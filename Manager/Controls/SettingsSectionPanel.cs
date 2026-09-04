using System;
using System.Reflection;
using System.Windows.Forms;
using TonePrism.Manager.Services;

namespace TonePrism.Manager.Controls
{
    public partial class SettingsSectionPanel : UserControl
    {
        private DatabaseManager _dbManager;

        public event Action DatabaseReset;

        // (#170 followup round 1) Text 系 control の Leave event は focus 移動ごとに発火するため、
        // 値が前回 save 時から変更されていない場合は dirty mark を skip する (= no-op Leave で
        // 「未保存」マーカーが誤点灯するのを防ぐ)。これらの field は「最後に DB に書込んだ値」を tracking。
        private string _lastSavedLogsRoot = "";
        private string _lastSavedBackupDest = "";

        // (#201, v0.16.0) editing model = commit-on-Apply。control 変更は即 DB 保存せず本 dirty flag を
        // 立てるだけ、per-section「適用」ボタンで CheckBeforeWrite 1 回 + DB flush、「元に戻す」で
        // Load* 再読込。tab 切替 / フォーム終了時に dirty なら 3-button 確認 dialog (= MainForm が呼ぶ)。
        //
        // **dirty の意味 (R1 review Low-2)**: 「DB と差分あり」ではなく **「user が control を touch 済」**。
        // numeric / checkbox / combo は値を DB 値に戻しても dirty が解除されない (= ON→OFF→ON トグルで
        // 実効値が DB と一致しても dirty 維持)。TextBox 系のみ `_lastSaved*` 比較で no-op Leave を除外。
        // commit-on-Apply モデルでは「touched = 適用候補」として扱う一般的な許容挙動、baseline 値比較を
        // 全 control に足す cost を回避。「元に戻す」で確実に dirty clear できるので user は脱出可能。
        private bool _logSectionDirty;
        private bool _backupSectionDirty;

        public SettingsSectionPanel()
        {
            InitializeComponent();
        }

        // ----- dirty 制御 helper (#201) -----

        /// <summary>ログ section の dirty 状態を set + 未保存マーカー / 適用・元に戻すボタンの表示を同期。</summary>
        private void SetLogSectionDirty(bool dirty)
        {
            _logSectionDirty = dirty;
            lblLogUnsaved.Visible = dirty;
            btnLogApply.Enabled = dirty;
            btnLogRevert.Enabled = dirty;
        }

        /// <summary>バックアップ section の dirty 状態を set + 未保存マーカー / 適用・元に戻すボタンの表示を同期。</summary>
        private void SetBackupSectionDirty(bool dirty)
        {
            _backupSectionDirty = dirty;
            lblBackupUnsaved.Visible = dirty;
            btnBackupApply.Enabled = dirty;
            btnBackupRevert.Enabled = dirty;
        }

        // ----- 未保存解決 API (MainForm の tab 切替 / FormClosing から呼ぶ) -----

        /// <summary>いずれかの section に未保存変更があるか。</summary>
        public bool HasUnsavedChanges()
        {
            return _logSectionDirty || _backupSectionDirty;
        }

        /// <summary>
        /// 未保存変更がある場合に 3-button 確認 dialog (保存 / 破棄 / キャンセル) を出して解決する。
        /// 戻り値: true = 移動してよい (保存成功 or 破棄完了 or 未保存なし) / false = 留まる (キャンセル or 保存失敗)。
        /// 「保存」時に各 section の Apply を呼ぶため、その中で CheckBeforeWrite が走る (= LAN race fence)。
        /// </summary>
        public bool PromptAndResolveUnsavedChanges()
        {
            if (!HasUnsavedChanges()) return true;

            // (R3 review) 「保存 / 破棄」を button label に直接出す custom dialog
            // (= 標準 MessageBox は「はい/いいえ/キャンセル」固定で文言が冗長になるため)。
            DialogResult r;
            using (var dialog = new UnsavedSettingsDialog())
            {
                r = dialog.ShowDialog(this);
            }

            if (r == DialogResult.Yes)
            {
                // 保存: dirty な各 section を Apply。Apply 内の validate / CheckBeforeWrite が失敗 (= false)
                // したら留まる (= dirty 維持で編集継続)。
                if (_logSectionDirty && !ApplyLogSection()) return false;
                if (_backupSectionDirty && !ApplyBackupSection()) return false;
                return true;
            }
            if (r == DialogResult.No)
            {
                // 破棄: dirty な各 section を DB 値に Revert。
                if (_logSectionDirty) RevertLogSection();
                if (_backupSectionDirty) RevertBackupSection();
                return true;
            }
            // キャンセル: 留まる
            return false;
        }

