using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using TonePrism.Manager.Services;

namespace TonePrism.Manager.Shell
{
    /// <summary>
    /// (#362 step B1) 初の WPF ネイティブ画面。設定を「適用ボタン＋#201 ガード」から即時反映へ。
    /// 反映: トグル=即 / 数値=離脱時 / パス=離脱・参照選択時に <see cref="SettingsPathPolicy"/> で検証して反映。
    /// 書込先は <see cref="ShellWindow.SharedDb"/> の SettingsRepository (既存と同キー)。他 PC 競合チェックは
    /// MainForm 経由。B2 でバージョン情報 + DB リセットを追加予定。
    /// </summary>
    public partial class SettingsPage : Page
    {
        private static readonly Brush ErrorBrush = new SolidColorBrush(Color.FromRgb(0xE0, 0x6C, 0x5C));
        private static readonly Brush WarnBrush = new SolidColorBrush(Color.FromRgb(0xE0, 0x9F, 0x3E));

        private bool _loading;
        private DatabaseManager Db => ShellWindow.SharedDb;

        // (レビュー #6) 数値設定のデバウンス書込: スピナー連打を 1 回にまとめて SMB 越し DB 往復を減らす。
        // 同キーの直近値だけ保持し、500ms 静止 / 欄離脱 / ナビ離脱で 1 回 flush する (即時反映=保存ボタン無し
        // ・未保存状態なしは維持。デバウンス窓内の強制 kill だけが最後の 1 変更を失うが、設定編集中の kill は稀)。
        // (round4 #1) 競合チェックは flush 全体で 1 度 (固定 label) なので per-key label は不要 → key→value のみ保持。
        private readonly Dictionary<string, int> _pendingInts = new Dictionary<string, int>();
        private DispatcherTimer _intDebounce;

        // (レビュー #1) パスの直近保存値を追跡し、値が変化した時だけ書込＋セッション競合チェックを行う
        // (旧 SettingsSectionPanel の dirty 追跡相当)。no-op flush で SessionConflictDialog が誤発火するのを防ぐ
        // ＝複数 PC 共有で設定タブを開いて離れるだけで競合ダイアログが出る退行を回避。
        private readonly Dictionary<string, string> _lastSavedPaths = new Dictionary<string, string>();

        public SettingsPage()
        {
            InitializeComponent();

            // ホイール/二本指スクロール対策は ShellWindow 側で WM_MOUSEWHEEL を直接拾って処理する
            // (WinForms ループ上の WPF 窓 + NavigationView で WPF の wheel routing に届かないため)。
            Loaded += (_, _) => LoadSettings();

            // (#362 / レビュー #6) 数値は ValueChanged を「デバウンス」して反映 (spin 連打を 1 回の書込にまとめ
            // SMB 往復を減らす)。欄離脱 (LostFocus) / ナビ離脱 (Unloaded) で即 flush するので未保存状態は残らない。
            LogRetentionBox.ValueChanged += (s, e) =>
            {
                if (!_loading) QueueInt(SettingsKeys.LogRetentionDays, (int)Math.Round(LogRetentionBox.Value ?? 0));
            };
            BackupRetentionBox.ValueChanged += (s, e) =>
            {
                if (!_loading) QueueInt("backup_retention_count", (int)Math.Round(BackupRetentionBox.Value ?? 0));
            };
            // (#362) ナビ離脱時に未フラッシュの数値 + パスの未コミット直接入力を確実に書く保険 (prompt は出さない)。
            Unloaded += (_, _) => { FlushPendingInts(); FlushPaths(); };
        }

