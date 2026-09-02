using System;
using System.IO;
using TonePrism.Manager.Services;

namespace TonePrism.Manager
{
    /// <summary>
    /// アプリケーションのファイルパスを管理するクラス
    /// </summary>
    public static class PathManager
    {
        private static string _baseDirectory;
        
        /// <summary>
        /// アプリケーションのベースディレクトリ（プロジェクトルート）
        /// </summary>
        public static string BaseDirectory
        {
            get
            {
                if (_baseDirectory == null)
                {
                    _baseDirectory = FindBaseDirectory();
                }
                return _baseDirectory;
            }
        }

        /// <summary>(#239 テスト用 seam) BaseDirectory を一時 install dir に差し替える。本番経路は使わない
        /// (FindBaseDirectory が自動解決)。PathManager 静的に依存する RestoreReconciliationService 等を、実 install を
        /// 触らず一時フォルダで検証するため。テスト終了時に <see cref="ResetBaseDirectoryForTest"/> で戻す。</summary>
        internal static void SetBaseDirectoryForTest(string baseDir) { _baseDirectory = baseDir; }

        /// <summary>(#239 テスト用 seam) <see cref="SetBaseDirectoryForTest"/> の差し替えを解除し自動解決に戻す。</summary>
        internal static void ResetBaseDirectoryForTest() { _baseDirectory = null; }
        
        /// <summary>
        /// gamesフォルダのパス
        /// </summary>
        public static string GamesFolder
        {
            get { return Path.Combine(BaseDirectory, "games"); }
        }

        /// <summary>
        /// (#253) guide フォルダのパス (`&lt;install&gt;/guide/`)。イントロガイドのスライド画像を
        /// ファイル別管理する (games/ の隣)。DB (`intro_slides.image_path`) には `guide/&lt;file&gt;`
        /// の相対パスのみ持つ。Launcher も同 relative path を base 起点で resolve する。
        /// </summary>
        public static string GuideFolder
        {
            get { return Path.Combine(BaseDirectory, "guide"); }
        }
        
        /// <summary>
        /// データベースファイルのパス
        /// </summary>
        public static string DatabasePath
        {
            get { return Path.Combine(BaseDirectory, "toneprism.db"); }
        }

        // ===== Phase 4 (#108) update flow 用 path 拡張 =====
        // 既存の BaseDirectory = `<install>/` を起点に、各 component / shortcut bat / Updater /
        // staging 領域の path を 1 箇所で導出する。Manager UI のアップデートフロー
        // ([7]〜[10]) は本クラスから得た path だけを使い、ハードコードを散らさない。

        /// <summary>Launcher dir (`<install>/Launcher/`)</summary>
        public static string LauncherDir
        {
            get { return Path.Combine(BaseDirectory, "Launcher"); }
        }

        /// <summary>
        /// Launcher 実行 exe (`<install>/Launcher/TonePrism_Launcher.exe`)。(#283) Manager UI の VersionInventory が
        /// Launcher 版数を FileVersionInfo から読む対象 (Updater 読み取りと同方式)。dev (= exe 不在) では
        /// VersionInventory が `project.godot` 直 parse に fallback する。
        /// </summary>
        public static string LauncherExePath
        {
            get { return Path.Combine(LauncherDir, "TonePrism_Launcher.exe"); }
        }

        /// <summary>Manager dir (`<install>/Manager/`)。Updater が rename-rollback する対象。</summary>
        public static string ManagerDir
        {
            get { return Path.Combine(BaseDirectory, "Manager"); }
        }

        /// <summary>Companions 集約 dir (`<install>/Companions/`)。SPEC §2.4。</summary>
        public static string CompanionsDir
        {
            get { return Path.Combine(BaseDirectory, "Companions"); }
        }

        /// <summary>Updater dir (`<install>/Companions/Updater/`)。SPEC §3.7.4。</summary>
        public static string UpdaterDir
        {
            get { return Path.Combine(CompanionsDir, "Updater"); }
        }

        /// <summary>Updater 実行 exe (`<install>/Companions/Updater/TonePrism_Updater.exe`)。</summary>
        public static string UpdaterExePath
        {
            get { return Path.Combine(UpdaterDir, "TonePrism_Updater.exe"); }
        }

