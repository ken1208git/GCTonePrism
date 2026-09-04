using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using TonePrism.Manager.Controls;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;

namespace TonePrism.Manager
{
    /// <summary>
    /// メインフォーム - タブナビゲーション
    /// </summary>
    public partial class MainForm : Form
    {
        private DatabaseManager dbManager;
        // (#245 PR5 step4) 可視 main のシェル参照。ステータス更新 (DB状態/ゲーム数/バックアップ) を流し込むため保持。
        private Shell.ShellWindow _shell;
        private ManagerSessionService _sessionService;
        // (#179 PR3b) Launcher LAN-wide session 検出機構。`manager_sessions` table と非対称の
        // JSON drop folder 方式 (= SPEC §3.8.7)、polling-only で DB write ゼロ。
        private LauncherSessionService _launcherSessionService;

        /// <summary>
        /// (ダッシュボード) LAN-wide ランチャー稼働検出。シェルの DashboardPage が背景スレッドから
        /// DetectActiveLauncherSessions を呼ぶ (read-only ファイルスキャンでスレッド安全・UI 非依存)。
        /// 未初期化時は null か空 list で fail-soft。編集前競合チェックと同一インスタンスを共有する。
        /// </summary>
        internal LauncherSessionService LauncherSessionService => _launcherSessionService;

        private GameSectionPanel _gameSectionPanel;
        private StoreSectionPanel _storeSectionPanel;
        private SettingsSectionPanel _settingsSectionPanel;
        private BackupSectionPanel _backupSectionPanel;
        private LogSectionPanel _logSectionPanel;
        private UpdateSectionPanel _updateSectionPanel;
        private IntroGuidePanel _introGuidePanel;
        private System.Windows.Forms.TabPage _introTab; // (#253) ハンドル生成後に追加するため field 保持
        // (#299) 非ブロッキングバックアップの進捗を既存ステータスバー (statusStrip1) に統合する item 群 (1 段・左詰め)。
        // 順番は [phase 固定"バックアップ中..."][中止][進捗バー][ファイル名(可変・最後)]。可変幅のファイル名を末尾に
        // 置くことで、中止ボタンが per-file で高速移動しない (実機フィードバック)。phase 固定文言で中止位置を完全固定。
        private System.Windows.Forms.ToolStripStatusLabel _tsBackupPhase;
        // 中止 / 今すぐバックアップ。ToolStripControlHost(実 Button) は StatusStrip のレイアウトを壊して他 item が
        // 表示されなくなる + 残像が出るため不採用。フラットな ToolStripButton + 専用レンダラー
        // (BorderedStatusButtonRenderer) で常時枠を描いて「ボタンらしく」見せる。
        private System.Windows.Forms.ToolStripButton _tsBackupCancel;
        private System.Windows.Forms.ToolStripProgressBar _tsBackupBar;
        private System.Windows.Forms.ToolStripStatusLabel _tsBackupPercent; // 固定幅 (桁数でファイル名が揺れない)
        private System.Windows.Forms.ToolStripStatusLabel _tsBackupFile;
        private System.Windows.Forms.ToolStripButton _tsBackupRecapture;

        public MainForm()
        {
            InitializeComponent();

            // (#245 PR5 startup移管 step1) 移管中、MainForm は「裏方オーケストレータ」で可視 main は
            // ShellWindow(WPF)。起動時のフラッシュを避けるため Opacity=0 で不可視のまま Load を走らせ
            // (Opacity は描画のみ・Load は通常どおり発火)、全 init 完了後に ShowShellAsMain でシェルを
            // 表示して MainForm を Hide する。シェル表示に失敗した場合 / DB 未初期化で UI を見せたい場合は
            // Opacity=1 に戻して旧 WinForms UI を表示する (graceful fallback)。
            this.Opacity = 0;

            dbManager = new DatabaseManager();

            _gameSectionPanel = new GameSectionPanel { Dock = DockStyle.Fill };
            _storeSectionPanel = new StoreSectionPanel { Dock = DockStyle.Fill };
            _settingsSectionPanel = new SettingsSectionPanel { Dock = DockStyle.Fill };
            _backupSectionPanel = new BackupSectionPanel { Dock = DockStyle.Fill };
            _logSectionPanel = new LogSectionPanel { Dock = DockStyle.Fill };
            _updateSectionPanel = new UpdateSectionPanel { Dock = DockStyle.Fill };
            _introGuidePanel = new IntroGuidePanel { Dock = DockStyle.Fill };

            // (#170 followup) GameSectionPanel から送られる msg は常に「ゲーム数: N 件」で UpdateStatusBar()
            // の default と同義のため引数なし版に統一。旧 signature `UpdateStatusBar(string)` は廃止。
            _gameSectionPanel.StatusChanged += (msg) => UpdateStatusBar();
            _settingsSectionPanel.DatabaseReset += OnDatabaseReset;
            _backupSectionPanel.DatabaseChanged += OnDatabaseRestored;

            tabGame.Controls.Add(_gameSectionPanel);
            tabStore.Controls.Add(_storeSectionPanel);
            tabBackup.Controls.Add(_backupSectionPanel);
            tabLog.Controls.Add(_logSectionPanel);
            tabUpdate.Controls.Add(_updateSectionPanel);
            tabSettings.Controls.Add(_settingsSectionPanel);

            // (#253) イントロガイドのタブ追加は **ハンドル生成後** (MainForm_Load → ContinueLoadAfterSessionCheck)
            // に行う。理由: `TabControl.TabPages.Insert` / `Controls.SetChildIndex` は ctor 時点 (ハンドル前) では
            // silent fail し、タブが表示されない / 位置調整が効かない WinForms の既知挙動があるため (実機確認で判明)。
            // ここではパネル本体 (_introGuidePanel、上で生成済) のみ保持し、タブは AddIntroGuideTab() で後付けする。

            // (#179) ManagerSessionService の shutdown (self row delete + heartbeat 停止) を form 終了時に発火
            this.FormClosed += MainForm_FormClosed;
            // (#170 followup round 2 review L-3) backup status auto-revert timer の cleanup は Dispose 前に
            // 走らせたいので FormClosing を hook (= FormClosed は Dispose 後で意味薄)。
            this.FormClosing += MainForm_FormClosing;
            // (#201) 設定タブから他タブへ切替える際、未保存変更があれば確認 dialog (保存/破棄/キャンセル)。
            // **Deselecting** を使う (= 離脱するタブが e.TabPage で確実に取れる)。`Selecting` だと発火時点で
            // SelectedTab が既に新タブに変わっていて「設定タブから離脱したか」判定が timing 依存になる (= R3 fix bug)。
            this.tabControl1.Deselecting += TabControl1_Deselecting;
        }

        // (#201) 設定タブ離脱時の未保存変更ガード。Deselecting の e.TabPage は「離脱するタブ」なので、
        // それが tabSettings の時のみ判定。未保存あり + user「キャンセル」で e.Cancel=true → 切替中断 (= 留まる)。
        private void TabControl1_Deselecting(object sender, TabControlCancelEventArgs e)
        {
            // 設定タブ「から」離脱する遷移のみ対象
            if (e.TabPage != tabSettings) return;
            if (_settingsSectionPanel == null) return;

            // (R3 review fix) **focus 強制 commit**: TextBox.Leave / NumericUpDown のテキスト入力確定は
            // focus が抜けた時に発火するが、tab 切替 event は **focus-leave より先**に走るため、この時点では
            // 編集中 control の dirty mark がまだ立っていない (= TextBox に入力途中 / NumericUpDown に手打ち後
            // Enter 押さず tab click した case)。`ActiveControl = null` で active control の focus を抜いて
            // Leave / ValueChanged を同期発火させ、HasUnsavedChanges() 判定前に dirty を確定する。
            // (R4 review Medium-1: FormClosing 経路にも同じ `ActiveControl = null` を対称配置済 = focus-leave
            //  の発火順が version / focus 状態依存である前提を両経路で消去)。
            this.ActiveControl = null;

            if (_settingsSectionPanel.HasUnsavedChanges())
            {
                if (!_settingsSectionPanel.PromptAndResolveUnsavedChanges())
                {
                    e.Cancel = true; // 留まる
                }
            }
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            // (#170 followup round 2 review L-3 + round 3 review L-1) backup status auto-revert timer の
            // cleanup を **FormClosing** (= Dispose 前、message pump 走行中) で実行。
            // 別 handler が `e.Cancel=true` を set した場合 (= 将来「保存して閉じますか?」confirm dialog 追加時)
            // は timer を生かしたまま return、form が継続生存して `UpdateBackupStatus` 呼出時に新 timer 作成可能。
            //
            // (round 4 review L-3) **handler subscription 順序の前提**: `e.Cancel=true` を判定する handler
            // (= 「保存して閉じますか?」等) は **本 handler より先に subscribe** された場合のみ「timer を
            // 生かしたまま return」が成立する。`+=` の subscription 順で event 発火するため、後付け時は
            // ctor (L57-60) の `FormClosing` hook 行より前に新 handler の `+=` を追加すること。
            //
            // (#201) 設定タブの未保存変更ガード。**他 handler が既に e.Cancel=true を立てている場合は
            // skip** (= 下記 `if (e.Cancel) return;` で先に return)。現状 FormClosing を hook するのは本
            // handler のみなので未保存ガードが最初に走るが、将来 cancel 判定 handler を**先に** subscribe
            // した場合は本ガードが skip される点に注意 (= 上記 round 4 review L-3 の subscription 順序前提と
            // 同じ制約)。その場合は未保存判定を本ブロックより前 (= cancel-capable handler 群の最先頭) に
            // 移すか、未保存判定を独立 handler 化して subscribe 順を制御すること。
            if (e.Cancel) return;
            if (_settingsSectionPanel != null)
            {
                // (R4 review Medium-1) focus 強制 commit を tab 切替経路と**対称**に配置。× ボタン close 時、
                // active control の Leave が FormClosing より先に発火する保証は WinForms version / focus 状態に
                // 依存するため、「設定 textbox/numeric を編集途中で × クリック」で dirty 未確定のまま warning が
                // skip される脆い前提を消す。`ActiveControl = null` で Leave/ValueChanged を同期発火 → dirty 確定。
                this.ActiveControl = null;

                if (_settingsSectionPanel.HasUnsavedChanges())
                {
                    if (!_settingsSectionPanel.PromptAndResolveUnsavedChanges())
                    {
                        e.Cancel = true;
                        return; // 終了中断、timer は生かす
                    }
                }
            }
            // (#299) 非ブロッキングバックアップ実行中に閉じる場合は「中止して閉じますか？」確認。閉じる = 進行中
            // バックアップを中止する、と伝わる文言に。**変更データ自体は保存済み**で、中止しても live は無事
            // (途中世代が消えるだけ、次回起動の最初の操作で取り直される)。既定ボタンは「いいえ」(誤爆で中断しない)。
            try
            {
                var coord = dbManager?.SessionBackupCoordinator;
                if (coord != null && coord.IsBackupRunning)
                {
                    // (#449 レビュー H-1) シェル表示後は MainForm が Hide 済みなので `this` は不可視。
                    var dr = MessageBox.Show(VisibleModalOwner(),
                        "バックアップを中止して閉じますか？\n\n変更データ自体は保存済みです（バックアップだけが中断されます。次回起動時の最初の操作で取り直されます）。",
                        "バックアップ中", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2);
                    if (dr != DialogResult.Yes)
                    {
                        e.Cancel = true;
                        return; // 終了中断、timer は生かす
                    }
                    coord.CancelCurrentBackup();
                }
            }
            catch (Exception ex)
            {
                Logger.Warn("[MainForm] FormClosing バックアップ中確認で例外 (継続して閉じる): " + ex.Message);
            }
            try
            {
                if (_backupStatusClearTimer != null)
                {
                    _backupStatusClearTimer.Stop();
                    _backupStatusClearTimer.Dispose();
                    _backupStatusClearTimer = null;
                }
            }
            catch (Exception ex)
            {
                Logger.Warn("[MainForm] FormClosing で _backupStatusClearTimer cleanup 失敗: " + ex.Message);
            }
        }

        private void MainForm_FormClosed(object sender, FormClosedEventArgs e)
        {
            try
            {
                if (_sessionService != null)
                {
                    _sessionService.Shutdown();
                    _sessionService = null;
                }
            }
            catch (Exception ex)
            {
                Logger.Warn("[MainForm] FormClosed で ManagerSessionService Shutdown 失敗 (stale cleanup に委ねる): " + ex.Message);
            }

            // (#179 PR3b) LauncherSessionService も同様に Shutdown 呼出 + null 化。polling-only service
            // なので Shutdown は no-op (= 自 PC に self file なし)、対称化のため API は呼ぶ。
            try
            {
                if (_launcherSessionService != null)
                {
                    _launcherSessionService.Shutdown();
                    _launcherSessionService = null;
                }
            }
            catch (Exception ex)
            {
                Logger.Warn("[MainForm] FormClosed で LauncherSessionService Shutdown 失敗: " + ex.Message);
            }

        }

