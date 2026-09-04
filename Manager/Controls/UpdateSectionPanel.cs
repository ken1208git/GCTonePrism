using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;

namespace TonePrism.Manager.Controls
{
    /// <summary>
    /// 「アップデート」タブの UI 本体。Phase 4 (#108)。
    ///
    /// 責務:
    ///   - 5 + 1 component version の表示 (Bundle / Manager / Launcher / Updater / DB schema、+ 最新 Bundle)
    ///   - GitHub Releases API 経由でのバージョン check (UpdateChecker 経由、cache + skip 対応)
    ///   - リリースノートの WebBrowser + Markdig 表示
    ///   - 「今すぐアップデート」フロー (SPEC §3.7.3 [4]〜[11]) のトリガー
    ///
    /// 既存 SectionPanel pattern と同じく `Initialize(dbManager)` で DB 注入、`StatusChanged` event なし
    /// (アップデート操作中の status は ProcessingDialog の中で完結する)。
    /// </summary>
    public partial class UpdateSectionPanel : UserControl
    {
        private DatabaseManager _dbManager;
        private UpdateChecker _updateChecker;
        private UpdateCheckResult _currentResult;
        private CancellationTokenSource _checkCts;

        public UpdateSectionPanel()
        {
            InitializeComponent();
        }

        public void Initialize(DatabaseManager dbManager)
        {
            _dbManager = dbManager;
            _updateChecker = new UpdateChecker(dbManager.SettingsRepository);

            // 起動時 hydrate (cache から「前回確認時の状態」を即時表示)
            RefreshVersionLabels();
            UpdateCheckResult cached = _updateChecker.LoadCacheOnly();
            ApplyResult(cached);

            // 「前回アップデート結果」バナーがあれば表示
            int? lastExit = UpdaterClient.TryLoadLastExitCode();
            if (lastExit.HasValue)
            {
                ShowPreviousUpdateBanner(lastExit.Value);
            }
        }

        /// <summary>MainForm の background check (StartBackgroundUpdateCheckIfDue) から完了通知。UI thread に marshal。</summary>
        internal void OnCheckCompleted(UpdateCheckResult result)
        {
            if (InvokeRequired)
            {
                try
                {
                    BeginInvoke(new Action<UpdateCheckResult>(OnCheckCompleted), result);
                }
                // (#108 Phase 4 round 4 M-3) form 破棄経路の cosmetic 例外は両方握り潰す。
                // `ObjectDisposedException : InvalidOperationException` の派生関係のため `catch
                // (InvalidOperationException)` 単独で両方拾えるが、reviewer に「ObjectDisposedException
                // も明示的に意図している」を伝えるため specific (= ObjectDisposedException) を先に置く。
                catch (ObjectDisposedException) { /* form 完全 Dispose 済 */ }
                catch (InvalidOperationException) { /* form 破棄経路 */ }
                return;
            }
            ApplyResult(result);
        }

        private void RefreshVersionLabels()
        {
            int dbSchema = 0;
            try { dbSchema = _dbManager.GetTargetDatabaseVersion(); } catch { dbSchema = 0; }
            InventorySnapshot snap = VersionInventory.Snapshot(dbSchema > 0 ? (int?)dbSchema : null);
            lblBundleVersion.Text = FormatVersion(snap.Bundle);
            lblManagerVersion.Text = FormatVersion(snap.Manager);
            lblLauncherVersion.Text = FormatVersion(snap.Launcher);
            lblUpdaterVersion.Text = FormatVersion(snap.Updater);
            lblDbSchemaVersion.Text = snap.DbSchema.HasValue ? "v" + snap.DbSchema.Value : "不明";
        }

        private static string FormatVersion(Version v)
        {
            return v == null ? "不明" : "v" + v.ToString(3);
        }