        public void Initialize(DatabaseManager dbManager)
        {
            _dbManager = dbManager;
            UpdateVersionInfo();
            LoadLogSettings();
            LoadBackupSettings();
        }

        // ----- ログ section -----

        /// <summary>
        /// (#170 followup round 1) ログ section の初期化。保存先 path + 保存日数 を load。
        /// event hook は LoadLogSettings 完了後に attach (= 起動時 SetValue で spurious 発火回避)。
        /// </summary>
        private void LoadLogSettings()
        {
            if (_dbManager == null) return;
            // hook 一時 detach
            numLogRetention.ValueChanged -= NumLogRetention_ValueChanged;
            txtLogsRoot.Leave -= TxtLogsRoot_Leave;
            try
            {
                var repo = _dbManager.SettingsRepository;
                // (#170 followup round 2 review M-3) 初期値も trim して比較側 (newValue = Text.Trim()) と
                // 揃える。DB に末尾 whitespace が混入していた case で起動直後の focus 移動 1 回で
                // 「変更扱い」になり CheckBeforeWrite dialog が空発火する race を構造閉鎖。
                _lastSavedLogsRoot = (repo.GetString(SettingsKeys.LogsRootPath, "") ?? "").Trim();
                txtLogsRoot.Text = _lastSavedLogsRoot;

                int days = repo.GetInt32(SettingsKeys.LogRetentionDays, SettingsKeys.DefaultLogRetentionDays);
                if (days < numLogRetention.Minimum) days = (int)numLogRetention.Minimum;
                if (days > numLogRetention.Maximum) days = (int)numLogRetention.Maximum;
                numLogRetention.Value = days;
            }
            catch (Exception ex)
            {
                Logger.Warn("[SettingsSectionPanel] LoadLogSettings 読込失敗: " + ex.Message);
            }
            numLogRetention.ValueChanged += NumLogRetention_ValueChanged;
            txtLogsRoot.Leave += TxtLogsRoot_Leave;
            // (#201) load 完了時点では UI = DB なので未保存なし
            SetLogSectionDirty(false);
        }

        // (#201) control 変更は即 DB 保存せず dirty mark のみ。NumericUpDown の ValueChanged は実値変化時のみ発火。
        private void NumLogRetention_ValueChanged(object sender, EventArgs e)
        {
            SetLogSectionDirty(true);
        }

        private void btnLogBrowse_Click(object sender, EventArgs e)
        {
            using (var dialog = new FolderBrowserDialog())
            {
                dialog.Description = "ログ保存先フォルダを選択してください";
                if (!string.IsNullOrEmpty(txtLogsRoot.Text))
                {
                    // (R5 review Low-3) txtLogsRoot にゴミ値 (= 無効 path / 構文不正) が残っている state で
                    // SelectedPath set が ArgumentException を throw する path を防ぐ。失敗時は dialog を
                    // default location で開く (= 初期 path 指定を諦めるだけ、機能影響なし)。
                    try { dialog.SelectedPath = txtLogsRoot.Text; }
                    catch { /* 無効 path → 初期 path 指定なしで dialog 起動 */ }
                }
                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    txtLogsRoot.Text = dialog.SelectedPath;
                    SetLogSectionDirty(true);
                }
            }
        }

        // (#201) Leave は値が直前 save 値と異なる時だけ dirty mark (= no-op Leave で誤点灯しない)。
        private void TxtLogsRoot_Leave(object sender, EventArgs e)
        {
            string current = (txtLogsRoot.Text ?? string.Empty).Trim();
            if (current != _lastSavedLogsRoot) SetLogSectionDirty(true);
        }