        // ===== Unified logs root (v0.15.0、#201 前提の logs_root_path 設定) =====
        // SPEC §3.6: 全 component の log は `<LogsRootDirectory>/<component>/<file>.log` に統一配置。
        // LogsRootDirectory は Program.Main が SQLite から `logs_root_path` setting を読込んで
        // 起動時 1 回 set する (空 / 未設定なら default の `<BaseDirectory>/logs/`)。
        // 旧 v0.14.0 までの `log_destination_path` (Manager log 直配置 semantic) は廃止、起動時に
        // auto-migrate (Program.ReadInitialLogSettingsWithMigration) で値を `logs_root_path` に copy。

        private static string _logsRootDirectory;

        /// <summary>
        /// ログ全体の親 dir (`<BaseDirectory>/logs/` または user 設定 `logs_root_path`)。
        /// Program.Main が SQLite を読込んで起動時に SetLogsRootDirectory() で 1 回 set、以降は immutable。
        /// SettingsRepository には依存しない (Logger SoT 一元化)。
        ///
        /// **R2 review Medium #5 対応**: 旧 R1 実装は getter で「未 set なら default を field に書込む」
        /// defensive fallback を持っていたが、これは setter が後行で呼ばれた時に no-op 化させる silent
        /// ignore hazard だった。本実装は **getter は default を return するが field には書込まない**、
        /// setter は 2 回目以降 throw で discipline 強制 (= setter→getter 順序逆転を test / dev で検出)。
        /// </summary>
        public static string LogsRootDirectory
        {
            get
            {
                // Set 前 fallback: default (BaseDirectory/logs/) を return するが field には書込まない。
                // これにより後続の SetLogsRootDirectory(custom) が正しく custom 値を反映できる。
                if (_logsRootDirectory == null) return Path.Combine(BaseDirectory, "logs");
                return _logsRootDirectory;
            }
        }

        /// <summary>
        /// LogsRootDirectory を起動時に 1 回 set する。Program.Main が SQLite 読込結果で呼出。
        /// 空文字 / null 時は **field を set せず**、getter の lazy default (`<BaseDirectory>/logs/`) に委ねる。
        /// **2 回目以降 (= 既に custom 値 set 済) の呼出は InvalidOperationException** (= immutable invariant
        /// 厳守、Program.Main の順序逆転や重複呼出を発覚させる discipline)。
        ///
        /// **R5 review Medium-1 対応**: 旧実装は customRoot 空時に `Path.Combine(BaseDirectory, "logs")` を
        /// eager 評価していたが、broken install (= Manager.exe を `<install>/Manager/` 外から起動 → BaseDirectory
        /// の lazy 解決が `DirectoryNotFoundException` throw) で本 setter が **mutex try-catch 外で uncaught throw**
        /// → friendly MessageBox なしの silent crash regression があった。customRoot 空時は field を set せず
        /// getter の lazy default に委ねることで、broken install では後続の `VerifyPaths` (= mutex try-catch 内)
        /// が DirectoryNotFoundException を friendly「起動エラー」MessageBox で拾う pre-PR 経路を維持する。
        /// </summary>
        public static void SetLogsRootDirectory(string customRoot)
        {
            if (_logsRootDirectory != null)
            {
                throw new InvalidOperationException(
                    "PathManager.SetLogsRootDirectory は起動時に 1 回のみ呼出可能、既に set 済の状態で再呼出された。"
                    + " Program.Main の呼出順序を確認のこと (= getter 先行 / 重複 set 呼出は禁止)。");
            }
            // customRoot 非空時のみ即 set。空時は field を null のまま残し、getter の lazy default 計算に委ねる
            // (= BaseDirectory の eager 解決を回避、broken install で setter から throw しない)。
            if (!string.IsNullOrWhiteSpace(customRoot))
            {
                _logsRootDirectory = customRoot;
            }
        }

        /// <summary>Manager のログ出力先 (`<LogsRootDirectory>/manager/`)。SPEC §3.6 unified logs root 規約。</summary>
        public static string ManagerLogDir
        {
            get { return Path.Combine(LogsRootDirectory, "manager"); }
        }

        /// <summary>Launcher のログ出力先 (`<LogsRootDirectory>/launcher/`)。Launcher Logger は `responses/launcher_logs_root.json` 経由で同 path を resolve。</summary>
        public static string LauncherLogDir
        {
            get { return Path.Combine(LogsRootDirectory, "launcher"); }
        }