        private void LoadSettings()
        {
            if (Db == null) return;
            _loading = true;
            try
            {
                var repo = Db.SettingsRepository;
                LogPathBox.Text = (repo.GetString(SettingsKeys.LogsRootPath, "") ?? "").Trim();
                LogRetentionBox.Value = Clamp(repo.GetInt32(SettingsKeys.LogRetentionDays, SettingsKeys.DefaultLogRetentionDays), 1, 3650);
                BackupPathBox.Text = (repo.GetString("backup_destination_path", "") ?? "").Trim();
                // 解釈は SettingsValueFormat に集約（旧実装の「"false" 以外はすべて ON」は "0" を ON と
                // 読むため、Launcher の get_bool と食い違う。今は Launcher がこの key を読まないので実害は
                // 無いが、同じファイル内に 2 通りの解釈を残さない / レビュー M-4）。
                BackupAutoToggle.IsChecked = SettingsValueFormat.ParseBool(repo.GetString(SettingsKeys.BackupAutoEnabled, "true"), true);
                BackupRetentionBox.Value = Clamp(repo.GetInt32("backup_retention_count", 30), 1, 999);
                // (#35) アンケートのトグル。既定は ON = 新規インストールで何もしなくても収集が始まる
                // (文化祭は 1 日勝負で、設定し忘れて 1 件も取れない方が損失が大きいため)。
                SurveyGameEndToggle.IsChecked = SettingsValueFormat.ParseBool(repo.GetString(SettingsKeys.SurveyGameEndEnabled, "true"), true);
                SurveyLauncherEndToggle.IsChecked = SettingsValueFormat.ParseBool(repo.GetString(SettingsKeys.SurveyLauncherEndEnabled, "true"), true);
                // (レビュー #1) パスの直近保存値を記録 (以後この値と異なる時だけ書込/競合チェック)。
                _lastSavedPaths[SettingsKeys.LogsRootPath] = LogPathBox.Text;
                _lastSavedPaths["backup_destination_path"] = BackupPathBox.Text;
                LoadVersionInfo();
            }
            catch (Exception ex) { Logger.Warn("[SettingsPage] 設定読込失敗: " + ex.Message); }
            finally { _loading = false; }
        }

        private static int Clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

        // 他 PC 競合チェック (MainForm 経由)。Cancel なら false = 書込中止。host 不在は OK 扱い。
        private bool AllowWrite(string label)
        {
            var host = ShellWindow.HostForm;
            return host == null || host.CheckSessionConflictBeforeWrite(label) != System.Windows.Forms.DialogResult.Cancel;
        }

        // ---- ログ ----
        private void LogPath_LostFocus(object sender, RoutedEventArgs e)
            => ApplyPath(LogPathBox, LogPathMsg, SettingsKeys.LogsRootPath, "ログ設定の適用", isLog: true);

        private void LogBrowse_Click(object sender, RoutedEventArgs e)
        {
            if (Browse(LogPathBox)) ApplyPath(LogPathBox, LogPathMsg, SettingsKeys.LogsRootPath, "ログ設定の適用", isLog: true);
        }

        // (レビュー #6/#7) 欄離脱時は保留中の数値を即 flush (デバウンス満了を待たない)。旧 ValueChanged+LostFocus
        // 二重書込も解消 (LostFocus は flush 専任に)。
        private void LogRetention_LostFocus(object sender, RoutedEventArgs e) => FlushPendingInts();

        // ---- バックアップ ----
        private void BackupPath_LostFocus(object sender, RoutedEventArgs e)
            => ApplyPath(BackupPathBox, BackupPathMsg, "backup_destination_path", "バックアップ設定の適用", isLog: false);

        private void BackupBrowse_Click(object sender, RoutedEventArgs e)
        {
            if (Browse(BackupPathBox)) ApplyPath(BackupPathBox, BackupPathMsg, "backup_destination_path", "バックアップ設定の適用", isLog: false);
        }

        private void BackupAuto_Changed(object sender, RoutedEventArgs e)
        {
            if (_loading || Db == null) return;
            if (!AllowWrite("バックアップ設定の適用")) return;
            try { Db.SettingsRepository.SetString(SettingsKeys.BackupAutoEnabled, SettingsValueFormat.FormatBool(BackupAutoToggle.IsChecked == true)); }
            catch (Exception ex) { Logger.Warn("[SettingsPage] 自動バックアップ保存失敗: " + ex.Message); }
        }

        private void BackupRetention_LostFocus(object sender, RoutedEventArgs e) => FlushPendingInts();

        // ---- アンケート (#35) ----
        // 稼働中の Launcher が表示直前に毎回読むため、ここで書いた瞬間に全キオスクへ効く (再起動不要)。
        // 自動バックアップのトグルと同じ即時保存パターン。
        private void SurveyGameEnd_Changed(object sender, RoutedEventArgs e)
            => SaveSurveyToggle(SettingsKeys.SurveyGameEndEnabled, SurveyGameEndToggle.IsChecked == true, "ゲーム終了時のアンケート");

        private void SurveyLauncherEnd_Changed(object sender, RoutedEventArgs e)
            => SaveSurveyToggle(SettingsKeys.SurveyLauncherEndEnabled, SurveyLauncherEndToggle.IsChecked == true, "退出時のアンケート");