        /// <summary>
        /// (#201) ログ section の「適用」: validate → CheckBeforeWrite → DB flush → launcher 伝搬 → dirty clear。
        /// 戻り値: true = 適用成功 / false = validate 失敗 or CheckBeforeWrite Cancel or DB 書込失敗 (= dirty 維持)。
        /// </summary>
        private bool ApplyLogSection()
        {
            if (_dbManager == null) return false;
            string newValue = (txtLogsRoot.Text ?? string.Empty).Trim();

            // (R5 review Low-4) 絶対 path 制約の enforce。空文字 (= default) 以外は絶対 path を要求。
            // 相対 path / traverse を許すと Manager Logger / Launcher が CWD 依存の予測不能 path に倒れる。
            if (!string.IsNullOrEmpty(newValue) && !System.IO.Path.IsPathRooted(newValue))
            {
                MessageBox.Show(this,
                    "ログ保存先は絶対パス (例: D:\\TonePrism_logs) で入力してください。\n" +
                    "空欄にするとデフォルト (DB ファイルの隣の logs/) を使用します。",
                    "入力エラー", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false; // dirty 維持
            }

            if (Services.SessionConflictHelper.CheckBeforeWrite(this, "ログ設定の適用") == DialogResult.Cancel)
            {
                return false; // dirty 維持 (= UI 値そのまま、編集継続)
            }
            try
            {
                var repo = _dbManager.SettingsRepository;
                repo.SetString(SettingsKeys.LogsRootPath, newValue);
                repo.SetInt32(SettingsKeys.LogRetentionDays, (int)numLogRetention.Value);
                _lastSavedLogsRoot = newValue;

                // (#201, v0.15.0) Launcher への path 伝搬: responses/launcher_logs_root.json を atomic write。
                Services.LauncherLogsRootBridge.WriteCurrentLogsRoot(newValue);

                Logger.Info("[SettingsSectionPanel] ログ設定を適用 (保存先=" + newValue + " / 保存日数="
                    + (int)numLogRetention.Value + " 日、Manager は次回 Manager 起動時、Launcher は次回 Launcher 起動時に反映)");
                SetLogSectionDirty(false);
                return true;
            }
            catch (Exception ex)
            {
                Logger.Warn("[SettingsSectionPanel] ログ設定の適用に失敗: " + ex.Message);
                MessageBox.Show("ログ設定の保存に失敗しました: " + ex.Message,
                    "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return false; // dirty 維持
            }
        }

        /// <summary>(#201) ログ section の「元に戻す」: DB 値を再読込 (= LoadLogSettings、末尾で dirty clear)。</summary>
        private void RevertLogSection()
        {
            LoadLogSettings();
        }

        private void btnLogApply_Click(object sender, EventArgs e)
        {
            ApplyLogSection();
        }

        private void btnLogRevert_Click(object sender, EventArgs e)
        {
            RevertLogSection();
        }

        // ----- バックアップ section -----

        /// <summary>
        /// (#170 followup) バックアップ section の初期化 + per-control event hook attach。
        /// 旧 BackupSettingsForm.LoadSettings の置換、3 値 + 単位 ComboBox の 4 制御を load。
        /// </summary>
        private void LoadBackupSettings()
        {
            if (_dbManager == null) return;
            // hook 一時 detach
            txtBackupDest.Leave -= TxtBackupDest_Leave;
            chkBackupAutoEnabled.CheckedChanged -= ChkBackupAutoEnabled_CheckedChanged;
            numBackupRetention.ValueChanged -= NumBackupRetention_ValueChanged;
            try
            {
                var repo = _dbManager.SettingsRepository;
                // (#170 followup round 2 review M-3) trim 揃え (上記 LogDest 同 pattern、空発火 dialog 防止)
                _lastSavedBackupDest = (repo.GetString("backup_destination_path", "") ?? "").Trim();
                txtBackupDest.Text = _lastSavedBackupDest;

                // (#170 followup round 2) 自動バックアップ有効/無効 checkbox の load
                string enabledStr = repo.GetString(SettingsKeys.BackupAutoEnabled, "true");
                chkBackupAutoEnabled.Checked = !string.Equals(enabledStr, "false", StringComparison.OrdinalIgnoreCase);

                int retention = repo.GetInt32("backup_retention_count", 30);
                if (retention < numBackupRetention.Minimum) retention = (int)numBackupRetention.Minimum;
                if (retention > numBackupRetention.Maximum) retention = (int)numBackupRetention.Maximum;
                numBackupRetention.Value = retention;
            }
            catch (Exception ex)
            {
                Logger.Warn("[SettingsSectionPanel] LoadBackupSettings 読込失敗: " + ex.Message);
            }
            txtBackupDest.Leave += TxtBackupDest_Leave;
            chkBackupAutoEnabled.CheckedChanged += ChkBackupAutoEnabled_CheckedChanged;
            numBackupRetention.ValueChanged += NumBackupRetention_ValueChanged;
            // (#201) load 完了時点では UI = DB なので未保存なし
            SetBackupSectionDirty(false);
        }

        // (#201 / #295) 自動バックアップ enable checkbox 変更: DB 保存は dirty mark のみ (Apply 時に flush)。
        // (#295) 旧: interval section の enable/disable を即時反映していたが、間隔 UI 撤去に伴い不要。
        private void ChkBackupAutoEnabled_CheckedChanged(object sender, EventArgs e)
        {
            SetBackupSectionDirty(true);
        }

        private void btnBackupBrowse_Click(object sender, EventArgs e)
        {
            using (var dialog = new FolderBrowserDialog())
            {
                dialog.Description = "バックアップ保存先フォルダを選択してください";
                if (!string.IsNullOrEmpty(txtBackupDest.Text))
                {
                    // (R5 review Low-3) ログ保存先側と同 pattern、無効 path で SelectedPath set が
                    // ArgumentException を throw する path を防ぐ。
                    try { dialog.SelectedPath = txtBackupDest.Text; }
                    catch { /* 無効 path → 初期 path 指定なしで dialog 起動 */ }
                }
                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    txtBackupDest.Text = dialog.SelectedPath;
                    SetBackupSectionDirty(true);
                }
            }
        }

        // (#201) Leave は値が直前 save 値と異なる時だけ dirty mark。
        private void TxtBackupDest_Leave(object sender, EventArgs e)
        {
            string current = (txtBackupDest.Text ?? string.Empty).Trim();
            if (current != _lastSavedBackupDest) SetBackupSectionDirty(true);
        }

        private void NumBackupRetention_ValueChanged(object sender, EventArgs e)
        {
            SetBackupSectionDirty(true);
        }

        /// <summary>
        /// (#201) バックアップ section の「適用」: CheckBeforeWrite → 3 key (保存先 / 自動有効 / 保持世代数) を
        /// DB flush → dirty clear。戻り値: true = 適用成功 / false = CheckBeforeWrite Cancel or DB 書込失敗 (= dirty 維持)。
        /// (#295) 起動時の時間トリガ廃止に伴い間隔 key (backup_auto_interval_hours / _unit) は撤去。
        /// </summary>
        private bool ApplyBackupSection()
        {
            if (_dbManager == null) return false;
            if (Services.SessionConflictHelper.CheckBeforeWrite(this, "バックアップ設定の適用") == DialogResult.Cancel)
            {
                return false; // dirty 維持
            }
            try
            {
                var repo = _dbManager.SettingsRepository;
                string destValue = (txtBackupDest.Text ?? string.Empty).Trim();
                repo.SetString("backup_destination_path", destValue);
                repo.SetString(SettingsKeys.BackupAutoEnabled, chkBackupAutoEnabled.Checked ? "true" : "false");
                repo.SetInt32("backup_retention_count", (int)numBackupRetention.Value);

                _lastSavedBackupDest = destValue;
                Logger.Info("[SettingsSectionPanel] バックアップ設定を適用 (保存先=" + destValue
                    + " / 自動=" + (chkBackupAutoEnabled.Checked ? "有効" : "無効")
                    + " / 世代数=" + (int)numBackupRetention.Value + " 個)");
                SetBackupSectionDirty(false);
                return true;
            }
            catch (Exception ex)
            {
                Logger.Warn("[SettingsSectionPanel] バックアップ設定の適用に失敗: " + ex.Message);
                MessageBox.Show("バックアップ設定の保存に失敗しました: " + ex.Message,
                    "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return false; // dirty 維持
            }
        }

        /// <summary>(#201) バックアップ section の「元に戻す」: DB 値を再読込 (= LoadBackupSettings、末尾で dirty clear)。</summary>
        private void RevertBackupSection()
        {
            LoadBackupSettings();
        }

        private void btnBackupApply_Click(object sender, EventArgs e)
        {
            ApplyBackupSection();
        }

        private void btnBackupRevert_Click(object sender, EventArgs e)
        {
            RevertBackupSection();
        }

        // ----- バージョン情報 + DB リセット -----

        public void UpdateVersionInfo()
        {
            if (_dbManager == null) return;

            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                AssemblyName assemblyName = assembly.GetName();
                Version version = assemblyName.Version;

                string productName = assembly.GetCustomAttribute<AssemblyProductAttribute>()?.Product ?? "TonePrism マネージャー";

                string versionStr = $"{version.Major}.{version.Minor}.{version.Build}";
                if (version.Revision > 0)
                    versionStr += $".{version.Revision}";

                int targetVersion = _dbManager.GetTargetDatabaseVersion();
                int actualVersion = _dbManager.GetActualDatabaseVersion();

                // AssemblyCopyright を SoT として Reflection 取得 (= AssemblyInfo.cs:13 が単一 SoT、
                // UI 側に literal を直書きしないので drift しない)。
                // 折返しは WinForms の word-wrap に委任 — `MaximumSize.Width` を grpInfo 幅基準で
                // 設定して `AutoSize=true` と組み合わせると、Label が幅で wrap + 高さ自動拡張する。
                // AssemblyInfo の文字列内容に対する coupling を持たないため、将来 holder 文字列を
                // 改変しても表示が壊れない (PR #194 round 2 review M-2 対応)。
                string copyright = assembly.GetCustomAttribute<AssemblyCopyrightAttribute>()?.Copyright ?? "";
                lblVersionInfo.MaximumSize = new System.Drawing.Size(grpInfo.ClientSize.Width - 40, 0);

                lblVersionInfo.Text =
                    $"製品名: {productName}\n" +
                    $"バージョン: {versionStr}\n" +
                    $"データベース構造: v{actualVersion} (ターゲット: v{targetVersion})\n" +
                    "\n" +
                    $"{copyright}\n" +
                    "ライセンス: MIT License";
            }
            catch (Exception ex)
            {
                // AGENTS.md Cross-component Standards: 新規 catch path は Logger 経由で WARN/ERROR を出力する。
                // 本 catch は version + copyright 両方の取得失敗を吸収するため、debug 容易化のため例外詳細を残す
                // (round 2 review L-4 対応)。Logger 自体の例外は Logger 内部で握り潰される (再帰ハング回避)。
                Logger.Warn("[SettingsSectionPanel] バージョン情報の取得に失敗: " + ex.Message);
                lblVersionInfo.Text = "バージョン情報の取得に失敗しました。";
            }
        }

        private void btnResetDatabase_Click(object sender, EventArgs e) => ResetDatabaseWithConfirm();

        // (#362 B2) WPF 設定ページの「リセット」ボタンからも呼べるよう本体を抽出 (旧 btnResetDatabase_Click)。
        // ダイアログ owner / 設定再読込先は本パネル (this) のまま (hidden MainForm 配下だがダイアログは前面に出る)。
        // 完了で DatabaseReset を発火し MainForm が各パネルを再読込する。WPF 設定ページ側は呼出後に自前で
        // LoadSettings して表示を default に同期する。
        /// <summary>
        /// (#449) モーダルの owner。SPEC §3.8.2.1 の規約に従い、可視の窓か <c>null</c> を返す。
        /// **`this` (= 本パネル) を渡してはいけない** — 設定は #362 で WPF ネイティブ化されたため
        /// 本パネルはシェルにホストされず、`Hide()` 済み MainForm の子のまま残っているので、
        /// WinForms は不可視 MainForm を owner にしてしまう。
        /// </summary>
        private System.Windows.Forms.IWin32Window ModalOwner()
        {
            var main = FindForm() as MainForm;
            return main != null ? main.VisibleModalOwnerOrNull() : null;
        }

        internal void ResetDatabaseWithConfirm()
        {
            // (#201 R2 review Low-2) DB リセットは completion 後に LoadLogSettings / LoadBackupSettings で
            // 設定 section を新 DB 値に再ロードするため、未保存編集があると無確認で破棄される。tab 切替 /
            // フォーム終了と同じ 3-button ガードを冒頭で通す (= リセット前に「保存 / 破棄 / キャンセル」)。
            // user「キャンセル」(= PromptAndResolve が false) ならリセット自体を中止。
            if (HasUnsavedChanges() && !PromptAndResolveUnsavedChanges()) return;

            // (round 5 M-1) 最 destructive (DB 全削除 + 再構築) なので **2 段階 check**:
            //   (1) ConfirmForm 開く前 = user 親切性 (= 他 PC 起動中なら confirm 開かず早期 abort)
            //   (2) ConfirmForm OK 後 + ProcessingDialog 起動前 = race fence (= confirm 読んでる間に
            //       他 PC が起動した case を catch)。confirm を user が長時間読む可能性があるので
            //       race window が無視できない、本 callsite のみ 2 段階。
            if (Services.SessionConflictHelper.CheckBeforeWrite(this, "データベース初期化") == DialogResult.Cancel) return;
            using (var confirmForm = new ResetDatabaseConfirmForm())
            {
                // (round 3 review L-1) owner=this 渡しで同 method 内の他 dialog (FolderDeletionFailureDialog /
                // MessageBox) と pattern 統一、taskbar separate entry + modal stack の不整合を防止。
                // (#449 レビュー H-2) **`this` を渡さない。** 設定は #362 で WPF ネイティブ化され、
                // 本パネルはシェルにホストされず `Hide()` 済み MainForm の子のまま残っている。
                // そのため `this` 渡しは不可視 MainForm を owner 連鎖の頂点にしてしまい、
                // (a) シェルが無効化されず**破壊的な DB 全削除の確認中にシェルを操作できる**擬似モーダル、
                // (b) owner がタスクバーに居ないので長い処理中に見失うと戻せない、の両方を踏む。
                if (confirmForm.ShowDialog(ModalOwner()) != DialogResult.Yes) return;
            }
            if (Services.SessionConflictHelper.CheckBeforeWrite(this, "データベース初期化") == DialogResult.Cancel) return;

            // ResetDatabase は DBファイル削除 + games フォルダ再構築 + テーブル再作成 +
            // マイグレーション再実行を行う。共有フォルダ越しでは時間がかかるので進捗バー表示。
            // 戻り値は退避フォルダ物理削除の Result。Success=false なら DB / games は再構築済みだが
            // 退避フォルダだけ残る状態なので、再試行 UI で対処する (#122 Group C)。
            // 真に失敗した場合は例外が ProcessingDialog 内でハンドリングされ DialogResult.Abort になる。
            Exception caught = null;
            FolderDeletionService.Result resetResult = null;
            using (var dialog = new ProcessingDialog((progress, token) =>
            {
                try
                {
                    progress?.Report(new ProgressInfo(-1, "データベースをリセット中...", "ファイル削除と再作成を実行しています"));
                    resetResult = _dbManager.ResetDatabase();
                }
                catch (Exception ex)
                {
                    caught = ex;
                    throw;
                }
            })
            {
                Text = "データベースリセット中",
                MarqueeMode = true,
                AllowCancel = false
            })
            {
                var dr = dialog.ShowDialog(ModalOwner());   // (#449 レビュー H-2)
                if (dr != DialogResult.OK)
                {
                    return;
                }
            }

            // ここまで来た = DB / games は再構築済み。UI リフレッシュは結果に関わらず実行する
            // (Codex P2 #121: 警告を例外で表現すると ProcessingDialog で Abort 扱いされて
            //  リフレッシュフックがスキップされ、UI が古いまま「失敗」と誤報告されていたため)
            UpdateVersionInfo();
            // (#201 R1 review Low-3) DB リセットで settings は全て default に戻るため、ログ / バックアップ
            // section も再ロードして UI を新 DB 値に同期 + dirty clear。commit-on-Apply モデルでは UI が
            // pending buffer なので、再ロードしないと stale 値表示 + (dirty 状態だった場合) 次回「適用」で
            // 新規 DB に stale pending を書込む path があった。LoadXxxSettings 末尾で SetXxxSectionDirty(false)。
            LoadLogSettings();
            LoadBackupSettings();
            DatabaseReset?.Invoke();

            // 退避フォルダ削除に失敗した場合は再試行 UI を出す (#122)
            // ユーザーが Launcher を閉じてから「再試行」を押せばロックが解放されて削除成功する想定
            while (resetResult != null && !resetResult.Success)
            {
                using (var failDialog = new FolderDeletionFailureDialog(resetResult.Path, resetResult.LastError))
                {
                    var dr = failDialog.ShowDialog(ModalOwner());   // (#449 レビュー H-2)
                    if (dr == DialogResult.Retry)
                    {
                        resetResult = FolderDeletionService.TryDelete(resetResult.Path);
                    }
                    else
                    {
                        // 諦めた場合は警告 MessageBox を出して終了 (退避フォルダはゴミとして残る)
                        MessageBox.Show(this,
                            "データベースのリセットは完了しましたが、退避済みの旧 games フォルダの削除を諦めました。\n" +
                            "後で手動削除してください:\n  " + resetResult.Path,
                            "警告", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        return;
                    }
                }
            }

            MessageBox.Show(this,
                "データベースのリセットが完了しました。",
                "成功", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }
}