        /// <summary>
        /// (#179 / #178 (c)) 編集操作 (DB write) 前に他 PC active session を check して、検出時に
        /// SessionConflictDialog (EditOperation context) を表示する。各 SectionPanel が save handler 直前で
        /// 本 method を呼び出して結果を判定する。
        /// </summary>
        /// <param name="operationDescription">操作内容 (例: "ゲーム編集"、"ストア section 編集")、dialog 文言に embed される。</param>
        /// <returns>
        /// `DialogResult.OK` = 操作続行 (= 検出なし or user が「このまま保存する」選択)、
        /// `DialogResult.Cancel` = 操作中止 (= user が「保存を中止する」選択)。
        /// </returns>
        public DialogResult CheckSessionConflictBeforeWrite(string operationDescription)
        {
            // (H5) advisory restore-lock check。他 PC が現在復元処理中なら即時 Cancel 返却。
            // 「他 PC で復元中の数十秒間に自 PC が write した内容が File.Replace で消える」race を
            // user 確認層で塞ぐ coordination layer。stale (= 5 分以上 lock 古い) と self lock は無視。
            if (dbManager != null)
            {
                try
                {
                    string lockOwner = dbManager.SettingsRepository.GetActiveRestoreLockOwnerOrNull(
                        Environment.MachineName,
                        DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
                        Services.SettingsKeys.RestoreLockStaleThresholdMs);
                    if (!string.IsNullOrEmpty(lockOwner))
                    {
                        Logger.Warn($"[MainForm] (H5) 他 PC '{lockOwner}' が restore lock 保有中、{operationDescription} を中止");
                        // (#449 レビュー H-1) 同上。Hide 済み MainForm を owner にすると、シェルが
                        // 無効化されず擬似モーダルになり、警告表示中にシェルを操作できてしまう。
                        MessageBox.Show(VisibleModalOwner(),
                            $"他 PC ({lockOwner}) が現在データベースの復元処理中です。\n\n" +
                            $"復元処理と書込操作が衝突するとデータ消失のおそれがあるため、{operationDescription} を中止します。\n" +
                            "復元完了 (通常 1 分以内) を待ってから再試行してください。",
                            "他 PC で復元処理中", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        return DialogResult.Cancel;
                    }
                }
                catch (Exception ex)
                {
                    // lock check の失敗で write 全 path を block しないよう fail-soft。
                    Logger.Warn("[MainForm] (H5) restore lock check 失敗 (fail-soft 続行): " + ex.Message);
                }
            }

            // (#179 round 7 M-1) `_sessionService == null` (= MainForm_Load 完了前) と
            // `_sessionService.IsInitialized == false` (= Initialize 失敗で heartbeat 機構なし) の両方を
            // fail-soft で OK 返却。後者を guard しないと毎 click ごとに `DetectOtherActiveSessions` →
            // `ExecuteWithRetry` (busy_timeout=10000ms × maxRetries=3 = 最大 ~30 秒 block) を空振りし、
            // 全 13 SectionPanel callsite で click 毎 UI freeze + Warn log noise を踏む path だった。
            // Initialize 失敗は SPEC §3.8.5「致命傷、検出機能は以降一切働かない」と整合するため早期 OK。
            if (_sessionService == null || !_sessionService.IsInitialized)
            {
                return DialogResult.OK;
            }
            var others = _sessionService.DetectOtherActiveSessions();

            // (#179 PR3b) Launcher 検出を同時に取得 (= SPEC §3.8.7 merge 表示)。
            // LauncherSessionService が未 init / Initialize 失敗時は空 list で fail-soft、Manager 単独
            // 検出 path に倒れる (= 13 callsite 側 code 変更ゼロ、内部 merge で API contract 据置)。
            IReadOnlyList<LauncherSessionInfo> launcherOthers;
            if (_launcherSessionService != null && _launcherSessionService.IsInitialized)
            {
                launcherOthers = _launcherSessionService.DetectActiveLauncherSessions();
            }
            else
            {
                launcherOthers = new List<LauncherSessionInfo>();
            }

            if (others.Count == 0 && launcherOthers.Count == 0) return DialogResult.OK;

            // (#278 ①) 警告要否は SessionConflictPolicy に委譲 (純ロジック=単体テスト可能)。
            // 別 Manager がいれば常に警告 (write-write の本当の危険)。Launcher は DB 読み取り専用なので、
            // Launcher 単独稼働なら DB ファイルを丸ごと差し替える操作 (Restore / DB 初期化) のみ警告し、
            // 通常の行編集は抑制する (SQLite が行 write と Launcher の read を安全に調停するため、文化祭
            // 当日に Launcher を立てたままゲーム/セクション/初回説明等を編集してよい)。
            if (!Services.SessionConflictPolicy.ShouldWarn(others.Count, launcherOthers.Count, operationDescription))
            {
                if (launcherOthers.Count > 0)
                    Logger.Info($"[MainForm] (#278) Launcher 稼働中だが通常編集のため競合警告を省略: {operationDescription} (Launcher {launcherOthers.Count} 件)");
                return DialogResult.OK;
            }

            // (#449 レビュー H-1) **`this` を渡さない。** 本経路はシェル表示後の書込操作から呼ばれ、
            // そのとき MainForm は `Hide()` 済み = 不可視。`ShellOwner` の docstring が明記するとおり
            // 「隠し MainForm を owner にすると可視シェルが無効化されず擬似モーダルになる」ため、
            // 「データが破損する恐れ」の警告中にシェルを操作できてしまう (再入)。
            // 起動時ゲートより発火頻度が高い (別 Manager 稼働中なら書込のたびに出る)。
            return SessionConflictDialog.Show(
                VisibleModalOwner(), SessionConflictDialogContext.EditOperation,
                others, launcherOthers, operationDescription);
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            // (#245 PR5 / レビュー round5 Finding 1) 起動 init の前半 (DB migration / session init / 早期モーダル) も
            // fallback で受ける。ContinueLoadWithFallback はセッションゲート後しか守らず、前半で例外が出ると
            // Opacity=0 + 専用スレッドスプラッシュ下で「不可視窓 + スプラッシュ固まり」のサイレントハングになる
            // 退行があった (round3 で後半だけ守った取りこぼし)。Load 全体を包んで degraded-but-visible へ復元する。
            try { LoadCore(); }
            catch (Exception loadEx)
            {
                Logger.Error("[MainForm] (#245 PR5 / レビュー Finding 1) 起動 init 前半で例外、旧 WinForms UI へフォールバック", loadEx);
                FallbackToVisibleMainForm("起動処理中にエラーが発生しました。\n\n" + loadEx.Message + "\n\n一部の機能が使えない場合があります。問題が続く場合はアプリを再起動してください。");
            }
        }

        private void LoadCore()
        {
            // (#168 brand rename ハード切替 guard) 旧版 (GCTonePrism) install を検出した場合、
            // user が誤って新 zip を旧 install dir に展開した想定。`prism.db` (旧 DB filename) が
            // 残置されているが `toneprism.db` (新 DB filename) は存在しない、というのが旧版痕跡の
            // 一意 marker。fresh install (= 何もない) と区別するため両方を check する。検出時は
            // 警告 + 即時 process kill で、誤った混在状態で先に進む path を物理的に塞ぐ。
            //
            // **設計意図 (= 一過性 / 再利用前提なし)**: 本 guard は #168 brand rename transition 専用、
            // prism.db → toneprism.db 跨ぎ install の fail-safe。trigger 条件 (`prism.db` 残置 +
            // `toneprism.db` 不在) は brand rename specific で、健全 install では永久に発火しない
            // (= v0.12.0 以降では dead code に近い)。将来別 transition (e.g. toneprism.db → 別 schema)
            // では別 marker / 別 guard を新設する設計、本 guard を流用しない。
            //
            // **Environment.Exit(1) 採用根拠**: `Application.Exit()` だと WinForms message loop が
            // queued message を消化してから停止する設計のため、guard return 後も Form Show / 子
            // control 初期化 event が走り得る race window 残存 (= MainForm 未 Visible なので実害は
            // 薄いが defensive)。`Environment.Exit(1)` で process 即時 kill、queued message 一切
            // 処理されない厳密 fence。
            //
            // **dev 環境 false-positive 注意**: PathManager.FindBaseDirectory は priority-1
            // (`toneprism.db` 探索) → priority-2 (`.git` 探索) → priority-3 (Manager+Launcher
            // sibling) の順で BaseDirectory を resolve。開発者が repo root に過去の test artifact
            // `prism.db` を残置していた場合、priority-1 hit せず priority-2 で repo root が選ばれ
            // → 本 guard が trigger する path あり。回避は手動で `prism.db` 削除。MessageBox 文言は
            // 説明的なので開発者が原因に気付きやすい想定 (= 受容範囲、別 issue 化なし)。
            string oldDb = Path.Combine(PathManager.BaseDirectory, "prism.db");
            string newDb = Path.Combine(PathManager.BaseDirectory, "toneprism.db");
            if (File.Exists(oldDb) && !File.Exists(newDb))
            {
                MessageBox.Show(
                    "旧版 (GCTonePrism) の install が検出されました。\n\n" +
                    "新版は完全 rename (GCTonePrism → TonePrism) を伴う破壊的変更を含むため、" +
                    "自動更新できません。\n\n" +
                    "最新の TonePrism_vX.Y.Z.zip を新しいフォルダに解凍し、Install.bat を実行してください。",
                    "旧版検出 — 手動再 install が必要です",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                Environment.Exit(1);
                return;
            }

            // (#178 (b)) アップデート完了直後の起動 (= sentinel あり) は、まず「✓ アップデート完了」
            // MessageBox を表示。sentinel なし path は何もしない。
            // (#178 (c) / #179) 旧「同時起動に関する注意」MessageBox は撤廃、代わりに ManagerSessionService
            // で他 PC で稼働中の Manager を自動検出 → 検出時のみ SessionConflictDialog (Startup context)
            // を表示する設計に移行。session 初期化 + check は **dbManager.InitializeDatabase() で
            // schema migration (v12 → v13) が完了した後** に行う (= round 1 C-1 fix)。旧実装は migration
            // 前に Initialize を呼んでいて、v12 → v13 初回 upgrade で `no such table: manager_sessions`
            // で session 機構が silent に永久 disabled になる bug があった。
            TryShowUpdateCompletedDialog();

            // (#201, v0.15.0) ログ保存先 setting auto-migrate 完了 (v0.14.0 → v0.15.0 移行) の一回限り通知。
            // Program.Main の ReadInitialLogSettingsWithMigration が migration 完了時に `<install>/.logs_root_migrated`
            // sentinel file を書出している。本関数で sentinel を読込 → 部員向け subdir 構造説明 MessageBox →
            // sentinel を削除する flow。次回起動以降は sentinel 不在で発火しない。
            TryShowLogsRootMigratedDialog();

            // (R3 review M-2) Updater log absorb は ContinueLoadAfterSessionCheck 経由に移設済 (= session
            // conflict check 通過後)。MainForm_Load の早期で absorb すると同一 PC で複数 Manager が同時起動
            // した極端 case で `.absorbed` の append race + 重複 absorb が発生し得る path があった (実害は
            // Manager log file 間の重複 entry のみで file 内競合は無いが、構造的に bound するため移設)。
            //
            // (R4 review M-2) **skip path (dbReady=false / session conflict Cancel) の整理**:
            //   - dbReady=false (= DB 初期化を user が拒否 / 不存在 path) → MainForm_Load early return →
            //     ContinueLoadAfterSessionCheck 呼ばれず → absorb 走らない
            //   - session conflict Cancel → BeginInvoke dialog で Cancel → ContinueLoadAfterSessionCheck
            //     呼ばれず → absorb 走らない
            //   両 path とも次回 Manager 起動で `.absorbed` の未含有 entry として picked up される
            //   idempotent 設計のため、当該 startup の Manager log には Updater event が遅延反映されるが、
            //   永久に失われることはない (= CleanupOldLogs の「全起動 path 必達」設計とは要件が異なる、
            //   absorb は idempotent + deferred OK の弱い保証で十分)。

            // (#246) DB init/migration はここから (大きめ DB / SMB / migration 走行時に無反応になりうる)。
            Shell.SplashScreenHost.SetStatus("データベースを準備しています…");

            bool dbReady = false;

            if (!dbManager.DatabaseExists())
            {
                var result = MessageBox.Show(
                    "データベースが見つかりません。\n新規作成しますか？",
                    "データベース初期化",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);

                if (result == DialogResult.Yes)
                {
                    InitializeDatabase();
                    dbReady = true;
                }
            }
            else if (!dbManager.TablesExist())
            {
                var result = MessageBox.Show(
                    "データベーステーブルが見つかりません。\n初期化しますか？",
                    "データベース初期化",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);

                if (result == DialogResult.Yes)
                {
                    InitializeDatabase();
                    dbReady = true;
                }
            }
            else
            {
                dbManager.InitializeDatabase();
                dbReady = true;
            }

            if (!dbReady)
            {
                // (round 1 L-3) DB 未初期化 path では session service も起動しない (= heartbeat 不在で
                // form を user 手動 × で閉じるまで no-op、FormClosed で _sessionService=null なので
                // Shutdown も skip される clean path)。
                // (#170 followup) DB 未初期化は左 zone 占有 (= ゲーム数取得不可、データベース状態を伝える)
                // (#245 PR5 startup移管 step1) この path はシェルを出さず MainForm を UI として見せるため、
                // ctor で 0 にした Opacity を戻して可視化する (シェルは ContinueLoadAfterSessionCheck 末尾でのみ表示)。
                this.Opacity = 1;
                Shell.SplashScreenHost.Close(); // (#246) シェルを出さず MainForm を見せる path → スプラッシュを閉じる
                lblStatus.Text = "データベース未初期化";
                return;
            }

            // (#179、round 1 C-1 fix) DB schema migration が確実に完了したため、ManagerSessionService を
            // ここで初期化 + 起動時 check を実行。Initialize 内の SQL (`DELETE FROM manager_sessions ...` /
            // `INSERT OR REPLACE INTO manager_sessions ...`) は v13 schema に依存。
            _sessionService = new ManagerSessionService(dbManager.ManagerSessionRepository);
            _sessionService.Initialize();

            // (#179 PR3b) Launcher session 検出機構も同時に初期化。JSON drop folder 方式で SPEC §6.5
            // 「Launcher は SQLite に直接 write しない」原則を遵守、Manager 側は polling-only で DB write
            // ゼロ。`PathManager.LauncherSessionsFolder` (= `<install>/responses/launcher_sessions/`) を
            // SoT として両 component が同 path を別実装 (C# / GDScript) で resolve する。詳細 SPEC §3.8.7。
            _launcherSessionService = new LauncherSessionService(PathManager.LauncherSessionsFolder);
            _launcherSessionService.Initialize();

            // 起動時 check: 他 PC で active session を検出 → SessionConflictDialog (Startup)。
            // Cancel で Manager 終了 (self row delete 経由で clean exit trail を残す)。
            //
            // (#186 round 3) **gate 維持 + taskbar entry 確保の両立** のため chain pattern を採用:
            //   - 検出時: `BeginInvoke` で dialog 表示を defer (= MainForm の Show 完了後に開く)
            //     **(#449) この段の「MainForm を owner にすれば taskbar entry あり」という前提は失効した。**
            //     #245 で MainForm が `Opacity=0` + シェル表示後 `Hide()` の裏方窓になり、
            //     タスクバーに出ないため所有ダイアログを前面に戻す導線が無くなった。現在は
            //     `MakeMainFormVisible()` で可視 owner を作ってから出す。defer 自体 (= MainForm_Load の
            //     後続処理より先に dialog を出す) の意義は変わらないので pattern は維持する。
            //   - **panel.Initialize / LoadGames / CleanupZombieStagings / StartBackgroundUpdateCheckIfDue は
            //     全部 `ContinueLoadAfterSessionCheck` に切出し**、
            //     conflict 検出時は MainForm_Load 自体は
            //     return して残り init は実行しない (= gate)。
            //   - OK 押下時のみ `ContinueLoadAfterSessionCheck` を chain で起動 → 旧実装の gate 意味論
            //     を完全に維持。Cancel 時は panel init / backup / update check すべて skip して Close。
            //
            // round 1 (`MessageBoxOptions.DefaultDesktopOnly`) は user feedback「常時最前面うざい」で撤回。
            // round 2 (`BeginInvoke` defer のみ) は MainForm_Load の後続処理が dialog より先に走る regression
            // が PR #189 reviewer High で指摘されたため、本 round 3 で chain pattern に拡張。
            //
            // (#179 PR3b) Manager 検出 + Launcher 検出を merge して dialog 表示判定。両方が空の場合のみ
            // ContinueLoadAfterSessionCheck を直接呼出 (= 競合なし path)、どちらか 1 件以上で dialog 表示。
            //
            // Initialize は sync のまま (= heartbeat thread 起動を最速で)、Detect も sync で他 PC 検出結果
            // を握ってから dialog 表示部分のみ defer。
            var otherSessionsAtStartup = _sessionService.DetectOtherActiveSessions();
            // (#179 PR3b round 3 L-4) `CheckSessionConflictBeforeWrite` 側と pattern を対称化、
            // `_launcherSessionService.IsInitialized` を明示 check (= defense-in-depth、Initialize 失敗
            // path で fail-soft empty を確実に返す)。`_launcherSessionService` は直前に Initialize 済で
            // null になる path は無いが、guard を 2 箇所で揃えて読み手の認知 load を下げる。
            IReadOnlyList<LauncherSessionInfo> launcherSessionsAtStartup;
            if (_launcherSessionService != null && _launcherSessionService.IsInitialized)
            {
                launcherSessionsAtStartup = _launcherSessionService.DetectActiveLauncherSessions();
            }
            else
            {
                launcherSessionsAtStartup = new List<LauncherSessionInfo>();
            }
            // (#278 ①) 起動時ダイアログは「別 Manager 検出時のみ」出す。Launcher は DB 読み取り専用で
            // Manager の起動・通常編集を妨げないため、Launcher 単独稼働では出さない（危険な Restore /
            // DB 初期化は操作時に CheckSessionConflictBeforeWrite で警告される）。dialog には検出した
            // Launcher も併せて渡し（別 Manager 検出時は全体像を見せる）、判定だけを Policy に委譲。
            if (Services.SessionConflictPolicy.ShouldWarnAtStartup(otherSessionsAtStartup.Count, launcherSessionsAtStartup.Count))
            {
                BeginInvoke(new Action(() =>
                {
                    try
                    {
                        // (PR #189 round 4 L-1 表現訂正) race の正確 timing は
                        // 「`MainForm_Load` 完了 → `MainForm.Show` 完了 → message pump が本 BeginInvoke
                        // action を pick up するまでの数 ms」に user が × で閉じた case。
                        // MainForm_Load 実行中は MainForm 未表示で × clickable な window がないため、
                        // 「Load 中 ×」ではない。_sessionService が null になってる可能性 (= FormClosed
                        // 経由 Shutdown が deferred action 起動前に走った race) も同時 guard、defense-
                        // in-depth で残置。
                        if (IsDisposed || Disposing || _sessionService == null) return;

                        // (#449) **不可視の MainForm を owner にしない。** ここは MainForm_Load から
                        // BeginInvoke した deferred action で、MainForm は Opacity=0 の裏方窓。
                        // SessionConflictDialog の API contract も「owner Form を **visible 状態で**
                        // 渡せば自然な owner-modal child 挙動になる」と明記しており、契約違反だった。
                        //
                        // **`null` に倒すだけでは不十分 (レビュー H-2)。** WinForms は owner が null の
                        // とき `GetActiveWindow()` を owner に代入する。本経路は MainForm の Show 完了後に
                        // 走る設計なので、その時点の active window は不可視の MainForm になりうる —
                        // つまり null を渡しても同じ窓に戻り、修正が no-op になる。
                        //
                        // ここは**残りの初期化を止めるゲート**で、ユーザーが答えるまで先に進めない。
                        // 見失うと詰むので、**可視 owner を作ってから**出す。OK なら後続の
                        // ShowShellAsMain が MainForm を Hide してシェルに移るので、可視化は一時的。
                        MakeMainFormVisible();
                        var dialogResult = SessionConflictDialog.Show(
                            VisibleModalOwner(), SessionConflictDialogContext.Startup,
                            otherSessionsAtStartup, launcherSessionsAtStartup);
                        if (dialogResult == DialogResult.Cancel)
                        {
                            Logger.Info("[MainForm] user が SessionConflictDialog (Startup) で Cancel 選択、Manager 終了");
                            // (PR #184 round 1 M-4) FormClosed 経由 Shutdown と二重呼出にならないよう、
                            // Cancel path では Shutdown 直接呼出後に _sessionService = null を set。
                            _sessionService.Shutdown();
                            _sessionService = null;
                            // (#179 PR3b) LauncherSessionService も同様に Shutdown + null 化。polling-only
                            // なので Shutdown は no-op だが対称化のため呼ぶ + FormClosed 経由二重呼出予防。
                            if (_launcherSessionService != null)
                            {
                                _launcherSessionService.Shutdown();
                                _launcherSessionService = null;
                            }
                            // (PR #189 round 4 L-2 復活) `Application.Exit` ではなく `Close` で
                            // FormClosing → FormClosed chain を確実に走らせる (= Logger.Shutdown +
                            // FormClosed 経由の cleanup 一式)。round 3 で旧 `BeginInvoke(...Close())`
                            // 二重 defer を素の `Close()` に短絡化した際に同 rationale が消えていたため
                            // 復活。`Application.Exit` の方が直感的だが FormClosing が走らない drift
                            // path があるため `Close()` を選ぶ。
                            Close();
                            return;
                        }
                        Logger.Info("[MainForm] user が SessionConflictDialog (Startup) で OK 選択、起動を続行");
                        // (#186 round 3) OK path: 残り init を chain で起動 (= gate を通過した時点で
                        // 初めて panel init / backup / update check 等が走る)。(レビュー #1) fallback ラッパ経由。
                        ContinueLoadWithFallback();
                    }
                    catch (Exception ex)
                    {
                        // deferred action 内例外は Application.ThreadException 経由で UI thread crash
                        // 経路を踏むため、Logger.Error で握り潰す (FormClosed handler の Shutdown catch と
                        // 同方針、PR #189 round 3 reviewer Low 指摘)。
                        // (#245 PR5 / レビュー #1/round4 #3) Opacity=0 + 専用スレッドのスプラッシュ導入後は、握り潰すと
                        // 「不可視窓 + スプラッシュ固まり」のサイレントハングになる (SessionConflictDialog.Show 失敗等)。
                        // pre-shell init 失敗と同じく degraded-but-visible へ復元し、通知も揃える (フィードバックの一貫性)。
                        Logger.Error("[MainForm] Startup dialog deferred action で例外", ex);
                        FallbackToVisibleMainForm("起動処理中にエラーが発生しました。\n\n" + ex.Message + "\n\n一部の機能が使えない場合があります。問題が続く場合はアプリを再起動してください。");
                    }
                }));
                // (#186 round 3) gate 維持のため、conflict 検出時は MainForm_Load 自体ここで return。
                // dialog の OK/Cancel 判定後に ContinueLoadAfterSessionCheck が chain で呼ばれる。
                return;
            }

            // (#278 ①) ここに来るのは「別 Manager 無し」= 競合なし or Launcher 単独稼働。どちらも起動を妨げない。
            if (launcherSessionsAtStartup.Count > 0)
                Logger.Info($"[MainForm] (#278) 起動時に Launcher 稼働中だが別 Manager は無いため競合ダイアログを省略 (Launcher {launcherSessionsAtStartup.Count} 件)");
            // 残り init を直接呼出 (= 旧実装と同じ sync 起動 path、user 視点で挙動不変)。(レビュー #1) fallback ラッパ経由。
            ContinueLoadWithFallback();
        }

        /// <summary>
        /// (#245 PR5 / レビュー round4 #3/#4) 起動失敗時に degraded-but-visible へ復元する共通フォールバック。
        /// スプラッシュを閉じ MainForm を可視化し、crashMessage 指定時はクラッシュダイアログを出す
        /// (pre-shell init / セッションダイアログ失敗 = 通知あり / シェル生成失敗 = null で静かに旧 UI へ degrade)。
        /// 各手順は個別 try で包み本ヘルパー自体は throw しない (= ShowShellAsMain の catch から再 throw されない)。
        /// </summary>
        private void FallbackToVisibleMainForm(string crashMessage)
        {
            MakeMainFormVisible();
            if (!string.IsNullOrEmpty(crashMessage))
            {
                try { MessageBox.Show(this, crashMessage, "起動エラー", MessageBoxButtons.OK, MessageBoxIcon.Error); }
                catch { /* fallback ダイアログ自体の失敗は無視 */ }
            }
        }

        /// <summary>
        /// (#245 PR5 / レビュー #1) <see cref="ContinueLoadAfterSessionCheck"/> を呼び、pre-shell init 区間の
        /// 例外を graceful fallback で受ける。`Opacity=0` + fail-open スプラッシュ導入後、ここで例外が握り潰されると
        /// 「不可視窓 + スプラッシュ固まり」のサイレントハングになるため、両呼出元 (競合 OK / 競合なし) から本ラッパを
        /// 通し、失敗時はスプラッシュを閉じ MainForm を可視化してクラッシュを見せる (旧 degraded-but-visible 挙動を復元)。
        /// シェル生成/Show 失敗は <see cref="ShowShellAsMain"/> 内 catch が自己処理するため本 catch には来ない。
        /// </summary>
        private void ContinueLoadWithFallback()
        {
            try
            {
                ContinueLoadAfterSessionCheck();
            }
            catch (Exception ex)
            {
                Logger.Error("[MainForm] (#245 PR5 / レビュー #1) 起動 init に失敗、旧 WinForms UI へフォールバック", ex);
                FallbackToVisibleMainForm("起動処理中にエラーが発生しました。\n\n" + ex.Message + "\n\n一部の機能が使えない場合があります。問題が続く場合はアプリを再起動してください。");
            }
        }

        /// <summary>
        /// (#186 round 3) `MainForm_Load` の session check 通過後に呼ばれる残り init 処理。
        /// 旧実装は `MainForm_Load` 内に inline されていたが、Startup SessionConflictDialog の
        /// `BeginInvoke` defer (= MainForm.Show 完了後に dialog を出す taskbar entry 確保策) と
        /// 「Cancel 時は panel init / backup / update check すべて skip する gate 意味論」を両立する
        /// ため、chain pattern (= dialog OK 時に本 method を呼出、Cancel 時は呼出しない) で gate を維持。
        ///
        /// 競合なし path も本 method を直接呼んで code path を 1 本化。
        /// </summary>
        private void ContinueLoadAfterSessionCheck()
        {
            // (#246) パネル初期化・pending 取り込み等 (SMB 越しで遅延しうる) に入る。
            Shell.SplashScreenHost.SetStatus("画面を準備しています…");

            // DB確認後にパネルを初期化（DB存在前のアクセスを防止）
            _gameSectionPanel.Initialize(dbManager);
            _storeSectionPanel.Initialize(dbManager);
            _settingsSectionPanel.Initialize(dbManager);

            // (#253) イントロガイドのタブをここ (ハンドル生成後) で追加。ctor では TabPages.Insert が silent fail
            // するため後付けにしている。ストアタブの次に挿入。多重呼出ガードとして未作成時のみ追加。
            if (_introTab == null)
            {
                _introTab = new System.Windows.Forms.TabPage("初回説明") { UseVisualStyleBackColor = true };
                _introTab.Controls.Add(_introGuidePanel);
                int introStoreIdx = tabControl1.TabPages.IndexOf(tabStore);
                tabControl1.TabPages.Insert(introStoreIdx >= 0 ? introStoreIdx + 1 : tabControl1.TabPages.Count, _introTab);
            }
            _introGuidePanel.Initialize(dbManager);

            // Updater log の post-hoc filtered absorb (= SPEC §3.6 Companions ログ管理規約)。
            // 直前のアップデートサイクル中に Updater が書き出した log のうち Warn/Error + 主要 milestone
            // を Manager log に embed する。Manager GUI の log viewer から 3 component に収束させる方針の
            // 一環 (= Updater 用 tab を増やさず、Updater 由来の重要 event を Manager log の一部として閲覧)。
            // 例外は内部で握り潰し済、Manager 起動を阻害しない。
            //
            // **呼出位置**: session conflict check 通過後 = ContinueLoadAfterSessionCheck 内 (= R3 review
            // M-2 対応で MainForm_Load 早期から移設)。同一 PC 複数 Manager 同時起動時の `.absorbed` 競合を
            // 構造的に bound する目的。Cancel path で skip されるが next start で idempotent に picked up。
            Services.UpdaterLogAbsorber.AbsorbPendingLogs();

            // (#170 followup round 2 review H-1) CleanupOldLogs は **Program.Main に移動済**。
            // 旧実装は本 MainForm 経路で呼出していたが、dbReady=false / SessionConflictDialog Cancel
            // 等の early-return path で到達不能になる silent regression があり、Program.Main で
            // SQLite 直接 read 経由で呼ぶ形に変更。本 MainForm 内で再呼出は不要。

            // 旧バージョンが root 直下に作っていた safety ファイルを backups/safety/ へ一度きり移動
            try
            {
                int movedSafety = Services.BackupService.MigrateLegacySafetyFilesToSafetyFolder(
                    System.IO.Path.GetDirectoryName(PathManager.DatabasePath));
                if (movedSafety > 0)
                {
                    Logger.Info($"[MainForm] 旧 safety ファイル {movedSafety} 件を backups/safety/ に移動しました");
                }
            }
            catch (Exception ex)
            {
                Logger.Error("[MainForm] 旧 safety ファイル移動失敗", ex);
            }

            // (backup_log 廃止 / DB v19) バックアップ履歴は backups/ フォルダ走査由来 (BackupCatalogService)
            // になったため、起動時の register / reconcile は不要 (ファイル = 真実でズレない)。
            _backupSectionPanel.Initialize(dbManager);
            _logSectionPanel.Initialize(PathManager.LogsRootDirectory);
            _updateSectionPanel.Initialize(dbManager);

            _gameSectionPanel.LoadGames();
            _introGuidePanel.LoadSlides(); // (#253)
            UpdateStatusBar();

            // (#295) 起動時の時間トリガ自動バックアップは廃止。バックアップはデータ変更操作の成功直後に
            // SessionBackupCoordinator が操作単位で取る (replace-in-session、1 起動 = 1 自動世代)。
            // 操作単位バックアップの完了/失敗を status bar 右 zone に表示するコールバックを配線。
            // DB-only 操作はバックグラウンド実行 = 別スレッドから呼ばれるため UI スレッドへ marshal する。
            dbManager.SessionBackupCoordinator.StatusReporter = (msg, ok) =>
            {
                try
                {
                    if (IsDisposed) return;
                    Action apply = () =>
                    {
                        // (round2 #3) 成功は transient (7 秒で消える)、失敗/警告は sticky (autoRevert:false) にして
                        // 保存先設定ミス等の恒常的失敗を運営が見落とさないようにする (旧 modal 通知の代替)。
                        UpdateBackupStatus(msg,
                            ok ? System.Drawing.Color.DarkGreen : System.Drawing.Color.DarkOrange, autoRevert: ok);
                        // (round2 #4) 操作のたびに新世代を書くので、バックアップタブの履歴 / 最終バックアップ表示も最新化。
                        _backupSectionPanel?.RefreshDisplay();
                    };
                    if (InvokeRequired) BeginInvoke(apply); else apply();
                }
                catch { /* status 表示は best-effort、失敗しても無害 */ }
            };

            // (#299) 非ブロッキングバックアップの進捗を **既存の下部ステータスバー (statusStrip1) に統合** する (別バーを
            // 足して 2 段にせず 1 段)。進捗バー + 現在ファイル + 中止 を lblStatus の右へ **左詰め** で並べ、未バックアップ時は
            // 警告 + 「今すぐバックアップ」(1 クリック復旧) に切替。右寄せの lblBackupStatus (✓/⚠) は従来どおり右端。worker は
            // バックグラウンドスレッドなので ProgressReporter / BackupRunningChanged は UI スレッドへ marshal する。
            _tsBackupPhase = new System.Windows.Forms.ToolStripStatusLabel
            {
                Name = "_tsBackupPhase", Visible = false, AutoSize = true
            };
            _tsBackupCancel = new System.Windows.Forms.ToolStripButton { Name = "_tsBackupCancel", Text = "中止", Visible = false, DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text };
            _tsBackupBar = new System.Windows.Forms.ToolStripProgressBar
            {
                Name = "_tsBackupBar", Visible = false, Style = System.Windows.Forms.ProgressBarStyle.Continuous, Minimum = 0, Maximum = 100
            };
            _tsBackupBar.Size = new System.Drawing.Size(160, 16);
            _tsBackupPercent = new System.Windows.Forms.ToolStripStatusLabel
            {
                Name = "_tsBackupPercent", Visible = false, AutoSize = false, Width = 40,
                TextAlign = System.Drawing.ContentAlignment.MiddleRight
            };
            _tsBackupFile = new System.Windows.Forms.ToolStripStatusLabel
            {
                Name = "_tsBackupFile", Visible = false, AutoSize = true, Overflow = System.Windows.Forms.ToolStripItemOverflow.AsNeeded
            };
            _tsBackupRecapture = new System.Windows.Forms.ToolStripButton { Name = "_tsBackupRecapture", Text = "今すぐバックアップ", Visible = false, DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text };
            // 順番: [phase][中止][進捗バー][ファイル名(末尾・可変)][今すぐバックアップ(未バックアップ時のみ)]。
            statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] { _tsBackupPhase, _tsBackupCancel, _tsBackupBar, _tsBackupPercent, _tsBackupFile, _tsBackupRecapture });
            statusStrip1.Renderer = new BorderedStatusButtonRenderer(); // ToolStripButton に常時枠を描いて「ボタンらしく」見せる
            _tsBackupCancel.Click += (s, e) => { try { dbManager?.SessionBackupCoordinator?.CancelCurrentBackup(); } catch { } };
            _tsBackupRecapture.Click += (s, e) =>
            {
                // 未バックアップからの 1 クリック復旧 = アセット込みで取り直す (操作単位の enqueue に乗る)。
                try { dbManager?.SessionBackupCoordinator?.RunAfterOperation(this, assetsChanged: true, "再バックアップ"); } catch { }
            };

            var backupCoord = dbManager.SessionBackupCoordinator;
            backupCoord.ProgressReporter = (p) =>
            {
                try
                {
                    if (IsDisposed || p == null) return;
                    Action apply = () => ShowBackupProgress(p.Percentage, p.Detail);
                    if (InvokeRequired) BeginInvoke(apply); else apply();
                }
                catch { /* 進捗表示は best-effort */ }
            };
            backupCoord.BackupRunningChanged = (running) =>
            {
                try
                {
                    if (IsDisposed) return;
                    Action apply = () =>
                    {
                        if (running) ShowBackupProgress(0, "");
                        else if (backupCoord.SessionAssetCaptureFailed) ShowBackupUnhealthy("⚠ ゲームファイルが未バックアップです（DB は保存済み）");
                        else HideBackupProgress();
                    };
                    if (InvokeRequired) BeginInvoke(apply); else apply();
                }
                catch { /* best-effort */ }
            };

            // 起動時に zombie staging dir (前回 update 失敗の残骸) を cleanup (#108 Phase 4)
            CleanupZombieStagings();

            // (#245 PR5 startup移管 step1) 全 init 完了後、WPF シェルを可視 main として表示し MainForm を裏方化する。
            //
            // **更新チェックより先に可視化する (#449)。** 逆順だと、cache が TTL 内のとき
            // `CheckAsync` が完了済み Task を返し、**完了済み Task の await は継続が同期実行される**ため
            // そのまま通知 MessageBox に突入して `StartBackgroundUpdateCheckIfDue()` から戻らず、
            // この行に永久に到達しない = スプラッシュのまま固まる。cache が冷えていれば本物の HTTP で
            // 非同期になり戻ってくるので、**「ネットワークが遅いおかげで助かっている」**だけの状態だった。
            // 順序を固定してタイミング依存を消す。
            ShowShellAsMain();

            // 起動時にバックグラウンドで GitHub Releases API を叩いてアップデート check (#108 Phase 4)
            // cache TTL 内なら HTTP を叩かない、起動を遅延させない fire-and-forget pattern
            StartBackgroundUpdateCheckIfDue();
        }