        private void SaveSurveyToggle(string key, bool enabled, string label)
        {
            if (_loading || Db == null) return;
            if (!AllowWrite("アンケート設定の適用")) return;
            try
            {
                Db.SettingsRepository.SetString(key, SettingsValueFormat.FormatBool(enabled));
                Logger.Info("[SettingsPage] " + label + " を " + (enabled ? "表示する" : "表示しない") + " に変更しました");
            }
            catch (Exception ex) { Logger.Warn("[SettingsPage] " + label + " の保存失敗: " + ex.Message); }
        }

        // ---- 共通 ----
        private bool Browse(Wpf.Ui.Controls.TextBox box)
        {
            using (var dialog = new System.Windows.Forms.FolderBrowserDialog())
            {
                dialog.Description = "フォルダを選択してください";
                if (!string.IsNullOrWhiteSpace(box.Text))
                {
                    try { dialog.SelectedPath = box.Text.Trim(); } catch { /* 無効 path は初期位置で開く */ }
                }
                if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                {
                    box.Text = dialog.SelectedPath;
                    return true;
                }
            }
            return false;
        }

        // (レビュー #6) 数値書込をデバウンス。同キーの直近値だけ保持し、500ms 静止後に flush で一括書込する。
        private void QueueInt(string key, int value)
        {
            _pendingInts[key] = value;
            if (_intDebounce == null)
            {
                _intDebounce = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(500) };
                _intDebounce.Tick += (s, e) => FlushPendingInts();
            }
            _intDebounce.Stop();
            _intDebounce.Start();
        }

        // 保留中の数値書込を即時 flush する (デバウンス満了 / 欄離脱 / ナビ離脱)。
        // (レビュー #6) セッション競合チェックは **数値 flush 全体で 1 度だけ** (両 retention を同時に変更して離脱しても
        // SessionConflictDialog が 2 連続で出ないように集約)。(round5 Finding 3) ただしこれは数値 flush 限定。Unloaded では
        // 別途 FlushPaths が各パスを (_lastSavedPaths ガードで変更時のみ) チェックするため、数値+両パスを同時編集して競合下で
        // 離脱する稀ケースは最大 3 ダイアログになりうる (各々が実変更に対応・spurious ではないので許容)。
        // (round4 #2) 数値は実変更時のみ queue されるので no-op flush は基本無い (例外: 同一操作で保存値へ revert した時
        // だけ最終値=保存値で flush される)。パスのような last-saved ガードは付けない＝flush トリガが ValueChanged 限定で
        // 頻度が低く、競合 × revert の二重稀ケースに限るため。
        private void FlushPendingInts()
        {
            _intDebounce?.Stop();
            if (_pendingInts.Count == 0 || _loading || Db == null) { _pendingInts.Clear(); return; }
            var snapshot = new List<KeyValuePair<string, int>>(_pendingInts);
            _pendingInts.Clear();
            if (!AllowWrite("設定の適用")) return;
            foreach (var kv in snapshot)
            {
                try { Db.SettingsRepository.SetInt32(kv.Key, kv.Value); }
                catch (Exception ex) { Logger.Warn("[SettingsPage] 数値設定保存失敗 (" + kv.Key + "): " + ex.Message); }
            }
        }

        // (#362) ナビ離脱時にパスの直接入力を prompt なしで反映する保険。MissingLocal は prompt 不可のため skip。
        private void FlushPaths()
        {
            ApplyPath(LogPathBox, LogPathMsg, SettingsKeys.LogsRootPath, "ログ設定の適用", isLog: true, allowPrompt: false);
            ApplyPath(BackupPathBox, BackupPathMsg, "backup_destination_path", "バックアップ設定の適用", isLog: false, allowPrompt: false);
        }

