using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.Linq;
using TonePrism.Manager.Models;
using TonePrism.Manager.Repositories;
using TonePrism.Manager.Services;

namespace TonePrism.Manager
{
    /// <summary>
    /// データベース操作のファサード。
    /// 既存の呼び出し元を壊さないよう、各Repositoryへ委譲する。
    /// </summary>
    public class DatabaseManager
    {
        private readonly DatabaseConnection _conn;
        private readonly SchemaManager _schema;
        private readonly GameRepository _gameRepo;
        private readonly VersionRepository _versionRepo;
        private readonly DeveloperRepository _devRepo;
        private readonly StoreSectionRepository _sectionRepo;
        private readonly IntroSlideRepository _introSlideRepo;
        private readonly SettingsRepository _settingsRepo;
        private readonly BackupService _backupService;
        private readonly BackupCatalogService _backupCatalogService;
        private readonly AssetSnapshotService _assetSnapshotService;
        private readonly AssetRestoreService _assetRestoreService;
        private readonly SessionBackupCoordinator _sessionBackupCoordinator;
        private readonly RestoreService _restoreService;
        private readonly ManagerSessionRepository _sessionRepo;

        public DatabaseManager() : this(new DatabaseConnection()) { }

        /// <summary>
        /// (#209 テスト基盤) 任意の <see cref="DatabaseConnection"/> (一時 DB) を指して構築する。production は
        /// 既定 ctor (= PathManager.DatabasePath) 経由。DataLayerRoundTripTests と同じ #239 方針 (PathManager の
        /// プロジェクトルート検出に依存せずデータ層を単体で回す)。
        /// </summary>
        internal DatabaseManager(DatabaseConnection conn)
        {
            _conn = conn;
            _schema = new SchemaManager(_conn);
            _devRepo = new DeveloperRepository(_conn);
            _gameRepo = new GameRepository(_conn, _devRepo);
            _versionRepo = new VersionRepository(_conn, _devRepo);
            _sectionRepo = new StoreSectionRepository(_conn);
            _introSlideRepo = new IntroSlideRepository(_conn);
            _settingsRepo = new SettingsRepository(_conn);
            _backupService = new BackupService(_conn, _settingsRepo);
            // (backup_log 廃止 / DB v19) 履歴は backups/ フォルダ走査由来。BackupService からフォルダパスを取得する。
            _backupCatalogService = new BackupCatalogService(_backupService);
            // (#250 PR1) games/ + guide/ のアセットスナップショット。BackupService の保存先計算を流用するため後付け注入
            // (循環依存回避)。BackupService は DB バックアップ成功直後に best-effort で CreateSnapshot を呼ぶ。
            _assetSnapshotService = new AssetSnapshotService(_conn, _settingsRepo, _backupService);
            _backupService.AttachSnapshotService(_assetSnapshotService);
            // (#250 PR3b) 控えプールから games/ + guide/ を live へ書き戻す復元エンジン。snapshot と保存先計算 (pool root)
            // を共有するため同じ BackupService を注入。復元 UI (BackupSectionPanel) が DB 復元後に呼ぶ。
            _assetRestoreService = new AssetRestoreService(_conn, _backupService);
            // (#295) 操作単位 / replace-in-session の自動バックアップ段取り (この起動 = 1 自動世代)。
            _sessionBackupCoordinator = new SessionBackupCoordinator(_backupService);
            // (H5) advisory restore-lock 取得/解放のため SettingsRepository を注入。
            _restoreService = new RestoreService(_conn, _settingsRepo);
            _sessionRepo = new ManagerSessionRepository(_conn);
        }