        private void ApplyResult(UpdateCheckResult result)
        {
            _currentResult = result;
            if (result == null)
            {
                lblLatestVersion.Text = "未確認";
                lblLatestDate.Text = string.Empty;
                lblStatusMessage.Text = string.Empty;
                btnUpdateNow.Enabled = false;
                btnSkip.Enabled = false;
                webReleaseNotes.DocumentText = MarkdownRenderer.WrapAsDocument("<p>「更新を確認」を押してください。</p>");
                return;
            }

            // 最新 ver / 日付
            // (#170 followup) cache fallback (FromCache=true + LastError あり) の場合、表示している
            // version は **再確認できていない古い値の可能性** があるため「(キャッシュ)」suffix +
            // 灰色化で disclaimer を視覚化。再確認成功時 (FromCache=true でも LastError=null) は
            // disclaimer 不要 (= cache TTL 内の正常 hit、信頼可)。
            bool isStaleCache = result.FromCache && !string.IsNullOrEmpty(result.LastError);
            if (result.Latest != null)
            {
                lblLatestVersion.Text = (result.Latest.TagName ?? "不明") + (isStaleCache ? " (キャッシュ)" : string.Empty);
                lblLatestVersion.ForeColor = isStaleCache ? System.Drawing.Color.Gray : System.Drawing.SystemColors.ControlText;
                lblLatestDate.Text = result.Latest.PublishedAt.HasValue
                    ? "(公開: " + result.Latest.PublishedAt.Value.ToLocalTime().ToString("yyyy-MM-dd") + ")"
                    : string.Empty;
            }
            else
            {
                lblLatestVersion.Text = result.Status == UpdateCheckStatus.UnknownBundle ? "(Bundle 不明)" : "—";
                lblLatestVersion.ForeColor = System.Drawing.SystemColors.ControlText;
                lblLatestDate.Text = string.Empty;
            }

            // status メッセージ + button 有効化
            //
            // cache fallback (FromCache=true + LastError あり) の場合は、Status は cache の元 Status
            // (UpToDate/Available/Skipped/UnknownBundle) を保持しているのでそのまま主メッセージに使い、
            // LastError は別行で grey の sub-text として軽く注記 (= データが見えてるのに「失敗」赤字で
            // alarming にしない設計、UpdateChecker.cs の fallback path 参照)。
            switch (result.Status)
            {
                case UpdateCheckStatus.Initializing:
                    // (#173) cache 不在 + background check 未完了の遷移状態。「最新版を実行中」緑文字 default
                    // 誤表示を避けるため Initializing 灰色で「未確認」を視覚化、API 完了で上書きされる短命状態。
                    lblStatusMessage.Text = "最新版を確認中...";
                    lblStatusMessage.ForeColor = System.Drawing.Color.Gray;
                    btnUpdateNow.Enabled = false;
                    btnSkip.Enabled = false;
                    break;
                case UpdateCheckStatus.UpToDate:
                    // (#170 followup) cache 経由判定の場合、実 GitHub 最新と比較できていないため
                    // 緑文字「最新版を実行中」と断言すると過信させすぎ。stale cache 時は灰色 + 文言
                    // を「キャッシュ比較、再確認失敗中」に降格して信頼度を視覚化。
                    if (isStaleCache)
                    {
                        lblStatusMessage.Text = "最新版を実行中 (キャッシュ比較、再確認失敗中)";
                        lblStatusMessage.ForeColor = System.Drawing.Color.DimGray;
                    }
                    else
                    {
                        lblStatusMessage.Text = "最新版を実行中です。";
                        lblStatusMessage.ForeColor = System.Drawing.Color.DarkGreen;
                    }
                    btnUpdateNow.Enabled = false;
                    btnSkip.Enabled = false;
                    break;
                case UpdateCheckStatus.UpdateAvailable:
                    lblStatusMessage.Text = "新しいバージョンが利用可能です。";
                    lblStatusMessage.ForeColor = System.Drawing.Color.DarkOrange;
                    btnUpdateNow.Enabled = true;
                    btnSkip.Enabled = true;
                    break;
                case UpdateCheckStatus.Skipped:
                    lblStatusMessage.Text = "このバージョンはスキップ済みです。";
                    lblStatusMessage.ForeColor = System.Drawing.Color.Gray;
                    btnUpdateNow.Enabled = true;
                    btnSkip.Enabled = false;
                    break;
                case UpdateCheckStatus.NetworkError:
                    // cache 無しで API 失敗 → 赤字エラー (データが見えていない alarming 状態)
                    lblStatusMessage.Text = "ネットワーク確認に失敗: " + (result.LastError ?? "");
                    lblStatusMessage.ForeColor = System.Drawing.Color.DarkRed;
                    btnUpdateNow.Enabled = false;
                    btnSkip.Enabled = false;
                    break;
                case UpdateCheckStatus.ParseError:
                    lblStatusMessage.Text = "API 応答の解析失敗: " + (result.LastError ?? "");
                    lblStatusMessage.ForeColor = System.Drawing.Color.DarkRed;
                    btnUpdateNow.Enabled = false;
                    btnSkip.Enabled = false;
                    break;
                case UpdateCheckStatus.UnknownBundle:
                    lblStatusMessage.Text = "現在の Bundle バージョンを判定できません (CHANGELOG.md 不在)。開発環境では正常な表示です。本番環境でこの表示が出る場合は Install.bat で再 install してください。";
                    lblStatusMessage.ForeColor = System.Drawing.Color.Gray;
                    btnUpdateNow.Enabled = false;
                    btnSkip.Enabled = false;
                    break;
            }

            // cache 表示中 + 再確認 API 失敗の sub-text 注記 (grey、alarming を下げる)
            //   Status が NetworkError/ParseError 以外 (= cache に意味あるデータがある場合) かつ
            //   LastError が乗っているケース。cache の元データを main message でそのまま表示し、
            //   sub-text で「再確認はエラー」を grey で軽く伝える。
            if (result.FromCache && !string.IsNullOrEmpty(result.LastError)
                && result.Status != UpdateCheckStatus.NetworkError
                && result.Status != UpdateCheckStatus.ParseError)
            {
                string elapsed = FormatElapsedSince(result.CheckedAtUnixMs);
                string subText = "(最終確認: " + elapsed + " 前、再確認エラー: " + result.LastError + ")";
                lblStatusMessage.Text = lblStatusMessage.Text + "\n" + subText;
            }

            // リリースノート表示の使い分け (#108 Phase 4):
            //   UpdateAvailable / Skipped (= current < latest、累積データあり)
            //       → 「これから適用される変更」ヘッダ + 累積 release notes (v0.3.0 → v0.4.0 → ...)
            //   UpToDate (= current == latest、累積データなし)
            //       → 「現在実行中: vX.Y.Z の内容」ヘッダ + latest 1 個 (= 今動いてる version の振り返り)
            //   データなし → 「リリースノートはありません」
            // アップデート完了後は current == latest になるため自然と UpToDate 表示に切り替わる
            // (ユーザーが期待した「アプデできたら最新版だけ表示」semantic)。
            try
            {
                // (#170 followup) 「これから適用される変更」見出しは UpdateAvailable / Skipped
                // (= current < latest、実際に未適用 release がある状態) でのみ意味を持つ。
                // UpToDate / UnknownBundle / NetworkError / ParseError のときに CumulativeReleases が
                // 残っていても (= cache stale 由来で UpdateChecker filter を通り抜けたケース) UI 側
                // で表示しない fallback。defense-in-depth として UpdateChecker の
                // FilterStaleFromCumulative と組み合わせ、片方が漏れても誤情報を user に出さない。
                bool showCumulative = result.CumulativeReleases != null
                    && result.CumulativeReleases.Count > 0
                    && (result.Status == UpdateCheckStatus.UpdateAvailable
                        || result.Status == UpdateCheckStatus.Skipped);
                if (showCumulative)
                {
                    // (#108 Phase 4 round 2 L12) cache hydrate 経路で CumulativeReleases=空 (size 抑制の
                    // ため cache に入れない設計) のケースは、次行の BuildCumulativeHtml が単一 Latest
                    // を fallback 表示するため UI semantics 上「最新 1 個のみ」になる short window あり。
                    // OnCheckCompleted で fresh API fetch 結果が来たら自動上書きされる。 perceivable な
                    // flash の対処は将来「累積データ取得中..." placeholder を出すこと検討。
                    webReleaseNotes.DocumentText = MarkdownRenderer.BuildCumulativeHtml(
                        result.CumulativeReleases, topHeading: "これから適用される変更");
                }
                else
                {
                    // (#170 followup round 2) 「現在実行中」notes は **local CHANGELOG.md を優先** する。
                    // 旧実装は cache.Latest.Body を直接使っていたが、cache が stale (= current > cache.Latest)
                    // のケースで「現在実行中: v0.4.0」+ v0.4.0 body を表示する誤誘導があった (user は実際は
                    // v0.5.0 を実行中で、v0.4.0 の内容は既に適用済)。local CHANGELOG.md は bundle 同梱
                    // (Release Tooling v0.1.16 以降) で、必ず current Bundle 版の notes を持つため SoT として
                    // 信頼可。fallback chain: 1) local CHANGELOG → 2) cache.Latest.Body → 3) "ありません"。
                    string localBody = null;
                    string localHeading = null;
                    try
                    {
                        BundleEntry localBundle = ChangelogParser.TryReadLatestFromFile(PathManager.BundleChangelogPath);
                        if (localBundle != null && !string.IsNullOrEmpty(localBundle.Body))
                        {
                            localBody = localBundle.Body;
                            string verStr = localBundle.Version != null
                                ? "v" + localBundle.Version.ToString(3)
                                : localBundle.RawVersionString ?? "";
                            localHeading = "現在実行中: " + verStr;
                        }
                    }
                    catch (Exception localEx)
                    {
                        Logger.Warn("[UpdateSectionPanel] local CHANGELOG.md 読込失敗 (cache fallback に降格): " + localEx.Message);
                    }

                    if (!string.IsNullOrEmpty(localBody))
                    {
                        string bodyHtml = MarkdownRenderer.MarkdownToHtml(localBody);
                        webReleaseNotes.DocumentText = MarkdownRenderer.WrapAsDocument(
                            "<h1>" + System.Net.WebUtility.HtmlEncode(localHeading) + "</h1>" + bodyHtml);
                    }
                    else if (result.Latest != null && !string.IsNullOrEmpty(result.Latest.Body))
                    {
                        string bodyHtml = MarkdownRenderer.MarkdownToHtml(result.Latest.Body);
                        string heading = "現在実行中: " + (result.Latest.TagName ?? "");
                        webReleaseNotes.DocumentText = MarkdownRenderer.WrapAsDocument(
                            "<h1>" + System.Net.WebUtility.HtmlEncode(heading) + "</h1>" + bodyHtml);
                    }
                    else
                    {
                        webReleaseNotes.DocumentText = MarkdownRenderer.WrapAsDocument("<p>リリースノートはありません。</p>");
                    }
                }
            }
            catch
            {
                webReleaseNotes.DocumentText = MarkdownRenderer.WrapAsDocument("<p>リリースノートの表示に失敗しました。</p>");
            }
        }