        /// <summary>Updater のログ出力先 (`<LogsRootDirectory>/updater/`)。Manager spawn 時に `--log-dir` 引数で Updater に渡される。SPEC §3.7.4 + §3.6 unified logs root 規約。</summary>
        public static string UpdaterLogDir
        {
            get { return Path.Combine(LogsRootDirectory, "updater"); }
        }

        /// <summary>Monitor のログ出力先 (`<LogsRootDirectory>/monitor/`)。Monitor component 実装着手時に使用 (現状 readiness)。</summary>
        public static string MonitorLogDir
        {
            get { return Path.Combine(LogsRootDirectory, "monitor"); }
        }

        /// <summary>
        /// install 親 dir (`<install>/../`)。`<親>/Launcher.bat` / `<親>/Manager.bat` の置き場所。
        /// SPEC §3.7.1 「ルート ショートカット規約」、Phase 2 で <親>/ 直下配置に変更済み。
        /// </summary>
        public static string InstallParentDir
        {
            get { return Path.GetDirectoryName(BaseDirectory.TrimEnd('\\', '/')); }
        }

        /// <summary>
        /// 同梱 CHANGELOG.md (`<install>/CHANGELOG.md` 直下)。Phase 4 (#108) で zip 同梱、Install.bat
        /// の robocopy で `<install>/` 直下に展開される (`Launcher/` `Manager/` 等と同階層、project
        /// 全体の SoT semantic)。Manager は本 path を parse して「現在の installed Bundle version」を
        /// 抽出する (SPEC §3.7.7)。Phase 4 アップデートフロー [7]〜[10] では single-file copy で更新
        /// (Updater が touch しない領域なので Manager UI が `FileReplacer.ReplaceFile` で書き換える)。
        /// </summary>
        public static string BundleChangelogPath
        {
            get { return Path.Combine(BaseDirectory, "CHANGELOG.md"); }
        }

        /// <summary>
        /// (#179 PR3b) Launcher session heartbeat 用 drop folder (`&lt;install&gt;/responses/launcher_sessions/`)。
        /// Launcher autoload `SessionHeartbeat` が 1 PC 1 file (`&lt;pc_name&gt;.json`) で heartbeat JSON を
        /// 10 秒周期 atomic write、Manager `LauncherSessionService` が on-demand polling で読込。
        /// SPEC §3.8.7 仕様化、§6.5 の「IPC 用 subfolder」(data drop ではなく Launcher → Manager 状態通知)
        /// として明文化 (data drop subfolder の play_records/ / surveys/ とは別カテゴリ)。
        /// ※ 旧 §6.5 の 3-state folder pattern (pending / imported/ / failed/) は #297 で SQLite 取り込み
        ///    経路ごと廃止されたため、本 heartbeat folder は「取り込み対象外の IPC 用」という位置づけのみ残る。
        ///
        /// Path SoT として両 component が同 relative path (`responses/launcher_sessions/`) を別実装
        /// (Manager C# / Launcher GDScript) で resolve、drift は SPEC §3.8.7 + §6.5 の literal 定義で
        /// fence。Launcher 側の対応 path は `Launcher/scripts/path_manager.gd:get_base_directory()` +
        /// `.path_join("responses/launcher_sessions")` で同 path を返す。
        /// </summary>
        public static string LauncherSessionsFolder
        {
            get { return Path.Combine(ResponsesFolder, "launcher_sessions"); }
        }

        /// <summary>
        /// (#297) Launcher が出力するプレイ記録・アンケートの保管場所 (`&lt;install&gt;/responses/`)。
        /// 直下は Manager ↔ Launcher の IPC 用ファイル、subfolder は data drop (SPEC §6.5 / §7.5.3)。
        /// </summary>
        public static string ResponsesFolder
        {
            get { return Path.Combine(BaseDirectory, "responses"); }
        }

        /// <summary>
        /// (#297) プレイ記録の data drop folder (`&lt;install&gt;/responses/play_records/`)。
        /// 配下は日付フォルダ (`YYYY-MM-DD/`)、その中に `&lt;unix_ts&gt;-&lt;game_no&gt;-&lt;uuid&gt;.json`。
        /// </summary>
        public static string PlayRecordsFolder
        {
            get { return Path.Combine(ResponsesFolder, "play_records"); }
        }