        private void ApplyPath(Wpf.Ui.Controls.TextBox box, TextBlock msg, string key, string label, bool isLog, bool allowPrompt = true)
        {
            if (_loading || Db == null) return;
            string val = (box.Text ?? "").Trim();
            HideMsg(msg);

            switch (SettingsPathPolicy.Classify(val, Directory.Exists))
            {
                case SettingsPathKind.Empty:
                case SettingsPathKind.Ok:
                    break; // そのまま反映
                case SettingsPathKind.Relative:
                case SettingsPathKind.Invalid:
                    ShowMsg(msg, "絶対パスを入力してください (例: D:\\TonePrism_logs)。空欄でデフォルト。", ErrorBrush);
                    return; // 反映しない
                case SettingsPathKind.MissingLocal:
                    if (!allowPrompt) return; // flush (ナビ離脱) 時は prompt できないので適用しない
                    var r = MessageBox.Show($"フォルダ「{val}」は存在しません。作成しますか？",
                        "フォルダの作成", MessageBoxButton.YesNo, MessageBoxImage.Question);
                    if (r != MessageBoxResult.Yes) return; // 作らない → 反映しない
                    try { Directory.CreateDirectory(val); }
                    catch (Exception ex) { ShowMsg(msg, "フォルダを作成できませんでした: " + ex.Message, ErrorBrush); return; }
                    break;
                case SettingsPathKind.Unreachable:
                    if (isLog)
                    {
                        // (レビュー #4) ログ保存先が到達不能だと Logger が書けず静かにログを失う。バックアップ先と違い
                        // 「後で書く」が無いので保存しない (到達可能なパスを促す)。Unreachable 緩和は BU 先専用。
                        ShowMsg(msg, "現在アクセスできません。ログ保存先には到達可能なパスを指定してください。", ErrorBrush);
                        return;
                    }
                    ShowMsg(msg, "現在アクセスできません (設定は保存します)。", WarnBrush);
                    break; // 反映は通す (バックアップ先は共有サーバの一時ダウンを許容)
            }

            // (レビュー #1) 値が直近保存値と同じなら書込もセッション競合チェックもしない (no-op flush 抑止)。
            if (_lastSavedPaths.TryGetValue(key, out string prevSaved) && string.Equals(prevSaved, val, StringComparison.Ordinal))
                return;

            if (!AllowWrite(label)) return;
            try
            {
                Db.SettingsRepository.SetString(key, val);
                if (isLog) LauncherLogsRootBridge.WriteCurrentLogsRoot(val);
                _lastSavedPaths[key] = val; // 保存成功 → 直近値を更新
                Logger.Info("[SettingsPage] " + label + ": " + (val.Length == 0 ? "(デフォルト)" : val));
            }
            catch (Exception ex) { ShowMsg(msg, "保存に失敗しました: " + ex.Message, ErrorBrush); }
        }

        private void ShowMsg(TextBlock msg, string text, Brush brush)
        {
            msg.Text = text;
            msg.Foreground = brush;
            msg.Visibility = Visibility.Visible;
        }

        private void HideMsg(TextBlock msg) => msg.Visibility = Visibility.Collapsed;

        // ---- (B2) バージョン情報 / DB リセット ----
        private void LoadVersionInfo()
        {
            try
            {
                var asm = Assembly.GetExecutingAssembly();
                Version v = asm.GetName().Version;
                string product = asm.GetCustomAttribute<AssemblyProductAttribute>()?.Product ?? "TonePrism マネージャー";
                string ver = v == null ? "?" : (v.Major + "." + v.Minor + "." + v.Build + (v.Revision > 0 ? "." + v.Revision : ""));
                string copyright = asm.GetCustomAttribute<AssemblyCopyrightAttribute>()?.Copyright ?? "";
                int actual = Db?.GetActualDatabaseVersion() ?? -1;
                int target = Db?.GetTargetDatabaseVersion() ?? -1;
                VersionInfoText.Text =
                    "製品名: " + product + "\n" +
                    "バージョン: " + ver + "\n" +
                    "データベース構造: v" + actual + " (ターゲット: v" + target + ")\n" +
                    copyright + "\n" +
                    "ライセンス: MIT License";
            }
            catch (Exception ex)
            {
                VersionInfoText.Text = "バージョン情報の取得に失敗しました。";
                Logger.Warn("[SettingsPage] バージョン情報取得失敗: " + ex.Message);
            }
        }

        private void ResetDb_Click(object sender, RoutedEventArgs e)
        {
            // DB リセット本体は既存 WinForms SettingsSectionPanel に集約 (確認/進捗ダイアログ + ResetDatabase +
            // DatabaseReset イベントで MainForm が各パネルを再読込)。WPF 側は呼出後に設定表示を default へ同期。
            var panel = ShellWindow.HostForm?.SettingsSectionPanel;
            if (panel == null) return;
            panel.ResetDatabaseWithConfirm();
            LoadSettings();
        }
    }
}