        /// <summary>cache の `CheckedAtUnixMs` から経過時間を「3 分」「5 時間」等の人間可読な短文に。</summary>
        private static string FormatElapsedSince(long unixMs)
        {
            if (unixMs <= 0L) return "不明";
            long nowMs = System.DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            long elapsedMs = nowMs - unixMs;
            if (elapsedMs < 0L) return "不明";
            long sec = elapsedMs / 1000L;
            if (sec < 60) return sec + " 秒";
            long min = sec / 60L;
            if (min < 60) return min + " 分";
            long hour = min / 60L;
            if (hour < 24) return hour + " 時間";
            long day = hour / 24L;
            return day + " 日";
        }

        private void ShowPreviousUpdateBanner(int exitCode)
        {
            ExitCodeDispatch dispatch = UpdaterClient.DispatchExitCode(exitCode);
            if (dispatch.Severity == ExitSeverity.Success)
            {
                lblPreviousResult.Text = "前回のアップデートに成功しました。";
                lblPreviousResult.ForeColor = System.Drawing.Color.DarkGreen;
            }
            else
            {
                lblPreviousResult.Text = "前回のアップデート結果: " + dispatch.Title;
                lblPreviousResult.ForeColor = System.Drawing.Color.DarkRed;
            }
            lblPreviousResult.Visible = true;
        }

        // ----- button handlers -----

        private async void btnCheckNow_Click(object sender, EventArgs e)
        {
            if (_updateChecker == null) return;
            btnCheckNow.Enabled = false;
            try
            {
                // (#108 Phase 4 round 1 L4 fix) 旧 CancellationTokenSource を Dispose してから新規生成。
                // 旧実装は Cancel のみで Dispose 漏れ、CancellationTokenSource は内部 WaitHandle を持つ
                // IDisposable のため連打で累積する。
                if (_checkCts != null)
                {
                    _checkCts.Cancel();
                    _checkCts.Dispose();
                }
                _checkCts = new CancellationTokenSource();
                lblStatusMessage.Text = "確認中...";
                lblStatusMessage.ForeColor = System.Drawing.Color.Black;
                UpdateCheckResult result = await _updateChecker.ForceRefreshAsync(_checkCts.Token).ConfigureAwait(true);
                ApplyResult(result);
            }
            catch (OperationCanceledException)
            {
                lblStatusMessage.Text = "確認をキャンセルしました。";
            }
            catch (Exception ex)
            {
                lblStatusMessage.Text = "確認失敗: " + ex.Message;
                lblStatusMessage.ForeColor = System.Drawing.Color.DarkRed;
            }
            finally
            {
                btnCheckNow.Enabled = true;
            }
        }