        /// <summary>
        /// (#245 PR5 startup移管 step1) WPF シェル(ShellWindow)を可視 main として表示し、MainForm を Hide して
        /// 裏方オーケストレータに徹する。MainForm 側の DB/セッション/パネル/バックアップ配線はそのまま生きており
        /// (実績ある起動シーケンスを無改変で温存)、シェルを閉じると MainForm も閉じてメッセージループを終了する。
        /// シェル生成/表示に失敗した場合は Opacity を戻して旧 WinForms UI を表示し、起動を継続する
        /// (#245 Phase 3 の graceful degradation 要件と整合)。
        ///
        /// 現段階の制約 (後続 step で解消): シェルの各ホストページは fresh パネル (= MainForm の実パネルとの
        /// 二重インスタンス) のまま。実パネルの単一インスタンス化 (再parent)・未保存ガード/ストア更新/GameCount/
        /// バックアップ進捗のステータスバー移植は別 step。
        /// </summary>
        private void ShowShellAsMain()
        {
            try
            {
                Shell.ShellWindow.SharedDb = dbManager;
                Shell.ShellWindow.HostForm = this; // (#245 PR5 step2) host ページが実パネルを取得するための参照
                var shell = new Shell.ShellWindow();
                _shell = shell; // (#245 PR5 step4) ステータス更新の流し込み先として保持
                // (#362) WinForms メッセージループ上で WPF 窓を出すと、キーボード入力 (NumberBox への直接入力・
                // Tab 移動等) が WinForms 側で処理されて WPF 側に届かない。ElementHost の keyboard interop を
                // 有効化して WPF 窓のキー入力を正しくルーティングする。
                System.Windows.Forms.Integration.ElementHost.EnableModelessKeyboardInterop(shell);
                // シェルを閉じたら MainForm も閉じて Application.Run を終了させる (= プロセス exit)。
                shell.Closed += (s, e) =>
                {
                    try { if (!IsDisposed) Close(); }
                    catch (Exception ex) { Logger.Warn("[MainForm] シェル close 後の MainForm.Close 失敗: " + ex.Message); }
                };
                shell.Show();
                Shell.SplashScreenHost.Close(); // (#246) スプラッシュを閉じる
                Hide(); // Load 完了済なので Hide で安全に裏方化 (= MainForm の窓・タスクバーボタンを消す)
                // (#246 / レビュー #4) ここから先 (前面化・ステータス反映) は **シェル表示済み** なので、失敗しても
                // フォールバックせずログのみにする。理由: Hide() 後は外側 catch の Opacity=1 では可視化できず
                // (Visible=false のまま) フォールバックが死蔵になる + シェルは既に出ているのでフォールバック不要。
                // 外側 catch は「シェル生成 / Show 失敗 (= MainForm 未 Hide)」専用に限定する。
                try
                {
                    // 別スレッドのスプラッシュがフォアグラウンドを握る + Hide() でフォアグラウンドが逃げるため、
                    // shell.Show() だけでは前面に来ない。Activate + Topmost 一瞬トグルで z-order 最前面を確実化。
                    shell.Activate();
                    shell.Topmost = true;
                    shell.Topmost = false;
                    UpdateStatusBar(); // (#245 PR5 step4) 初期ステータス (DB状態 + ゲーム数) をシェルに反映
                }
                catch (Exception postEx)
                {
                    Logger.Warn("[MainForm] (#245 PR5) シェル表示後の前面化/ステータス反映に失敗 (シェルは表示済み): " + postEx.Message);
                }
                Logger.Info("[MainForm] (#245 PR5) WPF シェルを可視 main として表示、MainForm を裏方化");
            }
            catch (Exception ex)
            {
                // シェル生成 / Show 失敗 = 旧 WinForms UI で起動継続 (graceful degradation)。ここは MainForm 未 Hide
                // なので可視化できる。シェル失敗は「旧 UI へ静かに degrade」なのでクラッシュダイアログは出さない (null)。
                Logger.Error("[MainForm] (#245 PR5) WPF シェル表示に失敗、旧 WinForms UI にフォールバック", ex);
                // (#449 レビュー M-3) **死んだシェルの Instance を残さない。** `ShellWindow.Instance` は
                // ctor で代入され `Closed` でしか消えないため、Show が HWND 生成後に失敗するとここに
                // 到達しても Instance が生き残り、VisibleModalOwner が「表示されていないシェル」を
                // owner として返してしまう。IsVisible check と併せて二重に閉じる。
                try { Shell.ShellWindow.Instance = null; } catch { }
                FallbackToVisibleMainForm(null);
            }
        }

