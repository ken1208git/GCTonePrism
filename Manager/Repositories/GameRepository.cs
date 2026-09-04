using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.Linq;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;

namespace TonePrism.Manager.Repositories
{
    /// <summary>
    /// ゲーム情報のCRUD操作
    /// </summary>
    public class GameRepository
    {
        private readonly DatabaseConnection _conn;
        private readonly DeveloperRepository _devRepo;

        public GameRepository(DatabaseConnection conn, DeveloperRepository devRepo)
        {
            _conn = conn;
            _devRepo = devRepo;
        }

        public List<GameInfo> GetAll()
        {
            return _conn.ExecuteWithRetry(() =>
            {
                var games = new List<GameInfo>();

                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    string query = @"
                        SELECT
                            game_id, title, description, release_year, genre,
                            min_players, max_players, difficulty, play_time, controller_support, supported_connection,
                            thumbnail_path, background_path, executable_path,
                            display_order, is_visible, controls, key_mapping, arguments, game_no,
                            COALESCE(version, (SELECT version FROM game_versions WHERE game_versions.game_id = games.game_id ORDER BY id DESC LIMIT 1)) AS display_version
                        FROM games
                        ORDER BY display_order ASC, title ASC";

                    using (var command = new SQLiteCommand(query, connection))
                    {
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var game = ReadGameInfo(reader, "display_version");
                                game.Developers = _devRepo.GetByGameId(game.GameId);
                                games.Add(game);
                            }
                        }
                    }
                }