        private void btnUpdateNow_Click(object sender, EventArgs e)
        {
            Services.Logger.Info("[UpdateSectionPanel] btnUpdateNow_Click");
            if (_currentResult == null || _currentResult.Latest == null) { Services.Logger.Warn("[UpdateSectionPanel] _currentResult / Latest が null、abort"); return; }
            if (_currentResult.Latest.Version == null) { Services.Logger.Warn("[UpdateSectionPanel] Latest.Version が null、abort"); return; }
            if (string.IsNullOrEmpty(_currentResult.Latest.ZipAssetUrl))
            {
                Services.Logger.Warn("[UpdateSectionPanel] ZipAssetUrl 空、abort");
                MessageBox.Show("zip asset URL が取得できません (リリースに同梱されていない可能性)。",
                    "アップデート中止", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // 開発環境ガード: `<install>/.git` が存在する = git repo 内で動いている。本フローは
            // Launcher / Manager / Companions / shortcut bat / CHANGELOG.md を **物理上書き** するため、
            // 誤って repo のソースを破壊する事故を物理的に防ぐ (リカバリは git reset --hard で可能だが
            // 未 commit の改変が消失する)。本番 install (Install.bat 展開後) には .git は存在しないので
            // 通常運用に影響なし。
            if (System.IO.Directory.Exists(System.IO.Path.Combine(PathManager.BaseDirectory, ".git")))
            {
                Services.Logger.Warn("[UpdateSectionPanel] 開発環境ガード発火 (.git 検出): " + PathManager.BaseDirectory);
                MessageBox.Show(
                    "開発環境 (.git リポジトリ直下) ではアップデート適用を実行できません。\n\n" +
                    "本フローは Launcher / Manager / Companions / shortcut bat / CHANGELOG.md を物理上書きするため、" +
                    "ソースコードを破壊する事故を防ぐためです。\n\n" +
                    "実環境での動作確認は Install.bat で展開した install dir で行ってください。",
                    "開発環境ガード", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            // [A] 事前確認ダイアログ
            // (#178 (a)) 警告色強化: MessageBoxIcon.Question → Warning、title に「起動中アプリの確認をお願いします」
            // を入れて意図を明確化、body の Launcher 閉じ予告を【重要】ブロックに昇格 + LAN 共有運用時の他 PC 対象も
            // 明示。SMB 配置運用 (SPECIFICATION.md §3.7、`\\学校サーバー\PCクラブ` 配置) では他 PC で起動中の
            // Launcher も file lock 衝突源になるが、現状 LAN 検出機構未実装のため文言で予告する暫定対応。
            // 自動検出への upgrade は #179 拡張 PR (Launcher session tracking 含む) で対応予定。
            // (v0.13.1 review Low-2) owner=this 渡しで Z-order / TaskbarOwner 挙動を確定化、
            // 同 method の再起動予告 dialog (L468) と pattern 統一。
            DialogResult confirm = MessageBox.Show(this,
                "アップデートを開始します。\n\n" +
                "  現在: v" + (_currentResult.Current == null ? "(不明)" : _currentResult.Current.ToString(3)) + "\n" +
                "  最新: " + _currentResult.Latest.TagName + "\n\n" +
                "【重要】Launcher などシステムに関連するソフトを、\n" +
                "        この PC を含む全ての PC で先に閉じてください。\n" +
                "        学校 LAN で共有運用している場合、他 PC で起動中の\n" +
                "        Launcher も対象です。閉じないとアップデートに失敗し、\n" +
                "        installation が破損する可能性があります。\n\n" +
                "・ダウンロード + 置換中、Manager が再起動します。\n" +
                "・ゲームデータ (toneprism.db / games/ / backups/ / responses/ / logs/) は保護されます。\n\n" +
                "続行してよろしいですか？",
                "アップデート開始 — 起動中アプリの確認をお願いします",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);
            if (confirm != DialogResult.Yes) { Services.Logger.Info("[UpdateSectionPanel] user が事前確認で No 選択、abort"); return; }
            Services.Logger.Info("[UpdateSectionPanel] user が事前確認で Yes 選択、起動中プロセスチェックへ進む");

            // [A.5] 起動中プロセスチェック (Launcher / Companions、Updater は除外)
            var running = ProcessTerminator.EnumerateRunning();
            while (running.Count > 0)
            {
                var sb = new System.Text.StringBuilder();
                sb.AppendLine("以下のプロセスが起動中です。手動で閉じてから「再試行」を押してください。");
                sb.AppendLine();
                foreach (var p in running)
                {
                    sb.AppendLine("  - " + p.DisplayLabel + " (" + p.InstanceCount + " 件)");
                }
                sb.AppendLine();
                sb.AppendLine("中止する場合は「キャンセル」を押してください。");
                Services.Logger.Warn("[UpdateSectionPanel] 起動中プロセスあり: " + running.Count + " 件");
                DialogResult dr = MessageBox.Show(sb.ToString(),
                    "起動中プロセスあり", MessageBoxButtons.RetryCancel, MessageBoxIcon.Warning);
                if (dr != DialogResult.Retry)
                {
                    Services.Logger.Info("[UpdateSectionPanel] user が起動中プロセス確認で Cancel、abort");
                    return;
                }
                running = ProcessTerminator.EnumerateRunning();
            }

            // [B] 実行 (ProcessingDialog の worker は Task.Run 内で同期呼出、async DL は GetAwaiter で待つ)
            Version targetVersion = _currentResult.Latest.Version;
            string zipUrl = _currentResult.Latest.ZipAssetUrl;
            long zipSizeBytes = _currentResult.Latest.ZipSizeBytes;
            string versionStr = targetVersion.ToString(3);
            string stagingDir = PathManager.StagingRootForUpdate(versionStr);
            Services.Logger.Info("[UpdateSectionPanel] アップデート worker 起動準備: target=v" + versionStr + " zip=" + zipUrl + " size=" + zipSizeBytes + " staging=" + stagingDir);

            bool spawnedUpdater = false;
            ProcessingDialog dialogRef = null;
            using (var dialog = new ProcessingDialog((progress, token) =>
            {
                // (#108 Phase 4 round 1 M2 fix) worker から置換境界 entry で cancel ボタンを hide する
                // ための callback。closure で dialogRef を capture して RunUpdateWorker に渡す。
                Action disableCancelCb = () => { if (dialogRef != null) dialogRef.DisableCancelFromWorker(); };
                spawnedUpdater = RunUpdateWorker(progress, token, zipUrl, zipSizeBytes, targetVersion, stagingDir, disableCancelCb);
            }))
            {
                dialogRef = dialog;
                dialog.AllowCancel = true;
                dialog.Text = "アップデート";
                dialog.ShowDialog(this);

                Services.Logger.Info("[UpdateSectionPanel] ProcessingDialog 結果: DialogResult=" + dialog.DialogResult + " spawnedUpdater=" + spawnedUpdater);
                if (dialog.DialogResult == DialogResult.OK && spawnedUpdater)
                {
                    // (#170 followup) ダウンロード + staging 完了直後の再起動予告 dialog。
                    // 旧実装は ProcessingDialog 閉じてから即 Application.Exit で Manager が silent に
                    // 消える挙動 (= user 視点で「あれ?何が起きた?」になりやすい)。本 dialog で
                    // 「これから Manager を一旦終了 → 新版で自動起動」を明示してから user の OK で
                    // 確定終了。新 Manager 起動時には sentinel 経由で「✓ アップデート完了」 dialog が出る。
                    MessageBox.Show(this,
                        "ダウンロードと展開が完了しました。\n\n" +
                        "OK を押すと Manager を一旦終了して、新しいバージョンで自動的に再起動します。\n" +
                        "再起動には数秒〜数十秒かかる場合があります。\n\n" +
                        "新しい Manager が起動したら、「✓ アップデート完了」のお知らせが表示されます。",
                        "Manager を再起動します",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                    Services.Logger.Info("[UpdateSectionPanel] Updater spawn 成功、再起動予告 dialog 確認後 Application.Exit を呼ぶ");
                    // Updater は spawn 済、Manager プロセスの終了待機を開始している。Application.Exit で
                    // message loop を抜けると `finally Logger.Shutdown` 経由で正常 exit、Updater の Step 1/4
                    // polling が抜けて Manager dir 置換 + 新 Manager.exe 起動に進む。
                    System.Windows.Forms.Application.Exit();
                }
                else
                {
                    Services.Logger.Warn("[UpdateSectionPanel] アップデートは完走しませんでした (DialogResult=" + dialog.DialogResult + ")。staging dir はそのまま、次回起動時 zombie cleanup で削除されます。");
                }
            }
        }

        /// <summary>
        /// アップデート worker (`ProcessingDialog` の Task.Run 内で同期実行)。
        /// SPEC §3.7.3 [4]〜[11] の Manager UI 側責務を順番に実行:
        ///   - zip DL → staging 展開 → ExpectedFiles 検証 → Bundle ver 一致検証 → Launcher / Companions
        ///     置換 → shortcut bat 置換 → CHANGELOG.md 置換 → Updater dir 置換 → Updater spawn。
        ///   - 「置換境界」より前 (検証フェーズまで) は CancellationToken で abort 可能、それ以降は
        ///     half-state 防止のため cancel チェックを外して完走させる。
        /// </summary>
        /// <returns>true: Updater spawn 成功 (caller は Application.Exit を呼ぶ責務) / false: ありえない (例外で抜ける)</returns>
        private bool RunUpdateWorker(System.IProgress<ProgressInfo> progress, System.Threading.CancellationToken ct,
            string zipUrl, long zipSizeBytes, Version targetVersion, string stagingDir,
            Action disableCancelCb)
        {
            // (#108 Phase 4 round 1 log) worker 全体を try/catch で囲み、例外時に stack trace を Logger.Error
            // に残してから rethrow (ProcessingDialog の generic MessageBox に流れる)。各 step は Logger.Info
            // で進入トレースを残す。これで failure 時に「何段階目で何が起きたか」が log だけで再構成可能に。
            try
            {
                Services.Logger.Info("[UpdateSectionPanel] RunUpdateWorker 開始: target=v" + targetVersion.ToString(3) + " staging=" + stagingDir);

                // staging dir clean (前回 zombie がある場合に備えて削除してから作り直す)
                if (System.IO.Directory.Exists(stagingDir))
                {
                    Services.Logger.Info("[UpdateSectionPanel] 既存 staging dir を削除: " + stagingDir);
                    System.IO.Directory.Delete(stagingDir, recursive: true);
                }
                System.IO.Directory.CreateDirectory(stagingDir);

                string zipPath = System.IO.Path.Combine(stagingDir, "TonePrism_v" + targetVersion.ToString(3) + ".zip");

                // ディスク容量 pre-check (zip + 展開 + buffer = ~3 倍想定)
                try
                {
                    long needed = System.Math.Max(zipSizeBytes, 100L * 1024L * 1024L) * 3L;
                    string root = System.IO.Path.GetPathRoot(stagingDir);
                    if (!string.IsNullOrEmpty(root))
                    {
                        var drive = new System.IO.DriveInfo(root);
                        Services.Logger.Info("[UpdateSectionPanel] disk pre-check: root=" + root + " needed=" + (needed / 1024 / 1024) + "MB free=" + (drive.AvailableFreeSpace / 1024 / 1024) + "MB");
                        if (drive.AvailableFreeSpace < needed)
                        {
                            throw new System.IO.IOException(
                                "ディスク容量不足: 必要 " + (needed / 1024 / 1024) + " MB、空き " +
                                (drive.AvailableFreeSpace / 1024 / 1024) + " MB");
                        }
                    }
                }
                catch (System.IO.DriveNotFoundException) { Services.Logger.Warn("[UpdateSectionPanel] disk pre-check skip: DriveNotFound"); }

                ct.ThrowIfCancellationRequested();

                // [1] zip DL (5-40%)
                // (#108 Phase 4 round 2 M9) Logger trace の step 番号は code 内部の進捗 indicator として
                // [N/10] のまま (= UI progress.Report の pct と対応)、対応する SPEC §3.7.3 のステップ番号
                // も `(SPEC §3.7.3 [X])` で併記して 3 系統 (code / SPEC / CHANGELOG) の番号乱立を解消。
                Services.Logger.Info("[UpdateSectionPanel] [Step 1/10] zip DL 開始 (SPEC §3.7.3 [5])");
                progress.Report(new ProgressInfo(5, "ダウンロード中...", zipUrl));
                var dlProgress = new System.Progress<DownloadProgress>(dp =>
                {
                    int pct = 5 + (int)(dp.Percent * 0.35);  // 5-40%
                    progress.Report(new ProgressInfo(pct, "ダウンロード中...",
                        string.Format("{0:N0} / {1:N0} bytes", dp.BytesDownloaded, dp.TotalBytes)));
                });
                UpdateDownloader.DownloadAsync(zipUrl, zipPath, dlProgress, ct).GetAwaiter().GetResult();
                ct.ThrowIfCancellationRequested();

                // [2] 展開 (40-50%)
                Services.Logger.Info("[UpdateSectionPanel] [Step 2/10] zip 展開 (SPEC §3.7.3 [6])");
                progress.Report(new ProgressInfo(42, "展開中...", stagingDir));
                UpdateDownloader.Extract(zipPath, stagingDir);
                ct.ThrowIfCancellationRequested();

                // [3] ExpectedFiles 検証 (50-55%)
                // (#177) ValidateStaging が parse 済 BundleManifest を out 引数で返すように signature 拡張。
                // apply 側 (Step 5-9 + defer block) が manifest.Layout 経由で path 解決するための forward
                // compat 機構。v0.3.1 manifest (layout なし) や旧構造 (manifest なし) は manifest=null /
                // manifest.Layout=null に倒れて、各 apply 箇所の `??` null-coalesce で hardcoded legacy
                // path に fallback する設計。
                Services.Logger.Info("[UpdateSectionPanel] [Step 3/10] ExpectedFiles 検証 (SPEC §3.7.3 [6] 内容検証)");
                progress.Report(new ProgressInfo(50, "ファイル検証中..."));
                BundleManifest manifest;
                var missing = UpdateDownloader.ValidateStaging(stagingDir, out manifest);
                if (missing.Count > 0)
                {
                    throw new System.IO.InvalidDataException(
                        "staging に必要ファイルが不足しています:\n  " + string.Join("\n  ", missing));
                }

                // [4] Bundle version 一致検証 (55-60%)
                Services.Logger.Info("[UpdateSectionPanel] [Step 4/10] Bundle version 一致検証 (SPEC §3.7.3 [6] 内容検証)");
                progress.Report(new ProgressInfo(55, "バージョン一致を検証中..."));
                Version stagingBundleVer;
                if (!UpdateDownloader.ValidateBundleVersion(stagingDir, targetVersion, manifest, out stagingBundleVer))
                {
                    // (#108 Phase 4 round 5 L-5) error message に staging 側 version を含めて debug
                    // ergonomics 改善 (旧実装は user が log を開かないと staging version を知れなかった)。
                    string stagingDesc = stagingBundleVer == null
                        ? "(staging CHANGELOG.md parse 失敗)"
                        : "v" + stagingBundleVer.ToString(3);
                    throw new System.IO.InvalidDataException(
                        "staging の CHANGELOG.md 最新 Bundle (" + stagingDesc + ") が target version (v" +
                        targetVersion.ToString(3) + ") と一致しません。zip 改竄 / 取り違え疑い。");
                }

                // ===== ここから「置換境界」: 以降の cancel は half-state を生むので無効化 =====
                // (#108 Phase 4 round 1 M2 fix) UI 上も cancel ボタンを hide して整合させる
                // (旧実装は AllowCancel=true 固定で「キャンセル押せるが無視」の misleading UX があった)。
                if (disableCancelCb != null) disableCancelCb();

                // (#175 Phase 4.1) staging dir 内の bundle root を解決。manifest あれば新構造
                // (`<staging>/bundle`)、無ければ legacy fallback (`<staging>`)。以降の Step 5-9 +
                // defer block の path 参照 + Updater spawn 引数を bundleRoot 経由に統一して、
                // 新旧両構造を同 code path で扱う forward compat 機構。詳細は
                // UpdateDownloader.ResolveBundleRoot の docstring を参照。
                string bundleRoot = UpdateDownloader.ResolveBundleRoot(stagingDir);
                Services.Logger.Info("[UpdateSectionPanel] bundleRoot 解決: " + bundleRoot);

                // [5] Launcher dir 置換 (60-67%)
                Services.Logger.Info("[UpdateSectionPanel] [Step 5/10] Launcher dir 置換 (SPEC §3.7.3 [7])");
                progress.Report(new ProgressInfo(60, "Launcher を更新中...", PathManager.LauncherDir));
                // (#177) manifest.Layout 経由 path 解決、layout 不在 (v0.3.1 以前 manifest / 旧構造) は
                // hardcoded legacy path に fallback して新旧 zip を同 code path で扱う forward compat。
                // (round 1 Medium-4) wire format `/` separator を OS-native separator に変換、
                // `ValidateStagingViaManifest` の `relWin = rel.Replace('/', Path.DirectorySeparatorChar)`
                // pattern と一貫させる (.NET on Windows は `/` も許容するため実害ゼロだが in-PR の作法統一)。
                string stagingLauncher = System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.LauncherDir ?? "files/Launcher").Replace('/', System.IO.Path.DirectorySeparatorChar));
                // (#108 Phase 4 round 4 codex P1 NEW) CleanupBak は Step 10 後にまとめて実行する。
                // 旧実装は各 Step 完了直後に CleanupBak していたため、Step 6-10 で failure 時に旧
                // Launcher 復元不能 mixed-version state に陥っていた (例: Launcher 置換成功 → Companion
                // 置換失敗で abort、Launcher の .bak は既に消えてる → user は旧 Launcher を取り戻せない)。
                // 置換した dir リスト (`replacedDirs`) を track して、Step 10 Updater spawn 成功後に
                // まとめて Cleanup する形に変更。
                var replacedDirs = new System.Collections.Generic.List<string>();
                var launcherResult = DirReplacer.Replace(stagingLauncher, PathManager.LauncherDir, allowInitialDeploy: false);
                if (launcherResult == DirReplacer.ReplaceResult.RecoveredAbort)
                {
                    // (#108 Phase 4 round 3 L-4) auto-recover 経路: user に「再実行で完走する」旨を伝える。
                    throw new System.IO.IOException(
                        "Launcher dir の前回 rollback 失敗状態を自動復元しました。" +
                        "もう一度「今すぐアップデート」を押すと適用が完走します。");
                }
                if (launcherResult != DirReplacer.ReplaceResult.Ok)
                {
                    throw new System.IO.IOException("Launcher dir の置換に失敗しました (詳細は log 参照)。");
                }
                replacedDirs.Add(PathManager.LauncherDir);

                // [6] Companions (Updater 以外) 置換 — dir 列挙で LauncherAgent (probe/sensor/focus 統合、旧 WindowProbe) を置換、将来追加分も対象
                Services.Logger.Info("[UpdateSectionPanel] [Step 6/10] Companions (Updater 以外) 置換 (SPEC §3.7.3 [8])");
                progress.Report(new ProgressInfo(67, "Companions を更新中..."));
                string stagingCompanionsRoot = System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.CompanionsDir ?? "files/Companions").Replace('/', System.IO.Path.DirectorySeparatorChar));
                if (System.IO.Directory.Exists(stagingCompanionsRoot))
                {
                    foreach (string stagingComp in System.IO.Directory.EnumerateDirectories(stagingCompanionsRoot))
                    {
                        string compName = System.IO.Path.GetFileName(stagingComp.TrimEnd('\\', '/'));
                        if (string.IsNullOrEmpty(compName)) continue;
                        if (string.Equals(compName, "Updater", System.StringComparison.OrdinalIgnoreCase)) continue;
                        string targetComp = System.IO.Path.Combine(PathManager.CompanionsDir, compName);
                        Services.Logger.Info("[UpdateSectionPanel]   Companion '" + compName + "' 置換");
                        // (#108 Phase 4 round 3 codex P1) Companion は新規追加で旧 install に target 不在の
                        // ケースが正常 path、`allowInitialDeploy: true` で初回 deploy 経路を許可。
                        var compResult = DirReplacer.Replace(stagingComp, targetComp, allowInitialDeploy: true);
                        if (compResult == DirReplacer.ReplaceResult.RecoveredAbort)
                        {
                            throw new System.IO.IOException(
                                "Companion '" + compName + "' の前回 rollback 失敗状態を自動復元しました。" +
                                "もう一度「今すぐアップデート」を押すと適用が完走します。");
                        }
                        if (compResult != DirReplacer.ReplaceResult.Ok
                            && compResult != DirReplacer.ReplaceResult.InitialDeploy)
                        {
                            throw new System.IO.IOException("Companion '" + compName + "' の置換に失敗しました (詳細は log 参照)。");
                        }
                        // InitialDeploy 経路では .bak が存在しないが、CleanupBak は内部 Exists check
                        // で no-op になるため defer list に追加して問題なし。
                        replacedDirs.Add(targetComp);
                    }
                }

                // [7] shortcut bat 置換 (single-file、`<install_parent>/Launcher.bat` と `Manager.bat`)
                // (#108 Phase 4 round 1 H1 fix) FileReplacer.ReplaceFile の戻り値を必ず check して
                // 失敗時は throw、silent shortcut 置換失敗 → 旧 bat が `<install_parent>/` に残ったまま
                // 新 Manager 起動して挙動不審、の path を closure。DirReplacer 系の throw pattern と
                // 対称化。
                Services.Logger.Info("[UpdateSectionPanel] [Step 7/10] shortcut bat 置換 (SPEC §3.7.3 [9])");
                progress.Report(new ProgressInfo(70, "ショートカットを更新中..."));
                string parentDir = PathManager.InstallParentDir;
                if (!string.IsNullOrEmpty(parentDir))
                {
                    if (!FileReplacer.ReplaceFile(
                        System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.LauncherBat ?? "Launcher.bat").Replace('/', System.IO.Path.DirectorySeparatorChar)),
                        System.IO.Path.Combine(parentDir, "Launcher.bat")))
                    {
                        throw new System.IO.IOException("Launcher.bat の置換に失敗しました (詳細は log 参照)。");
                    }
                    if (!FileReplacer.ReplaceFile(
                        System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.ManagerBat ?? "Manager.bat").Replace('/', System.IO.Path.DirectorySeparatorChar)),
                        System.IO.Path.Combine(parentDir, "Manager.bat")))
                    {
                        throw new System.IO.IOException("Manager.bat の置換に失敗しました (詳細は log 参照)。");
                    }
                }
                else
                {
                    // (#108 Phase 4 round 6 M-4) InstallParentDir 空 = `PathManager.BaseDirectory` が
                    // drive root 等の病的入力で `Path.GetDirectoryName` が null になった case。
                    // 旧実装は Warn log のみで継続して shortcut 置換 skip + 適用続行する silent path
                    // だったが、round 1 H1 で「FileReplacer 失敗時は throw」に揃えた原則と非対称。
                    // 実環境では発生しないが silent pass を残さず fail-fast。
                    throw new System.IO.IOException(
                        "InstallParentDir が空のため shortcut bat を置換できません " +
                        "(BaseDirectory=" + PathManager.BaseDirectory + " が drive root 等の病的入力疑い)。");
                }