        // (#245 PR5 startup移管 step2) シェルの host ページが実パネルを単一インスタンスで取得するための内部アクセサ。
        // MainForm が生成・初期化・イベント配線済みのインスタンスをそのまま返す (fresh 生成廃止で二重インスタンス解消)。
        internal Controls.GameSectionPanel GameSectionPanel => _gameSectionPanel;
        internal Controls.StoreSectionPanel StoreSectionPanel => _storeSectionPanel;
        internal Controls.BackupSectionPanel BackupSectionPanel => _backupSectionPanel;
        internal Controls.UpdateSectionPanel UpdateSectionPanel => _updateSectionPanel;
        internal Controls.IntroGuidePanel IntroGuidePanel => _introGuidePanel;
        internal Controls.LogSectionPanel LogSectionPanel => _logSectionPanel;
        internal Controls.SettingsSectionPanel SettingsSectionPanel => _settingsSectionPanel; // (#362 B2) WPF 設定ページの DBリセット委譲先

        /// <summary>
        /// 過去 run の失敗 / cancel で残った staging dir を起動時に best-effort 削除する (#108 Phase 4)。
        /// `%TEMP%/TonePrism_update_*` を全部削除。今 update 中 (= Manager 起動中に Updater spawn 直後)
        /// は normally 走らないので race condition なし。
        /// </summary>
        private void CleanupZombieStagings()
        {
            try
            {
                foreach (string dir in PathManager.EnumerateZombieStagings())
                {
                    try
                    {
                        System.IO.Directory.Delete(dir, recursive: true);
                        Services.Logger.Info("[MainForm] zombie staging 削除: " + dir);
                    }
                    catch (Exception ex)
                    {
                        Services.Logger.Warn("[MainForm] zombie staging 削除失敗: " + dir + " (" + ex.Message + ")");
                    }
                }
            }
            catch (Exception ex)
            {
                Services.Logger.Error("[MainForm] zombie staging cleanup エラー", ex);
            }
        }