        // --- バックアップ機能アクセサ ---
        public BackupService BackupService { get { return _backupService; } }
        /// <summary>(DB v19) バックアップ履歴を backups/ フォルダ走査から導出するカタログサービス。</summary>
        public BackupCatalogService BackupCatalogService { get { return _backupCatalogService; } }
        /// <summary>(#250) games/ + guide/ のアセット控え (共有プール CAS / SHA-256 バックアップ)。</summary>
        public AssetSnapshotService AssetSnapshotService { get { return _assetSnapshotService; } }
        /// <summary>(#250 PR3b) 控えプールから games/ + guide/ を live へ書き戻す復元エンジン (reconcile-in-place)。</summary>
        public AssetRestoreService AssetRestoreService { get { return _assetRestoreService; } }
        /// <summary>(#295) データ変更操作の成功直後に呼ぶ操作単位バックアップ coordinator (replace-in-session)。</summary>
        public SessionBackupCoordinator SessionBackupCoordinator { get { return _sessionBackupCoordinator; } }
        public RestoreService RestoreService { get { return _restoreService; } }
        public SettingsRepository SettingsRepository { get { return _settingsRepo; } }
        /// <summary>(#179) Manager session tracking 用 repository。</summary>
        public ManagerSessionRepository ManagerSessionRepository { get { return _sessionRepo; } }

        // --- 接続・スキーマ ---
        /// <summary>
        /// 現在の toneprism.db のフルパス (バックアップ保存先の既定算出等から参照)
        /// </summary>
        public string DatabasePath => _conn.DbPath;
        public bool DatabaseExists() => _conn.DatabaseExists();
        public bool TablesExist() => _schema.TablesExist();
        public int GetTargetDatabaseVersion() => _schema.GetTargetDatabaseVersion();
        public int GetActualDatabaseVersion() => _schema.GetActualDatabaseVersion();
        public void InitializeDatabase() => _schema.InitializeDatabase();
        public Services.FolderDeletionService.Result ResetDatabase() => _schema.ResetDatabase();

        // --- ゲーム ---
        public List<GameInfo> GetAllGames() => _gameRepo.GetAll();
        public GameInfo GetGameById(string gameId) => _gameRepo.GetById(gameId);
        public int GetMinDisplayOrder() => _gameRepo.GetMinDisplayOrder();
        public void AddGame(GameInfo game) => _gameRepo.Add(game);
        public void UpdateGame(GameInfo game) => _gameRepo.Update(game);
        public void DeleteGame(string gameId) => _gameRepo.Delete(gameId);
        public void UpdateGameId(string oldId, string newId) => _gameRepo.UpdateGameId(oldId, newId);

        // --- 開発者 ---
        public List<DeveloperInfo> GetDeveloperInfosByGameId(string gameId) => _devRepo.GetByGameId(gameId);
        public List<DeveloperInfo> GetDeveloperInfosByGameIdAndVersionId(string gameId, int versionId, SQLiteConnection connection) => _devRepo.GetByGameIdAndVersionId(gameId, versionId, connection);

        // --- バージョン ---
        public void AddGameVersion(GameVersion version) => _versionRepo.Add(version);
        public void UpdateGameVersion(GameVersion version) => _versionRepo.Update(version);
        // (#234 後続) 複数バージョンを単一トランザクションで一括更新 (番号入れ替え時の UNIQUE 一時衝突回避)。
        public void UpdateGameVersions(IEnumerable<GameVersion> versions) => _versionRepo.UpdateMany(versions);
        public List<GameVersion> GetGameVersions(string gameId) => _versionRepo.GetByGameId(gameId);
        public GameVersion GetLatestVersion(string gameId) => _versionRepo.GetLatest(gameId);