        /// <summary>
        /// (#297) アンケートの data drop folder (`&lt;install&gt;/responses/surveys/`)。命名規則は
        /// <see cref="PlayRecordsFolder"/> と同じ (全体アンケートは game_no 部分が `0`)。
        /// </summary>
        public static string SurveysFolder
        {
            get { return Path.Combine(ResponsesFolder, "surveys"); }
        }

        /// <summary>
        /// アップデート用 staging dir (`%TEMP%/TonePrism_update_<version>/`)。SPEC §3.7.3 [6]。
        /// 失敗時の zombie staging を MainForm_Load 起動時に cleanup する。
        /// </summary>
        public static string StagingRootForUpdate(string version)
        {
            return Path.Combine(Path.GetTempPath(), "TonePrism_update_" + (version ?? "unknown"));
        }

        /// <summary>
        /// 過去 run の zombie staging dir を列挙する (起動時 cleanup 用)。
        /// `Path.GetTempPath()` 直下の `TonePrism_update_*` + `GCTonePrism_update_*` 全てを返す。
        ///
        /// **#168 transition defensive cleanup**: 旧版 Manager (v0.11.0 以前) は `GCTonePrism_update_*`
        /// prefix で staging dir を作っていたため、その zombie が `%TEMP%` 直下に残る path あり。
        /// brand rename PR で新 Manager は `TonePrism_update_*` 一本だが、glob を 2 つ実行する形で
        /// transition 期間中の defensive cleanup を提供。staging dir は install path と独立なので
        /// 「旧 install 完全削除」の transition 戦略では cover 外、本 method 経由で別途回収する。
        /// **v0.13 以降**: 旧 prefix glob は削除候補 (= 全 user が transition 完了済を確認後)。
        /// </summary>
        public static System.Collections.Generic.IEnumerable<string> EnumerateZombieStagings()
        {
            string tempRoot = Path.GetTempPath();
            if (!Directory.Exists(tempRoot)) return new string[0];
            try
            {
                var newPrefix = Directory.EnumerateDirectories(tempRoot, "TonePrism_update_*");
                var oldPrefix = Directory.EnumerateDirectories(tempRoot, "GCTonePrism_update_*");
                return System.Linq.Enumerable.Concat(newPrefix, oldPrefix);
            }
            catch
            {
                return new string[0];
            }
        }
        
        /// <summary>
        /// 指定したゲームのフォルダパス
        /// </summary>
        /// <exception cref="ArgumentException">gameId が null / 空 / 空白のみのとき。
        /// (round 5 M5) `Path.Combine(GamesFolder, "")` は GamesFolder 自身を返す .NET 仕様で、
        /// それに `Directory.Delete(folder, true)` を当てると games/ 配下全削除の核兵器ボタンになる。
        /// 削除経路 (GameSectionPanel L477) では caller 側の IsNullOrWhiteSpace 防御が入っているが、
        /// 画像コピー / 編集の path 解決経路で別の caller が直呼びしているところは ValidateInput 前提で
        /// ガード無し。PathManager 自身が defense-in-depth として入口で fence する (caller 全部に防御を頼らない)。
        /// </exception>
        public static string GetGameFolder(string gameId)
        {
            if (string.IsNullOrWhiteSpace(gameId))
            {
                throw new ArgumentException("gameId が空文字 / 空白のみのため games フォルダ自身を指してしまいます (危険)。caller 側で IsNullOrWhiteSpace 防御してください。", nameof(gameId));
            }
            return Path.Combine(GamesFolder, gameId);
        }