        /// <summary>
        /// 起動時の background アップデート check (#108 Phase 4)。SettingsRepository の cache を参照し、
        /// TTL 超過なら GitHub Releases API を叩く。fire-and-forget で UI を遮らず、完了したら
        /// `_updateSectionPanel.OnCheckCompleted` で UI thread に marshal して反映。
        /// 新版検出 (Status=UpdateAvailable) 時は MessageBox で部員に通知してアップデートタブに誘導。
        /// 既にスキップ済 (Status=Skipped) / 最新 (UpToDate) / network 失敗時は通知しない。
        /// </summary>
        private async void StartBackgroundUpdateCheckIfDue()
        {
            try
            {
                if (dbManager == null) return;
                var checker = new Services.UpdateChecker(dbManager.SettingsRepository);
                // (#108 Phase 4 round 8 L-1) `Task.Run` 除去。`CheckAsync` は HttpClient.GetAsync 経由の
                // 真の async で UI thread をブロックしないため、`Task.Run` で thread pool 1 つ消費 +
                // 直ちに async state machine に戻る overhead が無駄だった。直接 await で同等動作 + thread pool 節約。
                Models.UpdateCheckResult result = await checker.CheckAsync(System.Threading.CancellationToken.None);
                if (result == null || _updateSectionPanel == null) return;
                _updateSectionPanel.OnCheckCompleted(result);
                if (result.Status == Models.UpdateCheckStatus.UpdateAvailable
                    && result.Latest != null
                    && !string.IsNullOrEmpty(result.Latest.TagName))
                {
                    // (#108 Phase 4 round 2 codex P2 / round 3 M-1) per-tag notified marker で「同 tag は 1 回
                    // dialog 表示」に絞る。round 3 M-1 fix: 直接 SettingsRepository.SetString ではなく
                    // UpdateChecker.MarkNotified / GetNotifiedTag 経由で _settingsWriteLock 内で書込み
                    // (= M4 invariant 維持)。
                    string notifiedTag = checker.GetNotifiedTag();
                    if (string.Equals(notifiedTag, result.Latest.TagName, StringComparison.Ordinal))
                    {
                        Services.Logger.Info("[MainForm] UpdateAvailable 検出 (tag=" + result.Latest.TagName + ") だが notified marker 一致、通知 skip");
                    }
                    else
                    {
                        // (#108 Phase 4 round 4 codex P2 NEW) MarkNotified は MessageBox 表示成功時のみ。
                        // 旧実装は無条件 marker 更新で、UI error (BeginInvoke 失敗 / MessageBox 例外) で
                        // dialog 表示されなかった case でも marker set → 次回起動以降 永久 suppress に
                        // なる path があった。ShowUpdateAvailableNotification を bool 返却に変更、
                        // success のみ MarkNotified 経路に流す。
                        bool shown = ShowUpdateAvailableNotification(result);
                        if (shown)
                        {
                            // (#170 followup) MarkNotified は **意図的に CheckBeforeWrite を呼ばない**。
                            // 理由 3 つ: (1) auto background path (StartBackgroundUpdateCheckIfDue) からの
                            // 自動副作用で user 操作直接 trigger ではない、(2) 非破壊的な metadata write
                            // (= 同 tag 上書きでも実害ゼロ、SQLite WAL で atomic)、(3) 直前に通知 dialog を
                            // user が dismiss したばかりで、直後に「他 PC 競合中」popup を出すと UX 二重表示
                            // で煩雑。background の auto 副作用 path は popup ではなく write の atomic 性に
                            // 依存する、という判断基準。本 PR の plan
                            // で当初追加候補だったが、background thread + auto side-effect + 非破壊性 という
                            // 3 constraint で意図的に skip と文書化。
                            checker.MarkNotified(result.Latest.TagName);
                        }
                        else
                        {
                            Services.Logger.Warn("[MainForm] UpdateAvailable 通知 dialog 表示に失敗、marker 更新 skip (次回起動で再通知)");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Services.Logger.Error("[MainForm] BackgroundUpdateCheck エラー", ex);
            }
        }

        /// <summary>
        /// (#449) **モーダルの owner に渡してよい「今この瞬間に可視でタスクバーに出ている窓」**を返す。
        /// 該当が無ければ <c>null</c>。
        ///
        /// <para>
        /// **機序 (レビュー M-6 で訂正)**: 所有ダイアログが自前のタスクバーボタンを持たないのは
        /// **owned であること自体**が理由で、owner の透明度とは関係ない。決定的なのは
        /// **owner 自身がタスクバーに出ているか** — タスクバーは `GetLastActivePopup` 経由で
        /// 所有モーダルを前面化するので、owner がタスクバーに居れば戻せる。逆に
        /// 「まだ表示されていない窓」「`Hide()` 済みの窓」を owner にすると戻す導線が消える。
        /// #449 の実害は「透明だから」ではなく **`MainForm_Load` が return する前 = MainForm が
        /// 一度も表示されていない状態の窓を owner にしたから**だった。
        /// </para>
        /// <para>
        /// **`null` は「owner なし」ではない (レビュー H-2)**: WinForms の `MessageBox.Show` は
        /// owner が `null` のとき呼び出しスレッドの `GetActiveWindow()` を owner に代入する。
        /// つまり `null` を渡しても不可視の MainForm が owner に戻りうる。**`null` は
        /// 「これ以上できることが無い」という意味であって、到達可能性の保証ではない。**
        /// 到達可能性が要る場面 (ゲート dialog 等) は <see cref="MakeMainFormVisible"/> で
        /// 可視 owner を作ってから渡すこと。
        /// </para>
        /// </summary>
        private IWin32Window VisibleModalOwner()
        {
            // [1] 可視シェル。WPF Window は既定で ShowInTaskbar=true なので戻す導線がある。
            //     **`IsVisible` を必ず見る (レビュー M-3)** — `ShellWindow.Instance` は ctor で
            //     代入され `Closed` でしか消えないため、`shell.Show()` が HWND 生成後に失敗すると
            //     「表示されていないシェル」の HWND が残る。それを owner にすると本規約違反になる。
            var shell = Shell.ShellWindow.Instance;
            if (shell != null && shell.IsVisible)
            {
                IWin32Window shellOwner = Shell.ShellOwner.For(shell);
                if (shellOwner != null) return shellOwner;
            }

            // [2] MainForm が実際に表示されているならそれ (= FallbackToVisibleMainForm 後の degraded 経路)。
            //     `Opacity > 0` も見る — 起動中の裏方状態 (Opacity=0) を弾くため。
            if (!IsDisposed && Visible && Opacity > 0) return this;

            // [3] 該当なし。呼び出し側が到達可能性を要求するなら MakeMainFormVisible を先に呼ぶこと。
            return null;
        }

        /// <summary>
        /// (#449) スプラッシュを閉じ、MainForm を**実際に表示された窓**にする。
        /// ゲート dialog のように「必ず前面に戻せる」ことが要る場面で、owner を用意するために使う。
        /// <see cref="FallbackToVisibleMainForm"/> の可視化部分を切り出したもの。
        /// </summary>
        private void MakeMainFormVisible()
        {
            try { Shell.SplashScreenHost.Close(); } catch { }
            try { this.Opacity = 1; if (!Visible) Show(); } catch { }
        }

        /// <summary>
        /// 新バージョン検出時に MessageBox で通知して「アップデート」タブに誘導する (#108 Phase 4)。
        /// `Status=UpdateAvailable` の case でのみ呼ばれる (Skipped / UpToDate / 失敗時は呼ばれない、
        /// = 「スキップしたバージョンが新 release で更新されるまで再通知しない」semantic を上位で保証)。
        ///
        /// **戻り値 (round 4 codex P2 NEW + round 5 L-1)**: dialog が **実際に user に表示された** ら
        /// true、UI error (Invoke 失敗 / MessageBox 例外 / form 破棄) で表示前に early return した場合は
        /// false。caller (StartBackgroundUpdateCheckIfDue) は true 時のみ MarkNotified を呼ぶ責務、
        /// false 時は marker 更新 skip で次回起動で再通知する。
        ///
        /// round 5 L-1: 旧実装は async recursive call (BeginInvoke) で楽観的 true return していたが、
        /// 実際 caller `StartBackgroundUpdateCheckIfDue` は `await Task.Run` 後 SynchronizationContext
        /// 経由で UI thread に戻るため `InvokeRequired = false` 確定の dead path だった。defensive
        /// として残す場合は **synchronous Invoke** で recursive call の結果を caller に正確に返す形に。
        /// </summary>
        private bool ShowUpdateAvailableNotification(Models.UpdateCheckResult result)
        {
            if (InvokeRequired)
            {
                // (round 5 L-1) defensive path: BeginInvoke の楽観 true は嘘になるため Invoke で
                // synchronous に recursive call → result を caller に正確に返す。
                try
                {
                    return (bool)Invoke(new Func<Models.UpdateCheckResult, bool>(ShowUpdateAvailableNotification), result);
                }
                // (round 4 M-3) ObjectDisposedException : InvalidOperationException 派生関係のため
                // specific を先に置いて意図明示。
                catch (ObjectDisposedException) { return false; /* form 完全 Dispose 済 */ }
                catch (InvalidOperationException) { return false; /* form 破棄済み */ }
            }

            string currentLabel = result.Current == null ? "(不明)" : "v" + result.Current.ToString(3);
            string latestLabel = result.Latest.TagName;
            string message =
                "新しいバージョンが利用可能です。\n\n" +
                "現在のバージョン: " + currentLabel + "\n" +
                "最新のバージョン: " + latestLabel + "\n\n" +
                "「アップデート」タブを開いてリリースノートを確認しますか？\n" +
                "(あとで確認する場合は「いいえ」、このバージョンを無視するには「アップデート」タブの「このバージョンをスキップ」を押してください)";

            DialogResult dr;
            try
            {
                // **不可視の MainForm を owner にしない (#449)。**
                // MainForm は ctor で `Opacity = 0` にしてあり、シェル表示後は `Hide()` される。
                // 透明 / 非表示の窓を owner にすると、Windows の仕様で **所有ダイアログはタスクバー
                // ボタンも Alt+Tab エントリも持たない**。つまり一度 z-order で他の窓の下に潜ると
                // ユーザーが前面に戻す手段が無くなり、「スプラッシュから進まない・閉じられない」に見える
                // (実際に仮想本番で発生し、Win32 API で外から閉じるしかなかった)。
                //
                // 可視シェルがあればそれを owner にする (シェルに対して正しくモーダルになる)。
                // まだ無ければ **owner なし** で出す — 所有されない dialog は top-level 窓になるので
                // タスクバー / Alt+Tab から必ず戻ってこられる。
                IWin32Window owner = VisibleModalOwner();
                dr = owner != null
                    ? MessageBox.Show(owner, message, "アップデートの通知",
                        MessageBoxButtons.YesNo, MessageBoxIcon.Information, MessageBoxDefaultButton.Button1)
                    : MessageBox.Show(message, "アップデートの通知",
                        MessageBoxButtons.YesNo, MessageBoxIcon.Information, MessageBoxDefaultButton.Button1);
            }
            catch (Exception ex)
            {
                Services.Logger.Error("[MainForm] ShowUpdateAvailableNotification エラー", ex);
                return false;
            }
            if (dr == DialogResult.Yes && tabControl1 != null)
            {
                try
                {
                    tabControl1.SelectedTab = tabUpdate;
                }
                catch (Exception ex)
                {
                    Services.Logger.Warn("[MainForm] tabUpdate 切替失敗: " + ex.Message);
                }
            }
            return true; // (round 4 codex P2 NEW) dialog 表示完了 = success
        }


        private void InitializeDatabase()
        {
            try
            {
                PathManager.EnsureDirectoriesExist();
                dbManager.InitializeDatabase();

                MessageBox.Show(
                    "データベースの初期化が完了しました。",
                    "成功", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"データベースの初期化に失敗しました。\n\n{ex.Message}",
                    "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void OnDatabaseReset()
        {
            _gameSectionPanel.LoadGames();
            _storeSectionPanel.LoadSections();
            _introGuidePanel.LoadSlides(); // (#253)
            UpdateStatusBar();
        }

        /// <summary>
        /// バックアップからの復元完了時。各パネルを再ロードする。
        /// </summary>
        private void OnDatabaseRestored()
        {
            try
            {
                // 復元によりスキーマやデータが変わっているので、必要なら再初期化
                dbManager.InitializeDatabase();

                // (backup_log 廃止 / DB v19) 復元後の register / reconcile は不要。履歴は backups/ フォルダ
                // 走査由来 (BackupCatalogService) で、復元で作られた safety_*.db も自動的に履歴へ現れる。
                _gameSectionPanel.LoadGames();
                _storeSectionPanel.LoadSections();
                _introGuidePanel.LoadSlides(); // (#253)
                _settingsSectionPanel.UpdateVersionInfo();
                UpdateStatusBar();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"復元後の再読み込みに失敗しました: {ex.Message}",
                    "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void tabControl1_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (tabControl1.SelectedTab == tabStore)
            {
                _storeSectionPanel.LoadSections();
            }
        }

        // (#170 followup) status bar の左 / 右 zone を分離。
        //   左 (lblStatus): データベース接続状態 + ゲーム数 = 永続表示
        //   右 (lblBackupStatus): 自動バックアップの transient 状態 = autoRevert=true なら 7 秒で消える
        // 旧実装は 1 ラベル 1 関数で、auto backup message が「ゲーム数」を上書きして元情報が一時消失していた。
        private System.Windows.Forms.Timer _backupStatusClearTimer;

        private void UpdateStatusBar()
        {
            if (dbManager == null) return;
            string dbStatus = dbManager.DatabaseExists() ? "接続済み" : "未接続";
            string gameInfo = $"ゲーム数: {_gameSectionPanel.GameCount}件";
            string text = $"データベース: {dbStatus} | {gameInfo}";
            lblStatus.Text = text;
            _shell?.SetStatusText(text); // (#245 PR5 step4) シェルのステータスバーにも反映
        }

        /// <summary>
        /// (#170 followup) status bar の右 zone (`lblBackupStatus`) に transient な backup 状態を表示する。
        /// 左 zone (`lblStatus` の「データベース | ゲーム数」) は変えない (= 旧 UpdateStatusBar(string) の
        /// 上書き問題への対処)。
        ///
        /// `autoRevert=true` で渡すと 7 秒後に自動 clear する Timer を仕掛ける (= 完了 / 失敗 message が
        /// 永続表示で stale になるのを防ぐ)。`autoRevert=false` は「実行中...」のような完了まで残したい
        /// 状態用、次の `UpdateBackupStatus` 呼出か手動 clear まで残る。
        ///
        /// Accessibility: color 情報を text prefix で補強する (`✓` / `✗`)、screen reader で color を
        /// 識別できない user 向けの fallback。
        /// </summary>
        private void UpdateBackupStatus(string message, System.Drawing.Color color, bool autoRevert)
        {
            // (#170 followup round 2) lblBackupStatus は Designer で Alignment=Right + AutoSize=true 設定済。
            // strip 右端から natural width 分を anchor 配置するため、Text / ForeColor 設定だけで OK。
            // (review M-2) 長文 message (= SQLite error / 長 path) で strip 幅超過 + left zone 重なりを防ぐため、
            // 表示 text を 80 文字に pre-truncate (= chevron に逃げる前の defense)。完全な message は呼出元
            // (e.g., 自動 backup 失敗 path) で Logger.Error として別途残るため UI で truncated でも debug 可能。
            lblBackupStatus.Text = TruncateForStatusBar(message);
            lblBackupStatus.ForeColor = color;
            // (#245 step4 / レビュー #5) シェルのバーにも反映。シェルの第2引数は「成功か」なので、autoRevert
            // (自動消去するか・本来 ok と直交) ではなく色 (緑=成功) を真実源にする。現状 autoRevert==ok だが疎結合化。
            _shell?.SetBackupStatus(message, color == System.Drawing.Color.DarkGreen);

            // 既存 timer を破棄してから新規 (= 連続呼出時に古い timer が古い message を消すのを防ぐ)
            if (_backupStatusClearTimer != null)
            {
                _backupStatusClearTimer.Stop();
                _backupStatusClearTimer.Dispose();
                _backupStatusClearTimer = null;
            }
            if (autoRevert && !string.IsNullOrEmpty(message))
            {
                _backupStatusClearTimer = new System.Windows.Forms.Timer();
                _backupStatusClearTimer.Interval = 7000;
                _backupStatusClearTimer.Tick += BackupStatusClearTimer_Tick;
                _backupStatusClearTimer.Start();
            }
        }

        // (#299) 下部ステータスバーに統合したバックアップ進捗 item の表示制御。いずれも UI スレッドで呼ぶこと。
        // 表示順 [phase 固定"バックアップ中..."][中止][進捗バー][ファイル名(可変・末尾)] で、中止ボタンが per-file で動かない。
        /// <summary>実行中: 「バックアップ中...」+ 中止 + 進捗バー + 現在ファイル名 を表示 (左詰め、lblStatus の右)。</summary>
        private void ShowBackupProgress(int percent, string fileName)
        {
            int p = percent < 0 ? 0 : (percent > 100 ? 100 : percent);
            _tsBackupPhase.ForeColor = System.Drawing.SystemColors.ControlText;
            _tsBackupPhase.Text = "バックアップ中...";   // 固定文言 = 幅不変 → 後続の中止位置が固定
            _tsBackupPhase.Visible = true;
            _tsBackupCancel.Visible = true;
            try { _tsBackupBar.Value = p; } catch { /* Maximum 変更レース等は無害 */ }
            _tsBackupBar.Visible = true;
            _tsBackupPercent.Text = p + "%";
            _tsBackupPercent.Visible = true;
            _tsBackupFile.Text = fileName ?? string.Empty; // 可変幅は末尾なので動いても他に影響しない
            _tsBackupFile.Visible = true;
            _tsBackupRecapture.Visible = false;
            _shell?.ShowBackupProgress(p, fileName); // (#245 step4) シェルのバーにも反映
        }

        /// <summary>未バックアップ (失敗/中断): 警告 + 「今すぐバックアップ」(1 クリック復旧) を表示。</summary>
        private void ShowBackupUnhealthy(string message)
        {
            _tsBackupPhase.ForeColor = System.Drawing.Color.DarkOrange;
            _tsBackupPhase.Text = message;
            _tsBackupPhase.Visible = true;
            _tsBackupCancel.Visible = false;
            _tsBackupBar.Visible = false;
            _tsBackupPercent.Visible = false;
            _tsBackupFile.Visible = false;
            _tsBackupRecapture.Visible = true;
            _shell?.ShowBackupUnhealthy(message); // (#245 step4) シェルのバーにも反映
        }

        /// <summary>idle かつ健全: バックアップ進捗 item を全て非表示。</summary>
        private void HideBackupProgress()
        {
            _tsBackupPhase.Visible = false;
            _tsBackupCancel.Visible = false;
            _tsBackupBar.Visible = false;
            _tsBackupPercent.Visible = false;
            _tsBackupFile.Visible = false;
            _tsBackupRecapture.Visible = false;
            _shell?.HideBackupProgress(); // (#245 step4) シェルのバーにも反映
        }

        // (#245 PR5 step4) シェルのバックアップバーのボタン (中止 / 今すぐバックアップ) から呼ばれる。
        // coordinator 操作は従来どおり MainForm が owner として行う (= 旧 statusStrip ボタンと同じ実体)。
        internal void CancelSessionBackup()
        {
            try { dbManager?.SessionBackupCoordinator?.CancelCurrentBackup(); } catch { }
        }

        internal void RecaptureBackupNow()
        {
            try { dbManager?.SessionBackupCoordinator?.RunAfterOperation(this, assetsChanged: true, "再バックアップ"); } catch { }
        }

        /// <summary>(#299) StatusStrip 上の ToolStripButton (中止 / 今すぐバックアップ) に常時枠を描いて「ボタンらしく」
        /// 見せる専用レンダラー。実 Button のホスト (ToolStripControlHost) はレイアウト破壊 + 残像を招くため、フラットな
        /// ToolStripButton + 本レンダラーで枠を出す方式にした (ホストしないので他 item も正常表示され残像も出ない)。</summary>
        private sealed class BorderedStatusButtonRenderer : System.Windows.Forms.ToolStripProfessionalRenderer
        {
            protected override void OnRenderButtonBackground(System.Windows.Forms.ToolStripItemRenderEventArgs e)
            {
                base.OnRenderButtonBackground(e);
                if (e.Item is System.Windows.Forms.ToolStripButton && e.Item.Visible)
                {
                    var r = new System.Drawing.Rectangle(0, 0, e.Item.Width - 1, e.Item.Height - 1);
                    e.Graphics.DrawRectangle(System.Drawing.SystemPens.ControlDark, r);
                }
            }
        }

        /// <summary>
        /// (#170 followup round 2 review M-2) status bar 右 zone 用の text truncation helper。
        /// 経験則上 80 chars で過半数の典型 message (= 自動 backup 失敗 SQLite error / 長 path) を救い、
        /// 極端 overflow は WinForms StatusStrip の chevron に逃げる設計。
        ///
        /// 注: 厳密な pixel 幅判定はしない (= 全角混じり / window resize / DPI scaling で精度差あり)。
        /// 完全な message は呼出元 (e.g., `SessionBackupCoordinator` の `Logger.Warn`) で別途 log に残るため
        /// UI で truncated でも debug 可能、本 helper は user 視覚的 alarm 用 carry-best-effort と位置付け。
        /// </summary>
        private static string TruncateForStatusBar(string message)
        {
            if (string.IsNullOrEmpty(message)) return string.Empty;
            const int MaxLen = 80;
            if (message.Length <= MaxLen) return message;
            // 先頭 50 文字 + "..." + 末尾 27 文字 で末尾 (ファイル名等) を維持
            return message.Substring(0, 50) + "..." + message.Substring(message.Length - 27);
        }

        private void BackupStatusClearTimer_Tick(object sender, EventArgs e)
        {
            lblBackupStatus.Text = string.Empty;
            if (_backupStatusClearTimer != null)
            {
                _backupStatusClearTimer.Stop();
                _backupStatusClearTimer.Dispose();
                _backupStatusClearTimer = null;
            }
        }

        // (#178 (b)) アップデート完了通知 dialog。invariant:
        //   sentinel ファイルは読込直後の `finally` で必ず削除 (parse 成功 / 失敗問わず、永続再表示バグ防止)。
        // 仕様: SPECIFICATION.md §3.7.3。
        //
        // (round 4 Medium-3) 旧 docstring の「同時起動注意 MessageBox との排他置換 → true/false 返却で
        // caller が gate」invariant は本 PR (#179 / #178 (c) で同時起動 MessageBox を撤廃) で消滅。
        // 戻り値を使う caller も居ない (MainForm_Load:104 の呼出は戻り値捨て) ため signature を void 化。

        /// <summary>
        /// sentinel ファイル `<install>/.update_completed` を読んで完了 dialog を表示。
        /// sentinel 不在時は no-op。仕様 SPECIFICATION.md §3.7.3 参照。
        /// </summary>
        private void TryShowUpdateCompletedDialog()
        {
            // (レビュー C-1) **起動時の consume はここで行う。** アップデートタブの Initialize は
            // ContinueLoadAfterSessionCheck の中にあり、DB 初期化拒否や同時起動 Cancel では到達しない。
            // そこに置くと成功記録が消えずに残り、残った exit 0 が後続の失敗を隠す
            // (resultFileMissing が false になり updaterLeftNoTrace が発火しない)。
            // 本メソッドは MainForm_Load 冒頭で、それらの early-return より先に走る。
            //
            // (レビュー Low-3) **consume は sentinel の有無より前**に置く。sentinel の書き込みは
            // Logger.Warn で握り潰される (書けなくても installation 自体は完成しているため) ので、
            // 「更新は成功したが sentinel が無い」起動が実在する。そこで consume を skip すると
            // 成功記録が残り、C-1 で塞いだ「残った exit 0 が後続の失敗を隠す」経路が細く復活する。
            var prevState = Services.UpdaterClient.ConsumePreviousRunState();

            string sentinelPath = System.IO.Path.Combine(PathManager.BaseDirectory, ".update_completed");
            if (!System.IO.File.Exists(sentinelPath)) return;

            string newVersion = null;
            string completedAtRaw = null;
            string expectedManagerVersion = null;
            try
            {
                string json = System.IO.File.ReadAllText(sentinelPath, System.Text.Encoding.UTF8);
                var dto = Services.JsonCompat.Deserialize<UpdateCompletedSentinel>(json);
                if (dto != null)
                {
                    newVersion = dto.NewVersion;
                    completedAtRaw = dto.CompletedAt;
                    expectedManagerVersion = dto.NewManagerVersion;
                }
            }
            catch (Exception ex)
            {
                Services.Logger.Warn("[MainForm] update_completed sentinel parse 失敗 (dialog 表示 skip): " + ex.Message);
            }
            finally
            {
                // 読込結果に関わらず sentinel は必ず削除する (永続 dialog 再表示バグ防止)。
                try { System.IO.File.Delete(sentinelPath); }
                catch (Exception delEx) { Services.Logger.Warn("[MainForm] update_completed sentinel 削除失敗: " + delEx.Message); }
            }

            if (string.IsNullOrEmpty(newVersion))
            {
                // parse 失敗 / newVersion 不在は dialog 出さず終了 (sentinel は finally で削除済)。
                return;
            }

            // (#440) **成功と言う前に、本当に置換されたかを確認する。**
            //
            // sentinel は Updater の spawn 成功後に書かれるだけで、spawn した Updater が**その後で**
            // 失敗するケース (Manager dir の置換失敗) を見ていなかった。そのため置換に失敗した
            // **古い Manager** が起動して「✓ アップデート完了 / 新しい管理ソフトが起動しています」と
            // 表示していた。更新失敗に気付けるのはアップデートタブを開いて「前回のアップデート結果:
            // 内部エラー」を読んだときだけで、実際 v0.9.0 以降 2 リリース分これで隠れていた (#440)。
            //
            // ここで比べるのは「入るはずだった Manager の版数」と「今動いている自分の版数」。
            // 一致しなければ、何が原因であれ置換は完了していない。
            // 判定は **2 つの材料の OR**。版数比較だけだと、Manager の版数が変わらない Bundle リリース
            // (Launcher だけ上げた等) で置換に失敗しても expected == running になって成功扱いになる。
            // 「一致しなければ失敗」は正しいが、その逆 (一致すれば成功) は成り立たない。
            Version running = Services.VersionInventory.ReadManagerVersion();
            Version expectedVer;
            // **比較は 3-part に揃える。** running は AssemblyVersion、expected は apphost の
            // FileVersion (= AssemblyFileVersion 由来) で **SoT が違う**。リリースゲート
            // (Release.ps1 の Assert-PublishedManagerVersion) が一致を強制しているのも 3-part までで、
            // revision だけ drift しても公開は通る。4-part で比べると、その場合に全ユーザーが
            // 偽の「✗ アップデート未完了」を食らう。ゲートと同じ粒度にしておく。
            // (レビュー C-2) `Version.TryParse` は 2 パート ("1.0") でも成功するが、`ToString(3)` は
            // 要素数を超える fieldCount で ArgumentException を投げる。expectedManagerVersion は
            // staging exe の VERSIONINFO 由来の**任意文字列**なので 2 パート値がありうる。
            // ここで throw すると LoadCore の catch に拾われ、WPF シェルもタブ初期化も skip された
            // degraded な旧 UI で起動する = 更新が成功していても起動体験が壊れる。
            // parse できた上で **3 パート以上ある**ことまでを条件にする (Build < 0 が 3 パート未満)。
            bool expectedParsed = Version.TryParse(expectedManagerVersion, out expectedVer)
                && expectedVer.Build >= 0;
            // (レビュー 5) parse 失敗は「不一致なし」に倒れる = 版数照合が丸ごと効かない。
            // sentinel の newManagerVersion は FileVersionInfo.FileVersion 由来で、null や
            // "0.34.1.0 (rel)" のような非 Version 文字列になりうる (staging の exe を直接読むこの経路には
            // Release.ps1 の [version] 検証が効かない)。他の 2 レグが残るので silent pass にはならないが、
            // 「照合が効いていない」ことが誰にも見えないのは駄目なので必ずログに残す。
            if (!string.IsNullOrEmpty(expectedManagerVersion) && !expectedParsed)
            {
                Services.Logger.Warn("[MainForm] (#440) 申し送りの newManagerVersion を 3 パート以上の Version として"
                    + " 解釈できません (版数照合を skip、終了コードと結果ファイルの有無で判定します): " + expectedManagerVersion);
            }
            bool versionMismatch = !string.IsNullOrEmpty(expectedManagerVersion)
                && running != null
                && expectedParsed
                && running.ToString(3) != expectedVer.ToString(3);
            // (#440) 一次情報は Updater が書き残した実行結果。無い場合 (旧 Updater) だけ、従来の
            // ログ推測にフォールバックする。ログ推測は「末尾 20 行に [ERROR] があれば失敗」+「直近 2 分」
            // というヒューリスティックで、文言依存で壊れるうえ失敗の翌朝には読めない。
            int? exitCode = Services.UpdaterClient.PreviousRunExitCode
                ?? Services.UpdaterClient.TryLoadLastExitCode();
            // (レビュー Medium-1) **成功コードを「原因」として出さない。** 版数不一致だけで失敗と
            // 判定した経路では exitCode が 0 のことがあり、そのまま埋めると
            // 「アップデートに失敗しました … 原因: アップデート完了」という自己矛盾した文面になる。
            string detail = "原因不明";
            if (exitCode.HasValue)
            {
                Services.ExitCodeDispatch d = Services.UpdaterClient.DispatchExitCode(exitCode.Value);
                detail = (d.Severity == Services.ExitSeverity.Success)
                    ? "更新プログラムは成功と報告しましたが、置換が反映されていません"
                    : d.Title;
            }
            bool exitFailed = (prevState == Services.UpdaterClient.PreviousRunState.Failed)
                || (prevState != Services.UpdaterClient.PreviousRunState.Succeeded
                    && exitCode.HasValue
                    && Services.UpdaterClient.DispatchExitCode(exitCode.Value).Severity != Services.ExitSeverity.Success);

            // (#440) **結果ファイルが「無い」ことも失敗の証拠になりうる。**
            //
            // ただし「無い」には (a) 一度も更新していない (b) 旧 Updater が動いた (c) Updater が
            // finally に到達せず死んだ、が混ざっているので、無条件に失敗扱いすると通常起動のたびに
            // 偽の警告が出る。切り分けるのは **申し送りに版数が入っているか**:
            // `newManagerVersion` を書くのは #440 以降の Manager だけで、その世代なら Updater も
            // 必ず結果を残す (書けない 3 経路は Manager dir に触れないので版数比較が拾う)。
            // つまり「版数入りの申し送りがあるのに結果が無い」= Updater が痕跡を残さず終わった、と
            // 特定できる。ここを見逃すと #440 と同じ「壊れているのに ✓ と言う」に戻る。
            //
            // v0.11.0 → v0.11.1 の 1 回だけは旧 Manager が申し送りを書く (版数なし) ため発火しない。
            // (レビュー Medium) **「ファイルが無い」と「あるが読めない」を区別する。**
            // どちらも TryLoadUpdateResult は null を返すが、意味は正反対 — 「無い」は
            // Updater が痕跡を残さず終わった証拠になりうる一方、「読めない」は単に判定できないだけ。
            // 混ぜると、成功した更新でファイルがロック / 破損していただけで偽の「✗ 未完了」を出す。
            bool resultFileMissing = (prevState == Services.UpdaterClient.PreviousRunState.NoRecord);
            bool updaterLeftNoTrace = !string.IsNullOrEmpty(expectedManagerVersion) && resultFileMissing;
            if (updaterLeftNoTrace)
            {
                detail = "更新プログラムが結果を残さずに終了しました";
            }

            // (レビュー D-1) **「確かめられなかった」を「確かめて成功だった」と同じに扱わない。**
            // 記録が破損している (File.WriteAllText は非アトミックなので停電・強制終了で torn write
            // しうる) と、失敗の証拠は全部消える — ファイルは在るので updaterLeftNoTrace は発火せず、
            // ログ推測も 2 分窓を過ぎれば何も返さず、Manager 版数が変わらない Bundle なら版数照合も
            // 通る。そのまま「✓ 完了」を出すのは、本 PR がまさに直している silent pass そのもの。
            bool resultUnreadable = (prevState == Services.UpdaterClient.PreviousRunState.Unreadable);

            if (!versionMismatch && !exitFailed && !updaterLeftNoTrace && resultUnreadable)
            {
                Services.Logger.Warn("[MainForm] (#440) アップデートの結果を確認できません (.update_result が破損)");
                MessageBox.Show(
                    "アップデートの結果を確認できませんでした。\n\n"
                        + "ゲームのデータは失われていません。そのままお使いいただけます。\n\n"
                        + "「アップデート」タブでバージョンをご確認ください。\n"
                        + "古いままだった場合は、もう一度アップデートをお試しください。",
                    "アップデート結果を確認できません",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                return;
            }

            if (versionMismatch || exitFailed || updaterLeftNoTrace)
            {
                Services.Logger.Error("[MainForm] (#440) アップデートが完了していません: 期待 Manager v"
                    + (expectedManagerVersion ?? "(不明)") + " / 実際に起動しているのは v"
                    + (running != null ? running.ToString() : "(不明)")
                    + " / Updater 終了コード=" + (exitCode.HasValue ? exitCode.Value.ToString() : "(記録なし)"));

                // (#440) Updater が結果を残していない場合は **ここで書く**。申し送りは読んだ時点で
                // 必ず消える一度きりの通知なので、書かないと次回起動で判断材料が全部無くなり
                // 「最新版を実行中」+ ボタン無効の袋小路に戻る (= #440 と同じ行き止まり)。
                //
                // 申し送りの方を残す案は採らない — 手動で Install.bat から復旧しても結果ファイルは
                // 生まれないため、直したのに永久に警告が出続けることになる。状態の置き場所を
                // .update_result 1 つに保つ (消えるのは成功確認 / 次の試行の上書き / Install.bat の掃除の 3 経路)。
                //
                // **期待版数が無いときは記録しない。** その場合の失敗判定はログ推測 (末尾 20 行の
                // [ERROR]) 由来で当てにならず、当てにならない根拠で貼りつく状態を作るべきではない。
                //
                // (レビュー High-2) 条件は「記録が無い」ではなく「**失敗と判定したのに、失敗を示す
                // 記録が残っていない**」。旧条件だと、版数照合だけで失敗を検出した (= Updater が
                // exit 0 を書いたのに実際には置換が効いていない。Updater 側の版数検証は片方でも
                // 版数を読めなければ警告に留めて続行するので実在する) ケースで証拠が一切残らず、
                // しかも成功記録は consume 済みで消えている。次回起動では sentinel も記録も無く、
                // CHANGELOG は新版数なので「最新版を実行中」+ ボタン無効 = #440 の症状に戻る。
                if (prevState != Services.UpdaterClient.PreviousRunState.Failed
                    && !string.IsNullOrEmpty(expectedManagerVersion))
                {
                    Services.UpdaterClient.RecordFailureWithoutUpdaterResult(expectedManagerVersion);
                }

                // 版数の行は **不一致のときだけ** 出す。判定は「版数の不一致 OR 終了コードの失敗」なので、
                // 終了コードだけで失敗した経路では両者が同値になり「v0.34.1.0 / 本来は v0.34.1.0」という
                // 不可解な表示になる (期待版数が読めなければ「本来は v不明」)。
                string failBody = "アップデートに失敗しました。\n\n";
                if (versionMismatch)
                {
                    failBody += "  管理ソフトが古いままです（v" + running + " / 本来は v" + expectedManagerVersion + "）\n";
                }
                failBody += "  原因: " + detail + "\n\n"
                    + "ゲームのデータは失われていません。そのままお使いいただけます。\n\n"
                    + "「アップデート」タブからもう一度お試しください。\n"
                    + "それでも失敗する場合は、logs フォルダの中の記録ファイルを\n"
                    + "そえて、開発者に連絡してください。";
                MessageBox.Show(
                    failBody,
                    "✗ アップデート未完了",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                return;
            }
            // 成功記録の消費は、このメソッド冒頭の ConsumePreviousRunState で既に済んでいる
            // (レビュー C-1 で、到達しない経路のあるタブ初期化からここへ移した)。
            // 結果はプロセス内でキャッシュされるので、タブ側が後から読んでも同じ答えになる。

            // CompletedAt は writer が ISO 8601 UTC で書き出した値 ("yyyy-MM-ddTHH:mm:ssZ")。dialog では
            // user-friendly な local time format に変換 ("yyyy-MM-dd HH:mm")。parse 失敗時は空文字で fallback、
            // dialog 表示は version のみで継続 (= 完了時刻不在で dialog 出ない方が UX 悪なので silent fallback)。
            string completedAtLocal = string.Empty;
            if (!string.IsNullOrEmpty(completedAtRaw))
            {
                DateTime parsed;
                if (DateTime.TryParse(completedAtRaw,
                        System.Globalization.CultureInfo.InvariantCulture,
                        System.Globalization.DateTimeStyles.AssumeUniversal | System.Globalization.DateTimeStyles.AdjustToUniversal,
                        out parsed))
                {
                    completedAtLocal = parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm");
                }
            }

            Services.Logger.Info("[MainForm] update_completed dialog 表示: Bundle v" + newVersion + " completedAt=" + (completedAtRaw ?? "(null)"));
            string body = "アップデートが完了しました。\n\n" +
                          "  Bundle バージョン: v" + newVersion + "\n";
            if (!string.IsNullOrEmpty(completedAtLocal))
            {
                body += "  完了時刻: " + completedAtLocal + "\n";
            }
            body += "\n新しい管理ソフトが起動しています。";
            MessageBox.Show(
                body,
                "✓ アップデート完了",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }

        /// <summary>
        /// (#201, v0.15.0) ログ保存先 setting auto-migrate 完了通知 dialog。
        /// `<install>/.logs_root_migrated` sentinel ファイル存在 check → 部員向け subdir 構造説明 MessageBox 表示
        /// → sentinel 削除。次回起動以降は sentinel 不在で発火しない。
        ///
        /// sentinel JSON schema: `{"migratedFrom": "<oldValue>", "migratedAt": "<ISO 8601 UTC>"}`
        /// (= `Program.WriteLogsRootMigrationSentinel` で書出済、wire format は **真の camelCase** で
        /// PascalCase DTO と `JavaScriptSerializer` の case-insensitive deserialize で互換、R2 review
        /// Critical #1 で snake_case → camelCase に修正済)。
        /// 例外は内部で握り潰し (= Manager 起動を阻害しない)、parse 失敗時も sentinel は finally で削除する
        /// (永続 dialog 再表示バグ防止、TryShowUpdateCompletedDialog と同 pattern)。
        /// </summary>
        private void TryShowLogsRootMigratedDialog()
        {
            string sentinelPath = System.IO.Path.Combine(PathManager.BaseDirectory, ".logs_root_migrated");
            if (!System.IO.File.Exists(sentinelPath)) return;

            string migratedFrom = null;
            try
            {
                string json = System.IO.File.ReadAllText(sentinelPath, System.Text.Encoding.UTF8);
                var dto = Services.JsonCompat.Deserialize<LogsRootMigratedSentinel>(json);
                if (dto != null) migratedFrom = dto.MigratedFrom;
            }
            catch (Exception ex)
            {
                Services.Logger.Warn("[MainForm] logs_root_migrated sentinel parse 失敗 (dialog 表示 skip): " + ex.Message);
            }
            finally
            {
                // 読込結果に関わらず sentinel は必ず削除する (永続 dialog 再表示バグ防止)。
                try { System.IO.File.Delete(sentinelPath); }
                catch (Exception delEx) { Services.Logger.Warn("[MainForm] logs_root_migrated sentinel 削除失敗: " + delEx.Message); }
            }

            if (string.IsNullOrEmpty(migratedFrom))
            {
                // parse 失敗 / migratedFrom 不在は dialog 出さず終了 (sentinel は finally で削除済)。
                return;
            }

            // (R4 review L-4) trailing backslash 正規化: FolderBrowserDialog の SelectedPath は末尾 `\` を
            // 含む慣習があり、dialog 本文構築時に `migratedFrom + "\\\n"` が `D:\logs\\` のような `\\` 混在
            // 表示になる cosmetic 問題を予防。Trim 後に再度 path 構築する。
            migratedFrom = migratedFrom.TrimEnd('\\', '/');

            Services.Logger.Info("[MainForm] logs_root_migrated dialog 表示: migratedFrom=" + migratedFrom);
            string body =
                "これまでのバージョンでは、Manager のログだけが指定したフォルダに保存されていました。\n" +
                "このバージョンから、Manager / Launcher / Updater など 全コンポーネントのログを\n" +
                "1 つのフォルダにまとめて保存できるようになりました。\n" +
                "\n" +
                "【設定の自動引き継ぎ】\n" +
                "これまでの設定値 (" + migratedFrom + ") はそのまま引き継がれましたが、\n" +
                "フォルダ構造が以下のように変わります:\n" +
                "\n" +
                "  " + migratedFrom + "\\\n" +
                "    ├ manager\\    ← Manager のログ\n" +
                "    ├ launcher\\   ← Launcher のログ (新規追加)\n" +
                "    └ updater\\    ← Updater のログ (新規追加)\n" +
                "\n" +
                "これまで " + migratedFrom + " 直下に保存されていた古い Manager ログはそのまま残ります\n" +
                "(不要であれば手動で削除してください)。\n" +
                "\n" +
                "※ Launcher / Updater の古いログは " + PathManager.BaseDirectory + "\\logs\\launcher\\ と\n" +
                "   " + PathManager.BaseDirectory + "\\logs\\updater\\ にあります (これまで Manager 設定とは\n" +
                "   別場所で管理されていたため)。\n" +
                "\n" +
                "設定タブの「ログ」セクションから保存先を変更できます。";
            // (#449) 起動シーケンス中なので不可視 MainForm を owner にしない。
            MessageBox.Show(
                VisibleModalOwner(),
                body,
                "ログの保存先の構造が変わりました",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }

        /// <summary>
        /// `<install>/.logs_root_migrated` sentinel ファイルの JSON deserialize 用 DTO (#201, v0.15.0)。
        /// writer 側は `Program.WriteLogsRootMigrationSentinel`、wire format は **真の camelCase**
        /// (`migratedFrom` / `migratedAt`)、`Services.JsonCompat.Deserialize` (System.Text.Json,
        /// case-insensitive) で PascalCase property と互換受理 (UpdateCompletedSentinel と同 pattern)。
        /// 注: 旧 R1 docstring で「camelCase」と称しつつ実態が snake_case (`migrated_from`) だった drift を
        /// R2 review Critical #1 で解消。System.Text.Json も JavaScriptSerializer 同様 underscore stripping を
        /// 行わないため、snake_case 採用は silent dialog 不発火を招く (camelCase 維持が必須)。
        /// </summary>
        private sealed class LogsRootMigratedSentinel
        {
            /// <summary>migration 前の旧 `log_destination_path` 値 (= dialog に embed して user に表示する)。</summary>
            public string MigratedFrom { get; set; }
            /// <summary>migration 実行時刻 (ISO 8601 UTC、現状は dialog 表示には使わず audit trail 用)。</summary>
            public string MigratedAt { get; set; }
        }

        /// <summary>
        /// `<install>/.update_completed` sentinel ファイルの JSON deserialize 用 DTO。
        ///
        /// **wire format 注意** (round 2 review fix Low-2): 本 class は PascalCase property を持ち、JSON
        /// wire format は camelCase (writer 側 `UpdateSectionPanel.RunUpdateWorker` の anonymous type が
        /// camelCase で書出し)。deserialize は `Services.JsonCompat.Deserialize<T>` 経由で **case-insensitive**
        /// (#258 で JavaScriptSerializer → System.Text.Json へ移行時、`PropertyNameCaseInsensitive=true` で旧挙動を
        /// 保存) のため camelCase wire ↔ PascalCase DTO 互換が継続する。wire 名を変える場合は要再検証。
        /// </summary>
        private sealed class UpdateCompletedSentinel
        {
            /// <summary>
            /// アップデート完了時刻 (ISO 8601 UTC、例: "2026-05-18T14:30:45Z")。consumer
            /// (`TryShowUpdateCompletedDialog`) が `DateTime.TryParse` で読み取り、`ToLocalTime` →
            /// "yyyy-MM-dd HH:mm" 形式に変換して dialog 文言の「完了時刻」行に embed する。parse 失敗時は
            /// 空文字 fallback で時刻行を省略 (= 時刻不在で dialog 自体を skip するより UX 良の判断)。
            /// `JavaScriptSerializer` の case-insensitive deserialize により JSON 上は `completedAt`
            /// (camelCase、wire format) でも `CompletedAt` (PascalCase) でも互換的に受理。
            /// </summary>
            public string CompletedAt { get; set; }
            /// <summary>
            /// (#440) 置換後に起動しているはずの Manager の FileVersion (例: "0.34.0.0")。
            /// 再起動した Manager が自分の assembly 版数と突き合わせて**本当に置換されたか**を確認する。
            /// 旧 sentinel には無いので null 可 — その場合は検証を skip して従来どおり完了 dialog を出す。
            /// </summary>
            public string NewManagerVersion { get; set; }
            /// <summary>
            /// 新 Bundle バージョン (例: "0.3.2")。**Bundle 全体の version** (= GitHub Releases tag) で、
            /// Manager 単体 version (例: "0.9.2") ではない (writer 側 `targetVersion.ToString(3)` が
            /// `_currentResult.Latest.Version` = Bundle Version 由来のため)。dialog 文言「Bundle バージョン: v...」
            /// に embed して user に表示する。
            /// </summary>
            public string NewVersion { get; set; }
        }
    }
}