                // (#108 Phase 4 round 5 M-1) CHANGELOG.md 置換は **Updater spawn 成功後** の defer
                // block に移動 (= 旧 [Step 8] を Step 10 後に再配置)。旧順序は Step 9/10 (Updater dir
                // 置換 + Updater spawn) で fail した場合、CHANGELOG が NEW で Manager 本体は OLD のまま
                // → `VersionInventory.ReadBundleVersion` が NEW 返却 → `ComputeStatus` で `UpToDate`
                // 判定 → 「最新版を実行中」誤表示 + btnUpdateNow disabled で user が再 update 不能
                // partial-state に陥っていた。CHANGELOG は 1 file copy で side effect 極小、Updater
                // spawn 成功確認後に動かせば fail tolerance を下げない。

                // [9] Companions/Updater 置換 (SPEC §3.7.3 [10]、常に staging の新 Updater で置換)
                Services.Logger.Info("[UpdateSectionPanel] [Step 9/10] Companions/Updater 置換 (SPEC §3.7.3 [10])");
                progress.Report(new ProgressInfo(77, "Updater を更新中...", PathManager.UpdaterDir));
                string stagingUpdater = System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.UpdaterDir ?? "files/Companions/Updater").Replace('/', System.IO.Path.DirectorySeparatorChar));
                var updaterResult = DirReplacer.Replace(stagingUpdater, PathManager.UpdaterDir, allowInitialDeploy: false);
                if (updaterResult == DirReplacer.ReplaceResult.RecoveredAbort)
                {
                    throw new System.IO.IOException(
                        "Updater dir の前回 rollback 失敗状態を自動復元しました。" +
                        "もう一度「今すぐアップデート」を押すと適用が完走します。");
                }
                if (updaterResult != DirReplacer.ReplaceResult.Ok)
                {
                    throw new System.IO.IOException("Updater dir の置換に失敗しました (詳細は log 参照)。");
                }
                replacedDirs.Add(PathManager.UpdaterDir);

                // [10] Updater spawn (Manager の終了を待機 + Manager dir 置換 + 新 Manager.exe 起動を引き継ぐ)
                Services.Logger.Info("[UpdateSectionPanel] [Step 10/10] Updater spawn (SPEC §3.7.3 [11])");
                progress.Report(new ProgressInfo(85, "Updater を起動中..."));
                if (!UpdaterClient.Spawn(bundleRoot, forceKill: false, logSink: null))
                {
                    throw new System.IO.IOException("Updater spawn に失敗しました。");
                }

                // (#108 Phase 4 round 4 codex P1 NEW + round 5 M-1) Updater spawn 成功 = ここまで来れば
                // Application.Exit 直前で「すべての置換が完了 + Updater が引き継ぎ待機中」状態。
                // **ここで初めて**:
                //   (a) CHANGELOG.md 置換 (round 5 M-1: VersionInventory が partial-state で誤判定する
                //       のを避けるため Updater spawn 成功後に動かす)
                //   (b) 各置換 dir の .bak 一括 cleanup
                // を実施。途中 Step で throw されると本ブロックに到達せず、.bak は残ったまま + CHANGELOG
                // も OLD のまま (= UI は依然「アップデートあり」を正しく表示)、次回起動時の zombie .bak
                // detection で 「target 存在 + .bak 存在 → 前回 partial state、target を正として .bak 削除」
                // path に自然に流れて消化される。
                // (#108 Phase 4 round 8 M-1) defer block にも `[Step 8/10]` 番号を割り当て、worker
                // log の `[Step N/10]` 表記の 8 番欠番 (Step 7 → Step 9 の飛び) を埋める。旧実装は
                // round 5 M-1 で旧 Step 8 を defer 化した際、log label の renumber を怠ったため
                // log を読むユーザーから「Step 8 で abort してログが切れた?」と誤読される path があった
                // (= round 2 M9 「code 内部 step 番号 = [N/10]」原則の self-violation)。
                // (#178 (b) round 2 Low-4) 旧実装は 85 → 95 の間に CHANGELOG 置換 + CleanupBak + sentinel
                // 書出しの 3 操作が無音で連続し、UI が「Updater を起動中... 85%」で停滞して見えていた。
                // SMB 共有 / AV scan 環境で seconds 単位かかる case の体感停滞を緩和するため、defer block /
                // sentinel 書出し / 終了 message の 3 段階に分けて progress.Report を発火する。
                progress.Report(new ProgressInfo(88, "後処理中 (CHANGELOG 置換 + 一時ファイル削除)..."));
                Services.Logger.Info("[UpdateSectionPanel] [Step 8/10] CHANGELOG.md 置換 + .bak cleanup (defer: Updater spawn 成功後、SPEC §3.7.3 [8] + round 5 M-1 で旧 Step 8 を本 defer に移動)");
                // (#108 Phase 4 round 7 M-1) `FileReplacer.ReplaceFile` は round 2 H4 で rollback-fatal
                // 経路に `InvalidOperationException` throw を導入したため、旧 `if (!ReplaceFile(...))`
                // 形式では throw を外に逃がして worker catch (本 method 末尾) で rethrow →
                // CleanupBak loop + Application.Exit が skip → Updater が timeout (exit 3) で死ぬ
                // silent partial-state があった。docstring「CHANGELOG 置換失敗は致命的ではない」前提と
                // 乖離 = throw 経路も Warn log のみで継続する形に揃える。
                try
                {
                    if (!FileReplacer.ReplaceFile(
                        System.IO.Path.Combine(bundleRoot, (manifest?.Layout?.ChangelogMd ?? "files/CHANGELOG.md").Replace('/', System.IO.Path.DirectorySeparatorChar)),
                        PathManager.BundleChangelogPath))
                    {
                        // CHANGELOG 置換失敗は致命的ではない (= VersionInventory が OLD のまま読むだけで
                        // installation は機能、user は次回 update で再試行可能)。Warn log のみで継続。
                        Services.Logger.Warn("[UpdateSectionPanel] CHANGELOG.md 置換失敗 (Updater spawn は成功済、Application.Exit 続行)");
                    }
                }
                catch (Exception fileEx)
                {
                    Services.Logger.Warn("[UpdateSectionPanel] CHANGELOG.md 置換例外 (致命的にせず継続): " + fileEx.GetType().Name + ": " + fileEx.Message);
                }
                foreach (string repDir in replacedDirs)
                {
                    // (#108 Phase 4 round 7 L-2) M-1 と同パッケージ: 1 dir の cleanup 失敗で残り dir の
                    // .bak 処理 + Application.Exit が skip するのを防ぐ。.bak 残置は次回起動時の
                    // zombie .bak detection 経路 (`DirReplacer.Replace` 冒頭で target + .bak 同時存在
                    // → 前回 partial → .bak 削除) で消化されるため致命的ではない。
                    try
                    {
                        DirReplacer.CleanupBak(repDir);
                    }
                    catch (Exception cleanupEx)
                    {
                        Services.Logger.Warn("[UpdateSectionPanel] CleanupBak 失敗 (継続): dir=" + repDir + " ex=" + cleanupEx.GetType().Name + ": " + cleanupEx.Message);
                    }
                }

                // (#178 (b)) アップデート完了 sentinel ファイル書出し。自動再起動した新 Manager の
                // MainForm_Load 冒頭で `TryShowUpdateCompletedDialog` が読み込んで、「同時起動に関する
                // 注意」MessageBox の替わりに「✓ アップデート完了」MessageBox を表示する (= 排他置換、
                // 起動時 dialog 数は常に 1 つ)。書込み失敗は dialog が出ないだけで installation 自体は
                // 完成しているため Warn log で握り潰し、Application.Exit は続行。
                // 詳細: SPECIFICATION.md §3.7.3 「sentinel ファイル仕様」参照。
                progress.Report(new ProgressInfo(92, "完了通知ファイルを準備中..."));
                try
                {
                    string sentinelPath = System.IO.Path.Combine(PathManager.BaseDirectory, ".update_completed");
                    // (#440) **これから入るはずの Manager の版数**も書く。再起動した Manager が自分の
                    // assembly 版数と突き合わせて「本当に置換されたか」を確認するために使う。
                    // sentinel は Updater の **spawn 成功後**に書かれるだけで、spawn した Updater が
                    // その後で失敗するケース (= Manager dir の置換失敗) を捕まえていなかった。
                    // その結果、置換に失敗した**古い Manager** が起動して「✓ アップデート完了 /
                    // 新しい管理ソフトが起動しています」と表示していた (v0.9.0 以降 2 リリース分、
                    // 更新失敗がこれで隠れていた)。
                    string expectedManagerVersion = null;
                    try
                    {
                        string stagingManagerExe = System.IO.Path.Combine(
                            bundleRoot,
                            (manifest?.Layout?.ManagerDir ?? "files/Manager").Replace('/', System.IO.Path.DirectorySeparatorChar),
                            "TonePrism_Manager.exe");
                        if (System.IO.File.Exists(stagingManagerExe))
                        {
                            expectedManagerVersion = System.Diagnostics.FileVersionInfo
                                .GetVersionInfo(stagingManagerExe).FileVersion;
                        }
                    }
                    catch (Exception mvEx)
                    {
                        // 取れなくても致命的ではない (旧来どおり Bundle 版数だけの dialog になる)。
                        Services.Logger.Warn("[UpdateSectionPanel] staging Manager の版数取得に失敗 (完了検証は skip): " + mvEx.Message);
                    }
                    string json = Services.JsonCompat.Serialize(new
                    {
                        completedAt = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", System.Globalization.CultureInfo.InvariantCulture),
                        newVersion = targetVersion.ToString(3),
                        newManagerVersion = expectedManagerVersion,
                    });
                    System.IO.File.WriteAllText(sentinelPath, json, System.Text.Encoding.UTF8);
                    Services.Logger.Info("[UpdateSectionPanel] update_completed sentinel 書出し: " + sentinelPath);
                }
                catch (Exception sentEx)
                {
                    Services.Logger.Warn("[UpdateSectionPanel] update_completed sentinel 書出し失敗 (dialog 出ないだけで続行): " + sentEx.Message);
                }

                progress.Report(new ProgressInfo(95, "Manager を終了中..."));
                Services.Logger.Info("[UpdateSectionPanel] RunUpdateWorker 全 Step 完了、Application.Exit へ");
                // worker 終了 → ProcessingDialog が DialogResult.OK で抜ける → caller が Application.Exit()
                return true;
            }
            catch (System.OperationCanceledException)
            {
                Services.Logger.Warn("[UpdateSectionPanel] RunUpdateWorker: user が cancel");
                throw;
            }
            catch (Exception ex)
            {
                Services.Logger.Error("[UpdateSectionPanel] RunUpdateWorker 中に例外発生", ex);
                throw;
            }
        }

        private void btnSkip_Click(object sender, EventArgs e)
        {
            if (_currentResult == null || _currentResult.Latest == null || _currentResult.Latest.Version == null) return;
            DialogResult dr = MessageBox.Show(
                "「" + _currentResult.Latest.TagName + "」をスキップしますか？\n\n" +
                "・起動時の通知ダイアログのみ抑制されます (= 黙る効果)。\n" +
                "・このタブの「今すぐアップデート」ボタンはそのまま使えるので、自分のタイミングで適用できます。\n" +
                "・次のリリース (例: 次バージョン) が出れば自動で通知が再開されます。",
                "スキップ確認",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (dr != DialogResult.Yes) return;
            // (#170 followup) LAN 他 PC race fence。skip 書込は user 意図的な destructive 操作
            // (= settings table への INSERT OR REPLACE) で BackupSettingsForm OK click と同位置付け、
            // 1 段目 fence (SectionPanel 配下の button click 直前) として CheckBeforeWrite を呼ぶ。
            // Cancel 時は skip 自体を中止して current 状態維持。
            if (Services.SessionConflictHelper.CheckBeforeWrite(this, "アップデートスキップ") == DialogResult.Cancel) return;
            _updateChecker.Skip(_currentResult.Latest.Version);
            // (#108 Phase 4 round 4 L-5) LastError も carry。Skip 直前に「再確認エラー: ...」grey sub-text
            // が出ていた case で Skip 後に context が消えると UX surprise になるため明示的に維持。
            ApplyResult(new UpdateCheckResult
            {
                Status = UpdateCheckStatus.Skipped,
                Current = _currentResult.Current,
                Latest = _currentResult.Latest,
                CumulativeReleases = _currentResult.CumulativeReleases,
                CheckedAtUnixMs = _currentResult.CheckedAtUnixMs,
                FromCache = _currentResult.FromCache,
                LastError = _currentResult.LastError,
            });
        }

        private void btnOpenBrowser_Click(object sender, EventArgs e)
        {
            string url = (_currentResult != null && _currentResult.Latest != null && !string.IsNullOrEmpty(_currentResult.Latest.HtmlUrl))
                ? _currentResult.Latest.HtmlUrl
                : "https://github.com/" + GitHubReleaseChecker.Owner + "/" + GitHubReleaseChecker.Repo + "/releases";
            try
            {
                Process.Start(new ProcessStartInfo { FileName = url, UseShellExecute = true });
            }
            catch (Exception ex)
            {
                MessageBox.Show("ブラウザを開けませんでした: " + ex.Message,
                    "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void webReleaseNotes_Navigating(object sender, WebBrowserNavigatingEventArgs e)
        {
            // 内部 about:blank はそのまま許可、外部 URL は cancel して既定ブラウザに委譲
            string url = e.Url == null ? string.Empty : e.Url.ToString();
            if (string.IsNullOrEmpty(url) || url.StartsWith("about:", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }
            e.Cancel = true;
            // (#108 Phase 4 round 1 L5 fix) scheme whitelist。Markdown の `[click](javascript:alert(1))`
            // 形式 link を Process.Start に直接渡すと CommandLineToArgvW 経由で OS が解釈する path に
            // なるため、http(s) のみ許可する defensive guard。release notes 著者は repo maintainer のみ
            // で信頼境界内だが、安価な防御として whitelist 採用。
            if (!url.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
                && !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                Services.Logger.Warn("[UpdateSectionPanel] release notes 内の non-http URL を block: " + url);
                return;
            }
            try
            {
                Process.Start(new ProcessStartInfo { FileName = url, UseShellExecute = true });
            }
            catch (Exception ex)
            {
                // (#108 Phase 4 round 8 L-6) 旧実装は `catch { }` 空握り潰しで「click したのに何も
                // 起きない」UX + 診断 trail なし。同 class の他 catch (`btnOpenBrowser_Click` 等) は
                // MessageBox + Logger 双方を残しているため非対称だった。release notes 内 URL click は
                // 連続発火し得る (link hover→click の高頻度 path)、MessageBox dialog 連発で煩雑なため
                // Logger.Warn のみで継続。
                Services.Logger.Warn("[UpdateSectionPanel] release notes 内 URL の browser launch 失敗: url=" + url + " ex=" + ex.Message);
            }
        }
    }
}