        /// <summary>
        /// version 文字列からバージョンフォルダの leaf 名 (`v<X>.<Y>.<Z>[-suffix]`、必ず小文字 v) を作る。
        /// 先頭の `v`/`V` を一度剥がしてから小文字 v を被せ直すため、生値が "1.0.0" / "v1.0.0" / "V1.0.0"
        /// のいずれでも同一 leaf に正規化される。case-sensitive な `StartsWith("v")` 実装だと "V1.0.0" が
        /// "vV1.0.0" と二重 prefix になり、disk フォルダ名と DB 保存パス (GameSectionPanel が独立計算する
        /// prefix) が食い違う死角があったため helper に集約して両者を必ず一致させる (VersionFolderRenameService.ToVersionLeaf と同規則。null/空の扱いのみ差: 当 helper は空を ArgumentException で弾き、rename 経路の ToVersionLeaf は異常 snapshot 値で throw しないよう空を許容)。
        /// </summary>
        /// <exception cref="ArgumentException">version が null / 空 / 空白のみのとき。
        /// (round 5 M5) 旧実装は `version ?? ""` で空文字を許容し leaf 名が `"v"` 単独になっていた。
        /// `Path.Combine(gameFolder, "v")` は `<games>/<id>/v` のフォルダを指し、これに rmdir をかけると
        /// 当該ゲーム全バージョン消滅の余地があった。入口 fence で必ず弾く。</exception>
        public static string GetVersionFolderLeaf(string version)
        {
            if (string.IsNullOrWhiteSpace(version))
            {
                throw new ArgumentException("version が空文字 / 空白のみのため leaf 名が \"v\" 単独になってしまいます (危険)。caller 側で空チェックしてください。", nameof(version));
            }
            return "v" + version.TrimStart('v', 'V');
        }

        /// <summary>
        /// 指定したゲームのバージョンフォルダパス
        /// </summary>
        /// <exception cref="ArgumentException">gameId / version のいずれかが null / 空 / 空白のみのとき。</exception>
        public static string GetVersionFolder(string gameId, string version)
        {
            return Path.Combine(GetGameFolder(gameId), GetVersionFolderLeaf(version));
        }
        