        /// <summary>
        /// (M5) 新版の追加 (game_versions INSERT) と activation (games UPDATE) を 1 transaction で atomic に
        /// 実行する。両者を別 transaction で順次実行する旧経路では、commit 完了直後に電源断 / SMB disconnect が
        /// 起きると game_versions のみ INSERT され games.version は旧版のまま残る partial-commit 窓があった
        /// (= Launcher で新版が起動できないが UI 上「アクティブ化失敗」MessageBox も出ない silent corruption)。
        /// 本 method は両 INSERT/UPDATE を共有 connection + transaction でラップして窓を物理閉鎖する。
        /// </summary>
        public void AddVersionAndActivate(GameVersion version, GameInfo game)
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
                            _versionRepo.AddVersionRowInTransaction(connection, transaction, version);
                            _gameRepo.UpdateGameRowInTransaction(connection, transaction, game);
                            transaction.Commit();
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        /// <summary>
        /// (#209) 個別バージョンを削除し、削除版が games の active 版 (= Launcher 表示中) だった場合は残りの最新版
        /// (id DESC 先頭) に **games 行を full mirror して** 付け替える。版行削除 + active 付け替えを 1 transaction で
        /// atomic に行う (AddVersionAndActivate と同じ partial-commit 窓閉鎖)。version 別 developers は version_id FK の
        /// ON DELETE CASCADE で自動削除される。
        ///
        /// **付け替えは version 文字列だけでなく executable_path / thumbnail 等のミラー列も更新する** (#209 review Codex P1)。
        /// version 文字列だけ書き換えると games.executable_path 等が削除済みフォルダを指したまま残り、Launcher が games.* を
        /// 直読みするため**そのゲームが起動不能**になる。`GameRepository.MirrorActiveVersionIntoGameInTransaction` を使う。
        ///
        /// **active 判定は DB の真値で行う**: 引数は versionId のみで、版数文字列は DB から引く (フォーム上で版番号を pending
        /// リネーム中でも dangling を起こさない)。**games.version が NULL のゲーム** (異常 DB) も「付け替えが必要」として
        /// 扱う (#209 review Codex P3、NULL のまま残して mirror が stale になるのを防ぐ)。
        ///
        /// **最後の 1 版は削除不可を transaction 内でも enforce** (#209 review Codex P2): UI ガードが並行 Manager で
        /// stale になっても 0 版ゲームを作らないよう、残存版数を数えて 1 以下なら例外を投げる。並行削除の race を
        /// 防ぐため BEGIN IMMEDIATE (Serializable) で RESERVED lock を先取りする (AddGameAtTop と同パターン)。
        /// </summary>
        /// <returns>削除後の games.version (= アクティブ版数文字列、DB の値)。</returns>
        /// <exception cref="InvalidOperationException">最後の 1 版を削除しようとした場合 (= 0 版になる)。</exception>
        public string DeleteGameVersionAndReassignActive(string gameId, int versionId)
        {
            return _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);
                    using (var transaction = connection.BeginTransaction(System.Data.IsolationLevel.Serializable))
                    {
                        try
                        {
                            // (P2) transaction 内で残存版数を確認。最後の 1 版なら拒否 (0 版ゲームを作らない)。
                            int count = _versionRepo.CountVersionsInTransaction(connection, transaction, gameId);
                            if (count <= 1)
                            {
                                throw new InvalidOperationException(
                                    "最後の 1 バージョンは削除できません (このゲームの残存バージョン数=" + count
                                    + ")。別の Manager が同時に削除した可能性があります。");
                            }

                            // 削除対象版の DB version 文字列 (active 判定の真値) を先に取得。
                            string deletedVersionString = _versionRepo.GetVersionStringByIdInTransaction(connection, transaction, versionId);

                            // 版行を削除 (developers は version_id FK cascade)。
                            _versionRepo.DeleteVersionRowInTransaction(connection, transaction, versionId);

                            // games.version が「削除版」または NULL (P3) なら、残り最新版を games 行へ full mirror して付け替え。
                            string currentActive = ReadGameVersionColumn(connection, transaction, gameId);
                            string newActive = currentActive;
                            bool needsReassign = currentActive == null
                                || (deletedVersionString != null
                                    && string.Equals(currentActive, deletedVersionString, StringComparison.OrdinalIgnoreCase));
                            if (needsReassign)
                            {
                                int? newActiveId = _versionRepo.GetLatestRemainingVersionIdInTransaction(connection, transaction, gameId);
                                if (newActiveId == null)
                                {
                                    // count>=2 を確認済なので通常到達しない (defensive)。
                                    throw new InvalidOperationException("残存バージョンが見つからず active を付け替えできません。");
                                }
                                _gameRepo.MirrorActiveVersionIntoGameInTransaction(connection, transaction, gameId, newActiveId.Value);
                                newActive = ReadGameVersionColumn(connection, transaction, gameId);
                            }

                            transaction.Commit();
                            return newActive;
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        // (#209) games.version 列を読む helper (DeleteGameVersionAndReassignActive の active 判定 / 戻り値用)。
        private static string ReadGameVersionColumn(SQLiteConnection connection, SQLiteTransaction transaction, string gameId)
        {
            using (var command = new SQLiteCommand("SELECT version FROM games WHERE game_id = @gameId", connection, transaction))
            {
                command.Parameters.AddWithValue("@gameId", gameId);
                object result = command.ExecuteScalar();
                return result == null || result == DBNull.Value ? null : (string)result;
            }
        }

        /// <summary>
        /// (累積監査 round 4 High-2) 複数バージョンの一括更新 (UpdateGameVersions) + ゲーム本体の更新
        /// (UpdateGame) を 1 transaction で atomic に実行する。EditGameForm のアクティブ版切替で両者を
        /// 別 transaction で順次実行する旧経路には、game_versions だけ commit 完了直後に電源断 / SMB
        /// disconnect が起きると games 行が旧版を指したまま残る partial-commit 窓があった (= Launcher で
        /// 古い executable_path / thumbnail を解決して silent corruption)。AddVersionAndActivate と同じ
        /// 設計で窓を物理閉鎖する。
        /// </summary>
        /// <summary>
        /// (累積監査 round 4 Medium-10) ゲーム追加時に DisplayOrder を「現在の MIN(display_order) - 1」へ自動採番
        /// する path を、SELECT MIN + INSERT を 1 transaction で atomic に実行する。旧経路は
        /// `GetMinDisplayOrder()` + `AddGame()` を別 transaction で順次実行しており、並行 Manager race で
        /// 両者が同じ MIN を取得して同 DisplayOrder で INSERT する → Launcher 並び順 invariant 「最新が一番上」が
        /// 壊れる経路があった。`IsolationLevel.Serializable` (= BEGIN IMMEDIATE) で RESERVED lock を最初に取り、
        /// 同時実行は SQLite 側で serialize される。
        /// </summary>
        public void AddGameAtTop(GameInfo game)
        {
            // transaction を開く前に走査しておく (SMB 全走査を書き込みロック中に持ち込まない。レビュー H-2)。
            long recordsMax = SchemaManager.ReadMaxGameNoFromRecords();
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);
                    using (var transaction = connection.BeginTransaction(System.Data.IsolationLevel.Serializable))
                    {
                        try
                        {
                            // SELECT MIN は RESERVED lock 内で実行されるため、他 Manager の concurrent
                            // AddGameAtTop は BEGIN IMMEDIATE で待たされ、commit 後に next snapshot を見る。
                            int minOrder;
                            using (var cmd = new SQLiteCommand("SELECT COALESCE(MIN(display_order), 0) FROM games", connection, transaction))
                            {
                                var r = cmd.ExecuteScalar();
                                minOrder = r is DBNull ? 0 : Convert.ToInt32(r);
                            }
                            game.DisplayOrder = minOrder - 1;

                            _gameRepo.AddGameRowInTransaction(connection, transaction, game, recordsMax);
                            transaction.Commit();
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        /// <summary>
        /// (累積監査 round 6 High-1) ゲーム追加時の games INSERT (display_order の MIN-1 採番込み) と
        /// 初期バージョンの game_versions INSERT を 1 transaction で atomic に実行する。
        ///
        /// 旧 AddGameForm は `AddGameAtTop` (games INSERT) と `AddGameVersion` (初期版 INSERT) を別 transaction で
        /// 順次実行しており、前者 commit 完了直後の電源断 / SMB disconnect で「games 行はあるが game_versions は
        /// ゼロ件」の起動不能孤児ゲーム (= Launcher 一覧には出るが版が無く起動できない) が残る partial-commit 窓が
        /// あった。失敗時は補償削除 (RollbackGameRow) で救おうとするが、それ自体が失敗すると zombie が残る。
        /// 本 method は両 INSERT を共有 connection + Serializable transaction でラップして窓を物理閉鎖する
        /// (AddVersionAndActivate / UpdateVersionsAndGame と同じ設計)。
        /// </summary>
        public void AddGameAtTopWithInitialVersion(GameInfo game, GameVersion initialVersion)
        {
            // transaction を開く前に走査しておく (SMB 全走査を書き込みロック中に持ち込まない。レビュー H-2)。
            long recordsMax = SchemaManager.ReadMaxGameNoFromRecords();
            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);
                    using (var transaction = connection.BeginTransaction(System.Data.IsolationLevel.Serializable))
                    {
                        try
                        {
                            int minOrder;
                            using (var cmd = new SQLiteCommand("SELECT COALESCE(MIN(display_order), 0) FROM games", connection, transaction))
                            {
                                var r = cmd.ExecuteScalar();
                                minOrder = r is DBNull ? 0 : Convert.ToInt32(r);
                            }
                            game.DisplayOrder = minOrder - 1;

                            _gameRepo.AddGameRowInTransaction(connection, transaction, game, recordsMax);
                            // 初期版は必ず追加対象 game の id を指す (caller の取り違え防止の二段保険)。
                            initialVersion.GameId = game.GameId;
                            _versionRepo.AddVersionRowInTransaction(connection, transaction, initialVersion);
                            transaction.Commit();
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        public void UpdateVersionsAndGame(IEnumerable<GameVersion> versions, GameInfo game)
        {
            var list = versions?.Where(v => v != null).ToList() ?? new List<GameVersion>();

            _conn.ExecuteWithRetry(() =>
            {
                using (var connection = new SQLiteConnection(_conn.ConnectionString))
                {
                    _conn.OpenConnectionWithJournalMode(connection);
                    using (var transaction = connection.BeginTransaction())
                    {
                        try
                        {
                            _versionRepo.UpdateManyInTransaction(connection, transaction, list);
                            _gameRepo.UpdateGameRowInTransaction(connection, transaction, game);
                            transaction.Commit();
                        }
                        catch
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }
            });
        }

        // --- ストアセクション ---
        public List<StoreSectionInfo> GetAllSections() => _sectionRepo.GetAll();
        public StoreSectionInfo GetSectionById(int sectionId) => _sectionRepo.GetById(sectionId);
        public int GetMaxSectionDisplayOrder() => _sectionRepo.GetMaxDisplayOrder();
        public void AddSection(StoreSectionInfo section) => _sectionRepo.Add(section);
        public void UpdateSection(StoreSectionInfo section) => _sectionRepo.Update(section);
        public void DeleteSection(int sectionId) => _sectionRepo.Delete(sectionId);
        public void SwapSectionOrder(int sectionIdA, int orderA, int sectionIdB, int orderB) => _sectionRepo.SwapDisplayOrder(sectionIdA, orderA, sectionIdB, orderB);

        // --- イントロガイド (#253) ---
        public List<IntroSlide> GetAllIntroSlides() => _introSlideRepo.GetAll();
        public int GetMaxIntroSlideDisplayOrder() => _introSlideRepo.GetMaxDisplayOrder();
        public void AddIntroSlide(IntroSlide slide) => _introSlideRepo.Add(slide);
        public void UpdateIntroSlide(IntroSlide slide) => _introSlideRepo.Update(slide);
        public void DeleteIntroSlide(int slideId) => _introSlideRepo.Delete(slideId);
        public void SwapIntroSlideOrder(int slideIdA, int orderA, int slideIdB, int orderB) => _introSlideRepo.SwapDisplayOrder(slideIdA, orderA, slideIdB, orderB);

        // --- エラーメッセージ ---
        public static string GetUserFriendlyErrorMessage(SQLiteException ex) => DatabaseConnection.GetUserFriendlyErrorMessage(ex);
    }
}
