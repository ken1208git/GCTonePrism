using System;
using System.Data.SQLite;
using System.IO;
using TonePrism.Manager;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#239 / F-1) 既存 DB の in-place スキーマ移行が子テーブルを CASCADE で消さないことの自動回帰テスト。
    /// 最高 blast-radius な v19 → v20 の `games` 親テーブル recreate を、実データ入りの v19 状態 DB で検証する。
    /// これまで手動 (sqlite3 + 実機 Manager) でしか確認できなかった F-1 を自動化し、net10 移行 (Phase 4) の
    /// data-core 再検証ゲートとしても効かせる。
    /// </summary>
    /// (#297 PR2) `[Collection]` が要るのは、v24 の採番が `PathManager` 経由で `responses/` を走査するように
    /// なり、本クラスも静的 base dir seam を使うようになったため。seam を使う test class を並列実行すると
    /// base dir をクロバーし合って flaky になる (PathManagerStaticCollection の説明参照)。
    [Collection("PathManagerStatic")]
    public class SchemaMigrationTests : IDisposable
    {
        private readonly string _root;
        private readonly string _dbPath;

        public SchemaMigrationTests()
        {
            // install root を一時 dir に見立てる。DB もその中に置き、`PathManager` の base dir をそこへ向ける
            // ことで、v24 の採番が走査する `responses/` が実 install ではなくこの一時 dir 配下になる
            // (実 install の記録を読んだり汚したりしない)。
            _root = Path.Combine(Path.GetTempPath(), "tp_mig_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
            _dbPath = Path.Combine(_root, "toneprism.db");
            PathManager.SetBaseDirectoryForTest(_root);
        }

        public void Dispose()
        {
            PathManager.ResetBaseDirectoryForTest();
            try { SQLiteConnection.ClearAllPools(); } catch { /* ignore */ }
            try { if (Directory.Exists(_root)) Directory.Delete(_root, true); } catch { /* ignore */ }
        }

        [Fact]
        public void V19ToV20_GamesRecreate_PreservesChildRows_NoCascade()
        {
            BuildV19DbWithChildren(_dbPath, playTime: 2);

            // in-place migration (v19 → v20、games 親テーブル recreate を foreign_keys=OFF で実行)
            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                // 全 migration 完走で現行ターゲット版に到達 (v19→v20 の games recreate + 以降の chain。
                // #253 で v21 追加)。schema bump で数値が変わっても壊れないよう target を動的取得して比較。
                Assert.Equal((long)new SchemaManager(new DatabaseConnection(_dbPath)).GetTargetDatabaseVersion(),
                    ScalarLong(c, "PRAGMA user_version"));
                // 子テーブルが CASCADE で巻き添え削除されていない
                Assert.Equal(1L, ScalarLong(c, "SELECT COUNT(*) FROM games"));
                Assert.Equal(2L, ScalarLong(c, "SELECT COUNT(*) FROM game_versions"));
                Assert.Equal(1L, ScalarLong(c, "SELECT COUNT(*) FROM developers"));
                // (#297) play_records は v23 で DROP されるため COUNT 検証は撤去。CASCADE 非発生の検証意図は
                // game_versions / developers の COUNT で担保される。
                // FK 整合: foreign_key_check が違反行を返さない
                using (var cmd = new SQLiteCommand("PRAGMA foreign_key_check", c))
                using (var r = cmd.ExecuteReader())
                {
                    Assert.False(r.Read(), "foreign_key_check に違反行が残っている");
                }
                // play_time CHECK が付与された
                var ddl = ScalarString(c, "SELECT sql FROM sqlite_master WHERE type='table' AND name='games'");
                Assert.Contains("play_time INTEGER CHECK", ddl, StringComparison.OrdinalIgnoreCase);
            }
        }

        [Fact]
        public void V19ToV20_OutOfRangePlayTime_SkipsAndStaysV19_WithoutCrashOrDataLoss()
        {
            BuildV19DbWithChildren(_dbPath, playTime: 5); // 範囲外 (1-3 でない)

            // 範囲外データ残存時は hard-fail せず skip + retry (user_version 据え置き、起動を止めない)
            var ex = Record.Exception(() => new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase());
            Assert.Null(ex); // クラッシュしない
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal(19L, ScalarLong(c, "PRAGMA user_version")); // 据え置き (次回是正後に適用)
                Assert.Equal(2L, ScalarLong(c, "SELECT COUNT(*) FROM game_versions")); // 子は無事
            }
        }

        /// <summary>
        /// (#297) v22 状態 DB に surveys / play_records / launcher_surveys を空で作り、InitializeDatabase
        /// (v22→v23 migration) 後にこれら 3 テーブルが DROP され user_version が現行ターゲットに到達することを検証する。
        /// スキーマ撤去の自動回帰。
        /// </summary>
        [Fact]
        public void V22ToV23_DropsEventTables()
        {
            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                // FK 親の games + 撤去対象 3 テーブルを最小構成で作る (v22 相当)。
                Exec(c, "CREATE TABLE games (game_id TEXT PRIMARY KEY, title TEXT)");
                Exec(c, "CREATE TABLE play_records (id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT, start_time TEXT, end_time TEXT, play_duration INTEGER, player_count INTEGER, FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE)");
                Exec(c, "CREATE TABLE surveys (id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT, rating INTEGER, comment TEXT, created_at TEXT, FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE)");
                Exec(c, "CREATE TABLE launcher_surveys (id INTEGER PRIMARY KEY AUTOINCREMENT, rating INTEGER, favorite_game_id TEXT, comment TEXT, created_at TEXT, FOREIGN KEY(favorite_game_id) REFERENCES games(game_id) ON DELETE SET NULL)");
                Exec(c, "PRAGMA user_version=22");
            }

            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal((long)new SchemaManager(new DatabaseConnection(_dbPath)).GetTargetDatabaseVersion(),
                    ScalarLong(c, "PRAGMA user_version"));
                Assert.Equal(0L, ScalarLong(c, "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('surveys','play_records','launcher_surveys')"));
                Assert.Equal("ok", ScalarString(c, "PRAGMA integrity_check"));
            }
        }

        /// <summary>
        /// (#297 review) versioning 導入前 (user_version=0) で物理的に surveys / play_records / launcher_surveys を
        /// 持つ旧 DB が、v0 fast-path で 3 テーブルを DROP し**最新版数へ到達**することを検証する。v0 path は migration
        /// chain を通らず CurrentDbVersion を直接 stamp するため、各 migration を明示適用しないと
        /// 「中身は古いのに最新を名乗る」穴が空く (本テストでその回帰を固定)。
        ///
        /// **版数を上げるたびに、その migration の効果をここへ足すこと** (レビュー Low)。v0 path は chain を
        /// 通らない特殊経路なので、`GetTargetDatabaseVersion()` との一致だけを見ていると、新しい migration の
        /// 適用漏れがあっても緑のまま通る。v24 (`games.game_no`) の分は下に追加済み。
        /// </summary>
        [Fact]
        public void V0FastPath_DropsEventTables_AndReachesCurrentVersion()
        {
            // v19 形状 (games + 子テーブル) を作ってから user_version=0 へ落とし、撤去対象 3 テーブルを足す。
            // これで v0 path の各 retrofit (arguments / developers FK / play_time CHECK) を通しつつ
            // MigrateV22ToV23 の v0 適用を検証する。
            BuildV19DbWithChildren(_dbPath, playTime: 2);
            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Exec(c, "CREATE TABLE play_records (id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT, start_time TEXT, end_time TEXT, play_duration INTEGER, player_count INTEGER, FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE)");
                Exec(c, "CREATE TABLE surveys (id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT, rating INTEGER, comment TEXT, created_at TEXT, FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE)");
                Exec(c, "CREATE TABLE launcher_surveys (id INTEGER PRIMARY KEY AUTOINCREMENT, rating INTEGER, favorite_game_id TEXT, comment TEXT, created_at TEXT, FOREIGN KEY(favorite_game_id) REFERENCES games(game_id) ON DELETE SET NULL)");
                Exec(c, "PRAGMA user_version=0"); // versioning 導入前
            }

            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal((long)new SchemaManager(new DatabaseConnection(_dbPath)).GetTargetDatabaseVersion(),
                    ScalarLong(c, "PRAGMA user_version"));
                Assert.Equal(0L, ScalarLong(c, "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('surveys','play_records','launcher_surveys')"));
                Assert.Equal("ok", ScalarString(c, "PRAGMA integrity_check"));
                // 既存データ (games) は保持される。
                Assert.Equal(1L, ScalarLong(c, "SELECT COUNT(*) FROM games"));

                // v24 (#297): `CREATE TABLE IF NOT EXISTS` は既存 games を温存するので列は付かず、
                // MigrateV23ToV24 を v0 path にも明示適用しないと「game_no 列が無いのに v24 を名乗る」。
                // 列の存在だけでなく **backfill まで** 見る (列だけ足りて中身が NULL だと、記録が
                // 1 件も出ないまま診断画面だけ ✓ になる)。
                Assert.Equal(1L, ScalarLong(c,
                    "SELECT COUNT(*) FROM pragma_table_info('games') WHERE name='game_no'"));
                Assert.Equal(0L, ScalarLong(c,
                    "SELECT COUNT(*) FROM games WHERE game_no IS NULL OR game_no <= 0"));
                // high-water mark も v0 path で保存される (次の採番が既存番号を踏まない)。
                Assert.Equal(ScalarLong(c, "SELECT MAX(game_no) FROM games"),
                    ScalarLong(c, "SELECT CAST(value AS INTEGER) FROM settings WHERE key='game_no_seq'"));
            }
        }

        /// <summary>
        /// versioning 前の v19 状態 DB を raw SQL で構築する: `games` は v20 から play_time CHECK を除いた形、
        /// 子テーブルは FK ON DELETE CASCADE。1 game + 2 versions + 1 developer を投入。
        /// </summary>
        private static void BuildV19DbWithChildren(string dbPath, int playTime)
        {
            using (var c = new SQLiteConnection($"Data Source={dbPath};Version=3;"))
            {
                c.Open();
                Exec(c, "PRAGMA foreign_keys=ON");
                Exec(c, @"CREATE TABLE games (
                    game_id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT, release_year INTEGER,
                    genre TEXT, min_players INTEGER, max_players INTEGER,
                    difficulty INTEGER CHECK(difficulty BETWEEN 1 AND 3), play_time INTEGER,
                    controller_support INTEGER DEFAULT 0, supported_connection INTEGER DEFAULT 0,
                    thumbnail_path TEXT, background_path TEXT, executable_path TEXT,
                    display_order INTEGER DEFAULT 0, is_visible INTEGER DEFAULT 1,
                    controls TEXT, key_mapping TEXT, arguments TEXT, version TEXT)");
                Exec(c, @"CREATE TABLE game_versions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT NOT NULL, version TEXT NOT NULL,
                    executable_path TEXT NOT NULL, arguments TEXT, description TEXT, title TEXT, genre TEXT,
                    min_players INTEGER, max_players INTEGER, difficulty INTEGER, play_time INTEGER,
                    controller_support INTEGER DEFAULT 0, supported_connection INTEGER DEFAULT 0,
                    thumbnail_path TEXT, background_path TEXT, update_note TEXT, registered_at TEXT NOT NULL,
                    FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE)");
                Exec(c, @"CREATE TABLE developers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT, game_id TEXT, last_name TEXT, first_name TEXT,
                    grade TEXT, version_id INTEGER,
                    FOREIGN KEY(game_id) REFERENCES games(game_id) ON DELETE CASCADE,
                    FOREIGN KEY(version_id) REFERENCES game_versions(id) ON DELETE CASCADE)");

                Exec(c, $"INSERT INTO games (game_id, title, difficulty, play_time, version) VALUES ('g1','Game 1',2,{playTime},'1.1.0')");
                Exec(c, "INSERT INTO game_versions (game_id, version, executable_path, registered_at) VALUES ('g1','1.0.0','v1.0.0/g.exe','2026-01-01 00:00:00')");
                Exec(c, "INSERT INTO game_versions (game_id, version, executable_path, registered_at) VALUES ('g1','1.1.0','v1.1.0/g.exe','2026-01-02 00:00:00')");
                Exec(c, "INSERT INTO developers (game_id, last_name, first_name, grade) VALUES ('g1','山田','太郎','3')");

                Exec(c, "PRAGMA user_version=19");
            }
        }

        /// <summary>
        /// (#297 PR2) v23 状態 DB に game_no 列を追加し、既存行へ game_id 昇順で 1 から backfill されること、
        /// UNIQUE INDEX が張られること、採番カウンタ (settings.game_no_seq) が最大値に揃うことを検証する。
        ///
        /// この番号はプレイ記録・アンケート JSON の唯一のゲーム参照キーなので、backfill が漏れる / 重複すると
        /// 記録が別ゲームに混線する。migration 直後の一意性と連続性をここで固定する。
        /// </summary>
        [Fact]
        public void V23ToV24_AddsGameNo_AndBackfillsExistingRows()
        {
            BuildV23DbWithGames(_dbPath, "gamma", "alpha", "beta");

            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal((long)new SchemaManager(new DatabaseConnection(_dbPath)).GetTargetDatabaseVersion(),
                    ScalarLong(c, "PRAGMA user_version"));

                // game_id 昇順で 1..3 が振られる (決定的順序)。
                Assert.Equal(1L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='alpha'"));
                Assert.Equal(2L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='beta'"));
                Assert.Equal(3L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='gamma'"));

                // 未採番が残っていない / 重複が無い。
                Assert.Equal(0L, ScalarLong(c, "SELECT COUNT(*) FROM games WHERE game_no IS NULL"));
                Assert.Equal(3L, ScalarLong(c, "SELECT COUNT(DISTINCT game_no) FROM games"));

                // UNIQUE INDEX が存在する (採番バグを INSERT 時点で例外に変える最後の砦)。
                Assert.Equal(1L, ScalarLong(c,
                    "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='idx_games_game_no'"));

                // high-water mark が最大採番値に揃う。
                Assert.Equal("3", ScalarString(c, "SELECT value FROM settings WHERE key='game_no_seq'"));
            }
        }

        /// <summary>
        /// (#297 PR2) migration の再実行 (= Manager の再起動) で既存の game_no が振り直されないことを検証する。
        /// 番号が振り直されると、既に書き出されたプレイ記録 JSON が全部別ゲームを指すことになる (静かなデータ破損)。
        /// </summary>
        [Fact]
        public void V23ToV24_RerunDoesNotRenumberExistingGames()
        {
            BuildV23DbWithGames(_dbPath, "alpha", "beta");

            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();
            new SchemaManager(new DatabaseConnection(_dbPath)).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal(1L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='alpha'"));
                Assert.Equal(2L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='beta'"));
                Assert.Equal("2", ScalarString(c, "SELECT value FROM settings WHERE key='game_no_seq'"));
            }
        }

        /// <summary>
        /// (#297 PR2) 最大番号のゲームを削除しても、次に追加されるゲームがその番号を再利用しないことを検証する。
        ///
        /// これが high-water mark 方式を採った理由そのもの。単純な MAX(game_no)+1 だと番号が再利用され、
        /// 新しいゲームが削除済みゲームの過去のプレイ記録・アンケートを引き継いでしまう
        /// (JSON 側は番号しか持たないので誰も気づけない)。
        /// </summary>
        [Fact]
        public void GameNo_IsNotReusedAfterDeletingHighestNumberedGame()
        {
            BuildV23DbWithGames(_dbPath, "alpha", "beta");
            var conn = new DatabaseConnection(_dbPath);
            new SchemaManager(conn).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            // 最大番号 (beta = 2) を削除してから新しいゲームを追加する。
            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Exec(c, "DELETE FROM games WHERE game_id='beta'");
            }
            SQLiteConnection.ClearAllPools();

            var repo = new Repositories.GameRepository(conn, new Repositories.DeveloperRepository(conn));
            repo.Add(new Models.GameInfo { GameId = "gamma", Title = "ガンマ" });
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                // 削除された beta の 2 番ではなく 3 番が振られる。
                Assert.Equal(3L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='gamma'"));
                Assert.Equal("3", ScalarString(c, "SELECT value FROM settings WHERE key='game_no_seq'"));
            }
        }

        /// <summary>
        /// (#297 PR2) ゲームの内容を更新しても game_no が変わらないことを検証する (不変性)。
        /// UPDATE 経路が game_no を一切書かない設計であることの回帰固定。
        /// </summary>
        [Fact]
        public void GameNo_SurvivesGameUpdate()
        {
            BuildV23DbWithGames(_dbPath, "alpha");
            var conn = new DatabaseConnection(_dbPath);
            new SchemaManager(conn).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            var repo = new Repositories.GameRepository(conn, new Repositories.DeveloperRepository(conn));
            var game = repo.GetById("alpha");
            Assert.Equal(1L, game.GameNo);

            game.Title = "書き換えたタイトル";
            game.GameNo = 999; // 呼び出し側が誤った値を持っていても DB は書き換わらないこと
            repo.Update(game);
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal(1L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='alpha'"));
                Assert.Equal("書き換えたタイトル", ScalarString(c, "SELECT title FROM games WHERE game_id='alpha'"));
            }
        }

        /// <summary>
        /// (#297 PR2) v23 相当 (game_no 列なし) の DB を、指定した game_id のゲーム入りで作る。
        /// 列構成は CreateTables の v23 時点に合わせる (game_no だけ持たない状態)。
        /// </summary>
        private static void BuildV23DbWithGames(string dbPath, params string[] gameIds)
        {
            using (var c = new SQLiteConnection($"Data Source={dbPath};Version=3;"))
            {
                c.Open();
                Exec(c, @"CREATE TABLE games (
                    game_id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT, release_year INTEGER,
                    genre TEXT, min_players INTEGER, max_players INTEGER,
                    difficulty INTEGER CHECK(difficulty BETWEEN 1 AND 3),
                    play_time INTEGER CHECK(play_time BETWEEN 1 AND 3),
                    controller_support INTEGER DEFAULT 0, supported_connection INTEGER DEFAULT 0,
                    thumbnail_path TEXT, background_path TEXT, executable_path TEXT,
                    display_order INTEGER DEFAULT 0, is_visible INTEGER DEFAULT 1,
                    controls TEXT, key_mapping TEXT, arguments TEXT, version TEXT)");
                foreach (var id in gameIds)
                {
                    using (var cmd = new SQLiteCommand("INSERT INTO games (game_id, title) VALUES (@id, @id)", c))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.ExecuteNonQuery();
                    }
                }
                Exec(c, "PRAGMA user_version=23");
            }
            SQLiteConnection.ClearAllPools();
        }

        /// <summary>
        /// (#297 PR2) 既に書き出された記録ファイルが参照している番号を、DB が忘れていても再利用しないことを検証する。
        ///
        /// これが本設計の中心。バックアップ復元や DB リセットで DB 側の採番情報 (settings / MAX(game_no)) が
        /// 巻き戻っても、`responses/` に残った記録のファイル名から「実際に使われている番号」を読めば、
        /// 新しいゲームがその番号を継承して過去の記録を横取りする事故を防げる。
        /// </summary>
        [Fact]
        public void GameNo_DoesNotReuseNumbersReferencedByExistingRecords()
        {
            BuildV23DbWithGames(_dbPath, "alpha");
            var conn = new DatabaseConnection(_dbPath);
            new SchemaManager(conn).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            // DB は alpha=1 しか知らない状態。ここで「no.7 の記録が既に存在する」状況を作る
            // (= 復元で消えたゲームが遊ばれていた、に相当)。
            WriteRecordFile(_root, "play_records", "2026-09-05", unixTs: 1788400000, gameNo: 7);
            WriteRecordFile(_root, "surveys", "2026-09-05", unixTs: 1788400001, gameNo: 4);

            var repo = new Repositories.GameRepository(conn, new Repositories.DeveloperRepository(conn));
            repo.Add(new Models.GameInfo { GameId = "beta", Title = "ベータ" });
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                // 記録が参照する最大値 7 の次 = 8。DB だけ見ていたら 2 になり no.7 の記録を横取りしていた。
                Assert.Equal(8L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='beta'"));
            }
        }

        /// <summary>
        /// (#297 PR2) 記録フォルダの走査が、形式に合わないファイルに惑わされないことを検証する。
        /// 書きかけの `.tmp`、旧形式 (番号を持たない) のファイル名、全体アンケートの `0` は、いずれも
        /// 採番の判断材料にしてはいけない (`.tmp` は未完成、旧形式は番号不明、`0` はゲームを指さない)。
        /// </summary>
        [Fact]
        public void GameNo_ScanIgnoresTmpAndLegacyAndUnlinkedFileNames()
        {
            BuildV23DbWithGames(_dbPath, "alpha");
            var conn = new DatabaseConnection(_dbPath);
            new SchemaManager(conn).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            string dir = Path.Combine(_root, "responses", "play_records", "2026-09-05");
            Directory.CreateDirectory(dir);
            // 書きかけ (.json で終わらないので列挙対象外)
            File.WriteAllText(Path.Combine(dir, "1788400000-99-aaaa.json.tmp"), "{}");
            // 旧形式 (2 番目が uuid なので数値として読めない)
            File.WriteAllText(Path.Combine(dir, "1788400001-bbbbcccc.json"), "{}");
            // 全体アンケート相当 (ゲームを指さない)
            File.WriteAllText(Path.Combine(dir, "1788400002-0-dddd.json"), "{}");

            var repo = new Repositories.GameRepository(conn, new Repositories.DeveloperRepository(conn));
            repo.Add(new Models.GameInfo { GameId = "beta", Title = "ベータ" });
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                // どれも判断材料にならないので、DB 側の値 (alpha=1) の次 = 2。
                // .tmp の 99 を拾っていたら 100 になる。
                Assert.Equal(2L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='beta'"));
            }
        }

        /// <summary>
        /// (#297 PR2) 記録フォルダが存在しない (開催前 / 新規 install) 場合でも、採番が壊れず
        /// DB 側の情報だけで正しく続きから振られることを検証する。
        /// </summary>
        [Fact]
        public void GameNo_WorksWhenRecordsFolderIsAbsent()
        {
            BuildV23DbWithGames(_dbPath, "alpha", "beta");
            var conn = new DatabaseConnection(_dbPath);
            new SchemaManager(conn).InitializeDatabase();
            SQLiteConnection.ClearAllPools();

            Assert.False(Directory.Exists(Path.Combine(_root, "responses")));

            var repo = new Repositories.GameRepository(conn, new Repositories.DeveloperRepository(conn));
            repo.Add(new Models.GameInfo { GameId = "gamma", Title = "ガンマ" });
            SQLiteConnection.ClearAllPools();

            using (var c = new SQLiteConnection($"Data Source={_dbPath};Version=3;"))
            {
                c.Open();
                Assert.Equal(3L, ScalarLong(c, "SELECT game_no FROM games WHERE game_id='gamma'"));
            }
        }

        /// <summary>(#297 PR2) 記録ファイルを 1 件でっち上げる (中身は走査に使わないので最小限)。</summary>
        private static void WriteRecordFile(string installRoot, string category, string dayFolder, long unixTs, int gameNo)
        {
            string dir = Path.Combine(installRoot, "responses", category, dayFolder);
            Directory.CreateDirectory(dir);
            string name = $"{unixTs}-{gameNo}-{Guid.NewGuid():N}.json";
            File.WriteAllText(Path.Combine(dir, name), "{}");
        }

        private static void Exec(SQLiteConnection c, string sql)
        {
            using (var cmd = new SQLiteCommand(sql, c)) cmd.ExecuteNonQuery();
        }
        private static long ScalarLong(SQLiteConnection c, string sql)
        {
            using (var cmd = new SQLiteCommand(sql, c)) return Convert.ToInt64(cmd.ExecuteScalar());
        }
        private static string ScalarString(SQLiteConnection c, string sql)
        {
            using (var cmd = new SQLiteCommand(sql, c)) { var o = cmd.ExecuteScalar(); return o?.ToString() ?? ""; }
        }
    }
}