        /// <summary>
        /// プロジェクトルートを自動検出
        /// 開発時・本番時どちらも同じロジックで検出
        /// </summary>
        private static string FindBaseDirectory()
        {
            string exePath = AppDomain.CurrentDomain.BaseDirectory;
            DirectoryInfo dir = new DirectoryInfo(exePath);
            string detectedBaseDirectory = null;
            
            // 最大10階層まで遡る（無限ループ防止）
            int maxLevels = 10;
            int currentLevel = 0;
            
            while (dir != null && currentLevel < maxLevels)
            {
                string currentPath = dir.FullName;
                
                // 優先順位1: toneprism.db（データベースファイル）
                if (File.Exists(Path.Combine(currentPath, "toneprism.db")))
                {
                    Logger.Info($"[PathManager] toneprism.db を検出: {currentPath}");
                    detectedBaseDirectory = currentPath;
                    break;
                }
                
                // 優先順位2: .git（Gitリポジトリのルート）
                if (Directory.Exists(Path.Combine(currentPath, ".git")))
                {
                    Logger.Info($"[PathManager] .git フォルダを検出: {currentPath}");
                    detectedBaseDirectory = currentPath;
                    break;
                }
                
                // 優先順位3: Managerフォルダが存在する場合（実行ファイルがその中にある場合）
                // 実行ファイルがManagerフォルダ内にある場合、親ディレクトリをプロジェクトルートとする
                //
                // NOTE: 比較は「等値 OR separator 付き StartsWith」の二段で行うこと。
                //   - exePath = AppDomain.CurrentDomain.BaseDirectory は現状 .NET の慣習で
                //     末尾 `\` 付きを返すので separator 付き StartsWith だけでも動くが、これは
                //     ランタイム実装依存の暗黙前提。将来 .NET 移行等で末尾 `\` が外れた場合、
                //     ちょうど Manager dir に居る正規ケースで誤って false になる regression
                //     リスクがある。Launcher 側の Godot get_base_dir() は末尾 "/" を返さない
                //     ため equality 比較が必須で、対称性のため Manager 側も同じパターンに揃える。
                //   - separator 付き StartsWith は "Manager" prefix が "ManagerStudio" 等の
                //     兄弟 dir 名にも誤マッチするのを防ぐため依然必要。
                //
                // 追加 guard (issue #151 で言及した sibling 同時存在検証):
                //   - 我々の install 構造は Manager と Launcher が必ず同一の親 dir 配下に
                //     セットで配置される (SPEC §3.7.1 / §7.5.1)。Launcher/ も同 currentPath
                //     直下に存在することを確認することで、`<install>/Manager/` 単独 dir
                //     (= 他アプリ等で偶然存在する Manager dir) との誤マッチを構造的に排除する。
                //     priority-1 (toneprism.db) / priority-2 (.git) が hit しない極限状況での
                //     false-match を低減 (round 7 L5)。
                string managerCandidate = Path.Combine(currentPath, "Manager");
                string managerCandidateWithSep = managerCandidate + Path.DirectorySeparatorChar;
                string siblingLauncher = Path.Combine(currentPath, "Launcher");
                if (Directory.Exists(managerCandidate) &&
                    Directory.Exists(siblingLauncher) &&
                    (exePath.Equals(managerCandidate, StringComparison.OrdinalIgnoreCase) ||
                     exePath.StartsWith(managerCandidateWithSep, StringComparison.OrdinalIgnoreCase)))
                {
                    Logger.Info($"[PathManager] Manager + Launcher 兄弟フォルダを検出: {currentPath}");
                    detectedBaseDirectory = currentPath;
                    break;
                }
                
                dir = dir.Parent;
                currentLevel++;
            }
            
            // プロジェクトルートが見つからない場合
            if (detectedBaseDirectory == null)
            {
                string errorMessage = $"エラー: プロジェクトルートが見つかりません。\n\n" +
                                     $"実行ファイルのパス: {exePath}\n\n" +
                                     $"このアプリケーションは、Managerフォルダ内から実行してください。";
                Logger.Error($"[PathManager] {errorMessage}");
                throw new DirectoryNotFoundException(errorMessage);
            }

            // Managerフォルダが存在し、実行ファイルがその中にあるか確認
            string managerFolderPath = Path.Combine(detectedBaseDirectory, "Manager");
            if (!Directory.Exists(managerFolderPath))
            {
                string errorMessage = $"エラー: Managerフォルダが見つかりません。\n\n" +
                                     $"プロジェクトルート: {detectedBaseDirectory}\n" +
                                     $"実行ファイルのパス: {exePath}\n\n" +
                                     $"このアプリケーションは、Managerフォルダ内から実行してください。";
                Logger.Error($"[PathManager] {errorMessage}");
                throw new DirectoryNotFoundException(errorMessage);
            }

            // 「等値 OR separator 付き StartsWith」の二段比較。Launcher 側との対称化、および
            // 将来 .NET ランタイムの BaseDirectory が末尾 `\` を外した場合の future-proofing
            // (詳細は loop 内の同パターン NOTE を参照)。
            string managerFolderPathWithSep = managerFolderPath + Path.DirectorySeparatorChar;
            if (!exePath.Equals(managerFolderPath, StringComparison.OrdinalIgnoreCase) &&
                !exePath.StartsWith(managerFolderPathWithSep, StringComparison.OrdinalIgnoreCase))
            {
                string errorMessage = $"エラー: 実行ファイルがManagerフォルダ内にありません。\n\n" +
                                     $"プロジェクトルート: {detectedBaseDirectory}\n" +
                                     $"Managerフォルダ: {managerFolderPath}\n" +
                                     $"実行ファイルのパス: {exePath}\n\n" +
                                     $"このアプリケーションは、Managerフォルダ内から実行してください。";
                Logger.Error($"[PathManager] {errorMessage}");
                throw new DirectoryNotFoundException(errorMessage);
            }

            return detectedBaseDirectory;
        }
        
        /// <summary>
        /// パスの確認（デバッグ用）
        /// </summary>
        public static void VerifyPaths()
        {
            Logger.Info("=== PathManager - パス確認 ===");
            Logger.Info($"実行ファイル: {AppDomain.CurrentDomain.BaseDirectory}");
            Logger.Info($"プロジェクトルート: {BaseDirectory}");
            Logger.Info($"Gamesフォルダ: {GamesFolder}");
            Logger.Info($"データベース: {DatabasePath}");
            Logger.Info($"");
            Logger.Info($"Gamesフォルダ存在: {Directory.Exists(GamesFolder)}");
            Logger.Info($"データベース存在: {File.Exists(DatabasePath)}");
            Logger.Info($"Launcher sessions フォルダ: {LauncherSessionsFolder}");
            Logger.Info($"Launcher sessions フォルダ存在: {Directory.Exists(LauncherSessionsFolder)}");
            Logger.Info("============================");
        }
        
        /// <summary>
        /// 必要なフォルダを作成
        /// </summary>
        public static void EnsureDirectoriesExist()
        {
            if (!Directory.Exists(GamesFolder))
            {
                Directory.CreateDirectory(GamesFolder);
            }
        }
    }
}