                return games;
            });
        }

        public GameInfo GetById(string gameId)
        {
            return _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    string query = @"
                        SELECT
                            game_id, title, description, release_year, genre,
                            min_players, max_players, difficulty, play_time, controller_support, supported_connection,
                            thumbnail_path, background_path, executable_path,
                            display_order, is_visible, controls, key_mapping, arguments, version, game_no
                        FROM games
                        WHERE game_id = @gameId";

                    using (var command = new SQLiteCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@gameId", gameId);
                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                var game = ReadGameInfo(reader, "version");
                                game.Developers = _devRepo.GetByGameId(game.GameId);
                                return game;
                            }
                        }
                    }
                }

                return null;
            });
        }

        public int GetMinDisplayOrder()
        {
            return _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);
                    using (var command = new SQLiteCommand("SELECT MIN(display_order) FROM games", connection))
                    {
                        var result = command.ExecuteScalar();
                        return result is DBNull ? 0 : Convert.ToInt32(result);
                    }
                }
            });
        }

        public void Add(GameInfo game)
        {
            // transaction を開く前に走査しておく (SMB 全走査を書き込みロック中に持ち込まない)。
            long recordsMax = SchemaManager.ReadMaxGameNoFromRecords();
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    using (var transaction = connection.BeginTransaction())
                    {
                        try
                        {
                            AddGameRowInTransaction(connection, transaction, game, recordsMax);
                            transaction.Commit();
                        }
                        catch (Exception)
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        /// <summary>
        /// (累積監査 round 4 Medium-10) Add の core logic を既存 transaction の中で実行する内部 helper。
        /// `DatabaseManager.AddGameAtTop` で「MIN(display_order) を SERIALIZABLE 内で読んで -1 した値を採用」+
        /// games INSERT を 1 transaction にまとめる目的で抽出。並行 Manager race で DisplayOrder が衝突する経路を
        /// 構造的に閉鎖する。
        ///
        /// (#297 PR2) <b>副作用</b>: 採番した <see cref="GameInfo.GameNo"/> を引数の <paramref name="game"/> へ
        /// 書き戻す (呼び出し側が採番結果をログ等に使えるようにするため)。<c>ExecuteWithRetry</c> のリトライで
        /// transaction が rollback された場合、破棄された番号が一時的に残るが、次の試行で必ず上書きされるため
        /// 呼び出し側から観測できる値は常に commit された番号になる。
        /// </summary>
        internal void AddGameRowInTransaction(SQLiteConnection connection, SQLiteTransaction transaction, GameInfo game, long recordsMax)
        {
            string insertGame = @"
                INSERT INTO games (
                    game_id, title, description, release_year, genre,
                    min_players, max_players, difficulty, play_time, controller_support, supported_connection,
                    thumbnail_path, background_path, executable_path,
                    display_order, is_visible, controls, key_mapping, arguments, version, game_no
                ) VALUES (
                    @gameId, @title, @description, @releaseYear, @genre,
                    @minPlayers, @maxPlayers, @difficulty, @playTime, @controllerSupport, @supportedConnection,
                    @thumbnailPath, @backgroundPath, @executablePath,
                    @displayOrder, @isVisible, @controls, @keyMapping, @arguments, @version, @gameNo
                )";

            // (#297 PR2) game_no はここでだけ払い出す。UPDATE 経路は game_no を一切書かないため、一度振った番号は
            // ゲーム ID を改名しても版を差し替えても変わらない = プレイ記録・アンケート JSON の参照先が壊れない。
            // 採番は呼び出し側の transaction 内で行い、games の INSERT と同時に commit / rollback される。
            // ただし `responses/` の走査だけは transaction の外 (= recordsMax) で済ませてある — SMB 上の
            // 全走査を書き込みロック中に行うと他のキオスクを巻き添えで待たせるため (レビュー H-2)。
            game.GameNo = SchemaManager.AllocateNextGameNo(connection, transaction, recordsMax);

            using (var command = new SQLiteCommand(insertGame, connection, transaction))
            {
                SetGameParameters(command, game);
                command.Parameters.AddWithValue("@gameNo", game.GameNo.Value);
                command.ExecuteNonQuery();
            }

            InsertDevelopers(connection, transaction, game.GameId, game.Developers);
        }

        public void Update(GameInfo game)
        {
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    using (var transaction = connection.BeginTransaction())
                    {
                        try
                        {
                            UpdateGameRowInTransaction(connection, transaction, game);
                            transaction.Commit();
                        }
                        catch (Exception)
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        /// <summary>
        /// (M5) Update (= games UPDATE + games 配下 developers の delete+reinsert) を既存 transaction の
        /// 中で実行する内部 helper。`DatabaseManager.AddVersionAndActivate` で同一 transaction 内に
        /// AddGameVersion + UpdateGame を atomically まとめるために抽出。
        /// </summary>
        internal void UpdateGameRowInTransaction(SQLiteConnection connection, SQLiteTransaction transaction, GameInfo game)
        {
            string updateGame = @"
                UPDATE games SET
                    title = @title,
                    description = @description,
                    release_year = @releaseYear,
                    genre = @genre,
                    min_players = @minPlayers,
                    max_players = @maxPlayers,
                    difficulty = @difficulty,
                    play_time = @playTime,
                    controller_support = @controllerSupport,
                    supported_connection = @supportedConnection,
                    thumbnail_path = @thumbnailPath,
                    background_path = @backgroundPath,
                    executable_path = @executablePath,
                    display_order = @displayOrder,
                    is_visible = @isVisible,
                    controls = @controls,
                    key_mapping = @keyMapping,
                    arguments = @arguments,
                    version = @version
                WHERE game_id = @gameId";

            using (var command = new SQLiteCommand(updateGame, connection, transaction))
            {
                SetGameParameters(command, game);
                command.ExecuteNonQuery();
            }

            if (game.Developers != null)
            {
                using (var command = new SQLiteCommand("DELETE FROM developers WHERE game_id = @gameId AND version_id IS NULL", connection, transaction))
                {
                    command.Parameters.AddWithValue("@gameId", game.GameId);
                    command.ExecuteNonQuery();
                }

                InsertDevelopers(connection, transaction, game.GameId, game.Developers);
            }
        }

        /// <summary>
        /// (#209) 指定 version 行の「active 版ミラー列」を games 行へコピーする (= active 版の付け替え)。
        /// 個別バージョン削除でアクティブ版を消したとき、残存版へ **version 文字列だけでなく executable_path /
        /// thumbnail / title 等のミラー列も** 付け替えるために使う。これを怠ると games.executable_path 等が
        /// 削除済みフォルダを指したまま残り、Launcher が games.* を直読みするため**そのゲームが起動不能**になる
        /// (#209 review Codex P1)。
        ///
        /// **列リストは <see cref="UpdateGameRowInTransaction"/> の version 由来列と同期させること** (両者が
        /// games の「active 版ミラー」の SoT)。games 固有列 (release_year / display_order / is_visible /
        /// controls / key_mapping) は touch しない。developers は Launcher が games.version ↔ game_versions.version
        /// の JOIN で active 版の製作者を解決するため (game_repository.gd)、ここでは触らない。
        /// title は NOT NULL のため、万一 version 側が NULL でも COALESCE で既存値を保持する。
        /// </summary>
        internal void MirrorActiveVersionIntoGameInTransaction(SQLiteConnection connection, SQLiteTransaction transaction, string gameId, int versionId)
        {
            string sql = @"
                UPDATE games SET
                    version = (SELECT version FROM game_versions WHERE id = @vid),
                    executable_path = (SELECT executable_path FROM game_versions WHERE id = @vid),
                    arguments = (SELECT arguments FROM game_versions WHERE id = @vid),
                    description = (SELECT description FROM game_versions WHERE id = @vid),
                    title = COALESCE((SELECT title FROM game_versions WHERE id = @vid), title),
                    genre = COALESCE((SELECT genre FROM game_versions WHERE id = @vid), genre),
                    min_players = (SELECT min_players FROM game_versions WHERE id = @vid),
                    max_players = (SELECT max_players FROM game_versions WHERE id = @vid),
                    difficulty = (SELECT difficulty FROM game_versions WHERE id = @vid),
                    play_time = (SELECT play_time FROM game_versions WHERE id = @vid),
                    controller_support = (SELECT controller_support FROM game_versions WHERE id = @vid),
                    supported_connection = (SELECT supported_connection FROM game_versions WHERE id = @vid),
                    thumbnail_path = (SELECT thumbnail_path FROM game_versions WHERE id = @vid),
                    background_path = (SELECT background_path FROM game_versions WHERE id = @vid)
                WHERE game_id = @gameId";
            using (var command = new SQLiteCommand(sql, connection, transaction))
            {
                command.Parameters.AddWithValue("@vid", versionId);
                command.Parameters.AddWithValue("@gameId", gameId);
                command.ExecuteNonQuery();
            }
        }

        public void Delete(string gameId)
        {
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    string deleteGame = "DELETE FROM games WHERE game_id = @gameId";

                    using (var command = new SQLiteCommand(deleteGame, connection))
                    {
                        command.Parameters.AddWithValue("@gameId", gameId);
                        command.ExecuteNonQuery();
                    }
                }
            });
        }

        public void UpdateGameId(string oldId, string newId)
        {
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);

                    // 重複チェック（トランザクション前）
                    using (var cmd = new SQLiteCommand("SELECT COUNT(*) FROM games WHERE game_id = @newId", connection))
                    {
                        cmd.Parameters.AddWithValue("@newId", newId);
                        long count = (long)cmd.ExecuteScalar();
                        if (count > 0)
                            // (#206 follow-up) AddGameForm と文言統一 (具体 ID + 案内)。
                            throw new InvalidOperationException($"ゲームID「{newId}」は既に使用されています。別のIDを入力してください。");
                    }

                    // PRAGMA foreign_keys はトランザクション外でのみ変更可能
                    using (var cmd = new SQLiteCommand("PRAGMA foreign_keys = OFF", connection))
                        cmd.ExecuteNonQuery();

                    // (L) PRAGMA foreign_keys = ON は connection-local の状態だが、
                    // System.Data.SQLite の connection pool に返却される際に PRAGMA 状態が
                    // 連れて行かれる可能性がある。transaction が throw した場合に ON 復元が
                    // skip されると、pool から同 connection を取り出した後続 path が FK 制約なしで
                    // 動く silent drift の risk。try-finally で必ず ON に戻す。
                    try
                    {
                        using (var transaction = connection.BeginTransaction())
                        {
                            try
                            {
                                // 子テーブルのgame_idを更新
                                // (累積監査 round 4 Low-28/29: game_genres は v18 で DROP した dead table のため除去)
                                // (#297 / DB v23: play_records / surveys / launcher_surveys は DROP したため除去。
                                //  これらは responses/ の JSON 直読みへ移行済で SQLite に存在しない＝UPDATE すると
                                //  「no such table」で rename が落ちるため必ず外す)
                                string[] childTables = { "game_versions", "developers", "store_section_games" };
                                foreach (var table in childTables)
                                {
                                    using (var cmd = new SQLiteCommand($"UPDATE {table} SET game_id = @newId WHERE game_id = @oldId", connection, transaction))
                                    {
                                        cmd.Parameters.AddWithValue("@newId", newId);
                                        cmd.Parameters.AddWithValue("@oldId", oldId);
                                        cmd.ExecuteNonQuery();
                                    }
                                }

                                // メインテーブルの主キーを更新
                                using (var cmd = new SQLiteCommand("UPDATE games SET game_id = @newId WHERE game_id = @oldId", connection, transaction))
                                {
                                    cmd.Parameters.AddWithValue("@newId", newId);
                                    cmd.Parameters.AddWithValue("@oldId", oldId);
                                    cmd.ExecuteNonQuery();
                                }

                                transaction.Commit();
                            }
                            catch (Exception)
                            {
                                transaction.Rollback();
                                throw;
                            }
                        }
                    }
                    finally
                    {
                        // 例外伝播 path でも必ず FK 制約を再有効化 (connection pool 汚染防止)
                        try
                        {
                            using (var cmd = new SQLiteCommand("PRAGMA foreign_keys = ON", connection))
                                cmd.ExecuteNonQuery();
                        }
                        catch (Exception pragmaEx)
                        {
                            Logger.Warn("[GameRepository] (L) PRAGMA foreign_keys = ON 復元失敗: " + pragmaEx.Message);
                        }
                    }
                }
            });
        }

        private GameInfo ReadGameInfo(SQLiteDataReader reader, string versionColumnName)
        {
            var game = new GameInfo
            {
                GameId = reader["game_id"].ToString(),
                Title = reader["title"].ToString(),
                Description = reader["description"] is DBNull ? null : reader["description"].ToString(),
                ReleaseYear = reader["release_year"] is DBNull ? (int?)null : Convert.ToInt32(reader["release_year"]),
                MinPlayers = reader["min_players"] is DBNull ? (int?)null : Convert.ToInt32(reader["min_players"]),
                MaxPlayers = reader["max_players"] is DBNull ? (int?)null : Convert.ToInt32(reader["max_players"]),
                Difficulty = reader["difficulty"] is DBNull ? (int?)null : Convert.ToInt32(reader["difficulty"]),
                PlayTime = reader["play_time"] is DBNull ? (int?)null : Convert.ToInt32(reader["play_time"]),
                ControllerSupport = reader["controller_support"] is DBNull ? false : Convert.ToInt32(reader["controller_support"]) == 1,
                SupportedConnection = reader["supported_connection"] is DBNull ? 0 : Convert.ToInt32(reader["supported_connection"]),
                ThumbnailPath = reader["thumbnail_path"] is DBNull ? null : reader["thumbnail_path"].ToString(),
                BackgroundPath = reader["background_path"] is DBNull ? null : reader["background_path"].ToString(),
                ExecutablePath = reader["executable_path"] is DBNull ? null : reader["executable_path"].ToString(),
                DisplayOrder = reader["display_order"] is DBNull ? (int?)null : Convert.ToInt32(reader["display_order"]),
                IsVisible = reader["is_visible"] is DBNull ? true : Convert.ToInt32(reader["is_visible"]) == 1,
                Controls = reader["controls"] is DBNull ? null : reader["controls"].ToString(),
                KeyMapping = reader["key_mapping"] is DBNull ? null : reader["key_mapping"].ToString(),
                Version = reader[versionColumnName] is DBNull ? null : reader[versionColumnName].ToString()
            };

            string genreStr = reader["genre"] is DBNull ? null : reader["genre"].ToString();
            if (!string.IsNullOrEmpty(genreStr))
            {
                game.Genre = genreStr.Split(',').Select(g => g.Trim()).ToList();
            }
            else
            {
                game.Genre = new List<string>();
            }

            // GetAll / GetById の SELECT は両方 arguments を含むため直接読む。
            game.Arguments = reader["arguments"] is DBNull ? null : reader["arguments"].ToString();

            // (#297 PR2) game_no も両 SELECT に含まれる。v24 migration 前の DB / 未採番行では NULL になりうるため
            // nullable のまま扱う (呼び出し側でログ用途などに使う。UPDATE 経路は game_no を書かない = 不変)。
            game.GameNo = reader["game_no"] is DBNull ? (long?)null : Convert.ToInt64(reader["game_no"]);

            return game;
        }

        private void SetGameParameters(SQLiteCommand command, GameInfo game)
        {
            command.Parameters.AddWithValue("@gameId", game.GameId);
            command.Parameters.AddWithValue("@title", game.Title);
            command.Parameters.AddWithValue("@description", game.Description ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@releaseYear", game.ReleaseYear ?? (object)DBNull.Value);

            string genreStr = (game.Genre != null && game.Genre.Count > 0) ? string.Join(",", game.Genre) : null;
            command.Parameters.AddWithValue("@genre", genreStr ?? (object)DBNull.Value);

            command.Parameters.AddWithValue("@minPlayers", game.MinPlayers ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@maxPlayers", game.MaxPlayers ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@difficulty", game.Difficulty ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@playTime", game.PlayTime ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@controllerSupport", game.ControllerSupport ? 1 : 0);
            command.Parameters.AddWithValue("@supportedConnection", game.SupportedConnection);
            command.Parameters.AddWithValue("@thumbnailPath", game.ThumbnailPath ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@backgroundPath", game.BackgroundPath ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@executablePath", game.ExecutablePath ?? (object)DBNull.Value);

            if (game.DisplayOrder.HasValue)
            {
                command.Parameters.AddWithValue("@displayOrder", game.DisplayOrder.Value);
            }
            else
            {
                command.Parameters.AddWithValue("@displayOrder", 0);
            }

            command.Parameters.AddWithValue("@isVisible", game.IsVisible ? 1 : 0);
            command.Parameters.AddWithValue("@controls", game.Controls ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@keyMapping", game.KeyMapping ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@arguments", game.Arguments ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("@version", game.Version ?? (object)DBNull.Value);
        }

        private void InsertDevelopers(SQLiteConnection connection, SQLiteTransaction transaction, string gameId, List<DeveloperInfo> developers)
        {
            if (developers == null || developers.Count == 0) return;

            string insertDeveloper = @"
                INSERT INTO developers (game_id, last_name, first_name, grade)
                VALUES (@gameId, @lastName, @firstName, @grade)";

            foreach (var developer in developers)
            {
                using (var command = new SQLiteCommand(insertDeveloper, connection, transaction))
                {
                    command.Parameters.AddWithValue("@gameId", gameId);
                    command.Parameters.AddWithValue("@lastName", developer.LastName ?? "");
                    command.Parameters.AddWithValue("@firstName", developer.FirstName ?? "");
                    command.Parameters.AddWithValue("@grade", developer.Grade ?? "");

                    command.ExecuteNonQuery();
                }
            }
        }
    }
}
