using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// `Companions/Updater/TonePrism_Updater.exe` の spawn と exit code dispatch。Phase 4 (#108)。
    ///
    /// SPEC §3.7.4 で固定された Updater CLI 規約に従って Manager UI が Updater を起動する。重要な
    /// 規約 (Phase 3 round 6-8 で固まった):
    ///   - `UseShellExecute=false` (round 8: shell 経由 spawn は handle 紐付けが遅延)
    ///   - `RedirectStandardError=true` + `StandardErrorEncoding=UTF8` (round 7 Codex P2: stderr の文字化け回避)
    ///   - `--caller-pid &lt;Process.GetCurrentProcess().Id&gt;` を **必ず** 渡す (round 8 Codex P2-1: PID 再利用検知のため)
    ///   - exit codes 0-8 を documented dispatch (round 4 H-1 + M-1 で 3 → 3/7/8 分割、round 6 で 6 仕様化)
    ///
    /// 本 class は Updater を spawn した直後に Manager 自身を終了させるための「最後の関数」として
    /// 機能する。Manager は Updater を待たない (待つと Updater の Step 1/4 polling が Manager を
    /// 生存中と判定し続けて timeout してしまう) ため、spawn 直後に Application.Exit() を呼ぶ。
    /// </summary>
    internal static class UpdaterClient
    {
        /// <summary>
        /// Updater を spawn する。spawn 自体に失敗した場合は false を返す (= 起動失敗、Manager は終了しない)。
        /// 成功時 (true) は呼出元が即 Application.Exit() を呼んで Manager を終了させる責務。
        ///
        /// (#175 Phase 4.1) 引数を `stagingDir` から `bundleRoot` に rename。Updater 側
        /// (`Companions/Updater/FileReplacer.cs`) は `--staging <X>/files/Manager` を期待する設計の
        /// まま (= 引数の意味は維持、caller の Manager 側が `<X>` に bundleRoot を渡す形)。新構造では
        /// `bundleRoot = <staging>/bundle`、旧構造 fallback では `bundleRoot = <staging>`。Updater 側
        /// コード変更不要で forward compat 獲得 (caller が bundleRoot 解決の責務を持つ設計)。
        /// </summary>
        /// <param name="bundleRoot">展開済み staging 内の bundle root (= UpdateDownloader.ResolveBundleRoot 解決結果、絶対 path)。
        ///     Updater 側で `<bundleRoot>/files/Manager` を source として使う。</param>
        /// <param name="forceKill">user が「強制終了して再試行」を選択している場合 true</param>
        /// <param name="logSink">Updater stdout/stderr の async 読取結果を流す sink (null 可)。各行が arrival 順で渡される</param>
        public static bool Spawn(string bundleRoot, bool forceKill, Action<string> logSink)
        {
            if (string.IsNullOrEmpty(bundleRoot) || !Directory.Exists(bundleRoot))
            {
                Services.Logger.Error("[UpdaterClient] bundle root が見つかりません: " + (bundleRoot ?? "(null)"));
                return false;
            }
            string updaterExe = PathManager.UpdaterExePath;
            if (!File.Exists(updaterExe))
            {
                Services.Logger.Error("[UpdaterClient] Updater.exe が見つかりません: " + updaterExe);
                return false;
            }
            // (#258 PR4) Assembly.Location は single-file publish で空文字を返す (IL3000)。Environment.ProcessPath は
            // 実 exe パス (apphost) を返し single-file/通常の両方で機能する。理論上 null 可 (取得不能) のため明示チェック:
            // 空だと Quote → `--restart-exe ""` で Updater が置換後 Manager を再起動できず silent 降格するため fail させる
            // (旧 .Location 無ガード + ProcessPath は throw しない dead な try/catch を、Program.cs と対称な null チェックに置換。レビュー Low)。
            string managerExe = Environment.ProcessPath;
            if (string.IsNullOrEmpty(managerExe))
            {
                Services.Logger.Error("[UpdaterClient] Manager.exe path が取得できません (Environment.ProcessPath が空)");
                return false;
            }

            // (#108 Phase 4 round 3 M-2) Process.GetCurrentProcess() の Process handle は IDisposable、
            // using で囲んで明示 Dispose。Spawn() 失敗時 (return false 経路) でも handle leak しない。
            int callerPid;
            using (var self = Process.GetCurrentProcess())
            {
                callerPid = self.Id;
            }
            var args = new List<string>
            {
                "--staging",        Quote(bundleRoot),
                "--manager-target", Quote(PathManager.ManagerDir),
                "--restart-exe",    Quote(managerExe),
                "--log-dir",        Quote(PathManager.UpdaterLogDir),
                "--caller-pid",     callerPid.ToString(),
            };
            if (forceKill)
            {
                // (#170 followup v0.13.1 review Medium-1) force-kill 経路は **default 60s timeout を維持**。
                // ProcessWaiter の force-kill trigger は `timeoutSeconds > 0 && elapsed >= timeoutSeconds` で
                // **timeout 到達で初めて発火** する設計 (ProcessWaiter.cs:143)。`--wait-timeout 0` (= 無制限) と
                // `--force-kill` を併用すると force-kill branch が永久に到達不能になり silent dead code 化。
                // force-kill は「previous attempt timeout → user が "強制終了して再試行" を選択した経路」で
                // 「停止した Manager を確実に殺す」semantic なので timeout が必須。
                args.Add("--force-kill");
            }
            else
            {
                // (#170 followup v0.13.1) 通常経路は Updater の Manager 終了待ち timeout を **0 = 無制限** に明示。
                // default 60s だと UpdateSectionPanel の再起動予告 dialog (Application.Exit 前) で user が
                // OK を遅延 click した場合 + defer 化された CHANGELOG / .bak cleanup の SMB latency で
                // Updater が exit 3 (TimedOutNoForceKill) を返して abort → 次回 Manager 起動時に
                // 「Manager が時間内に閉じませんでした」失敗 banner が出る race があった。
                // 0 (= 無制限) 根拠: Manager UI freeze で永久 polling し続ける zombie Updater リスクはあるが、
                // Windows user 常識として「ソフトが固まったら task manager で kill」が確立しており、
                // 自動 abort で謎 banner を出すより user 自身が手動 recovery する path のほうが clean。
                args.Add("--wait-timeout");
                args.Add("0");
            }
            string argLine = string.Join(" ", args);
            Services.Logger.Info("[UpdaterClient] Updater spawn: " + updaterExe + " " + argLine);

            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = updaterExe,
                    Arguments = argLine,
                    UseShellExecute = false,
                    // (#170 followup) `CreateNoWindow = true`。旧設計は「Updater console を visible にして
                    // user 安心感」だったが、実態は `RedirectStandardOutput=true` で stdout/stderr が pipe に
                    // 吸われて visible console が常に empty (= 黒い空 box が表示されるだけで「ウイルスかな?」
                    // UX 悪化の温床) だった。
                    // Updater output の trace 経路:
                    // - (a) `<install>/logs/updater/updater_<PC>_<datetime>.log` (= Updater 自身の file log、
                    //   **完全な全行ログ**)
                    // - (b) Manager log 経由 `[Updater stdout/stderr] ...` (= 本 Manager process が生きている
                    //   間だけ redirect で取込まれる、**Manager 死亡後の Updater output は届かない**)
                    // つまり (a) が full trace の SoT、(b) は Manager 生存中の補助記録。visible console を
                    // 消しても trace 情報は (a) で完全に残るため情報損失なし。
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    StandardOutputEncoding = Encoding.UTF8,
                    StandardErrorEncoding = Encoding.UTF8,
                    WorkingDirectory = Path.GetDirectoryName(updaterExe) ?? string.Empty,
                };

                Process proc = Process.Start(psi);
                if (proc == null)
                {
                    Services.Logger.Error("[UpdaterClient] Process.Start が null を返却");
                    return false;
                }

                // async event 読取で 4KB buffer deadlock 回避 (SPEC §3.7.4 round 7 Codex P2 規約)
                proc.OutputDataReceived += (s, e) =>
                {
                    if (e.Data != null)
                    {
                        Services.Logger.Info("[Updater stdout] " + e.Data);
                        if (logSink != null) try { logSink(e.Data); } catch { }
                    }
                };
                proc.ErrorDataReceived += (s, e) =>
                {
                    if (e.Data != null)
                    {
                        Services.Logger.Warn("[Updater stderr] " + e.Data);
                        if (logSink != null) try { logSink(e.Data); } catch { }
                    }
                };
                proc.BeginOutputReadLine();
                proc.BeginErrorReadLine();

                Services.Logger.Info("[UpdaterClient] Updater spawn 成功 (PID=" + proc.Id + ")。Manager は終了します。");
                // proc.Dispose() しない: child process が exit 前に handle close すると stream redirect が
                // 切れる。Manager が Application.Exit で抜けると process tree が綺麗に分離するので問題なし。
                // (#108 Phase 4 round 4 L-3) **caller 不変式**: 本 method の return true は「caller が
                // Application.Exit を呼ぶこと」を前提とする trade-off (= proc handle を intentional leak、
                // GC finalizer 経由 Dispose で stdout redirect 切断する path を避けるため)。
                // (#170 followup v0.13.1) 旧 invariant 「**即** Application.Exit」+「modal dialog 重ね開き
                // 等で遅延 = 不変式違反」は v0.13.1 で **緩和**: Spawn と Application.Exit の間に
                // user 介入 modal (= 再起動予告 dialog) を **意図的に挟むことが許容** された (= 通常経路で
                // `--wait-timeout 0` を渡して Updater 側 polling を無制限化、user の OK click を任意時間
                // 待てる構造に変更)。force-kill 経路は default 60s timeout 維持で旧 invariant 通り。
                // SPEC §3.7.3 [11] の不可分性は file 置換 / sentinel / 再起動 ops の atomic 性であって、
                // user 介入 delay は SPEC 範囲外 (本 round で sentinel write 位置の SPEC 表現も同期更新)。
                return true;
            }
            catch (Exception ex)
            {
                Services.Logger.Error("[UpdaterClient] Updater spawn 失敗: " + ex.Message);
                return false;
            }
        }

        /// <summary>
        /// `<install>/logs/updater/` 配下の直近 **2 分以内** のログから Updater の exit code を回収する。
        /// 新 Manager が起動した直後 (MainForm_Load) で呼んで「前回アップデート結果」を UI バナーに出す用途。
        /// 該当ログが見つからない / parse 失敗時は null。
        ///
        /// **注意 (round 2 M8)**: 旧 docstring は「1 分以内」と書いていたが実装は `AddMinutes(-2)` (= 2 分)、
        /// round 1 H3 fix で書き直した際の追従漏れ。docstring を実装に揃えて訂正。
        /// </summary>
        /// <summary>
        /// (#440) Updater が書き残した実行結果 (`&lt;install&gt;/.update_result`)。
        ///
        /// Manager は Updater の**プロセス終了コードを受け取れない** (受け取るには待つ必要があるが、
        /// 待っていると dir を置換できない)。そのため従来は「ログ末尾 20 行に `[ERROR]` があれば失敗」
        /// という推測をしていた。ログは人間向けの副産物であって API ではなく、致命的でない Error 行で
        /// 誤判定するうえ「どの実行の話か」も分からない (だから直近 2 分という窓が要った)。
        /// Updater が答えを持っているのだから、解析で復元せず**消えない場所に書いてもらう**。
        /// </summary>
        public sealed class UpdateRunResult
        {
            public int ExitCode { get; set; }
            public bool Success { get; set; }
            /// <summary>この更新で入るはずだった Manager の FileVersion (読めなければ null)。</summary>
            public string TargetManagerVersion { get; set; }
        }

        internal static string UpdateResultPath
        {
            get { return Path.Combine(PathManager.BaseDirectory, ".update_result"); }
        }

        /// <summary>
        /// (#440) 実行結果を読む。ファイルが無ければ null (= 旧 Updater か、まだ一度も更新していない)。
        /// 呼び出し側は null のとき従来の <see cref="TryLoadLastExitCode"/> にフォールバックする。
        /// </summary>
        public static UpdateRunResult TryLoadUpdateResult()
        {
            try
            {
                if (!File.Exists(UpdateResultPath)) return null;
                string json = File.ReadAllText(UpdateResultPath, System.Text.Encoding.UTF8);
                var dto = JsonCompat.Deserialize<UpdateRunResult>(json);
                return dto;
            }
            catch (Exception ex)
            {
                Logger.Warn("[UpdaterClient] .update_result を読めませんでした (従来の判定に fallback): " + ex.Message);
                return null;
            }
        }

        /// <summary>
        /// (#440) 実行結果を消す。**成功を確認した時点で呼ぶ** — 成功はもう覚えておく必要が無い。
        /// 失敗は残す (アップデートタブが再試行ボタンを有効に戻すために後で参照するため)。
        /// </summary>
        public static void ClearUpdateResult()
        {
            try { if (File.Exists(UpdateResultPath)) File.Delete(UpdateResultPath); }
            catch (Exception ex) { Logger.Warn("[UpdaterClient] .update_result の削除に失敗 (継続): " + ex.Message); }
        }

        /// <summary>
        /// (#440) 「前回のアップデートが未完了のまま残っているか」。
        ///
        /// 残っている失敗記録が**まだ有効か**をここで判断する。実行中の Manager が
        /// `TargetManagerVersion` に達していれば、その失敗は既に解消済み (手動で `Install.bat` を
        /// 実行して直した場合など) なので記録を消して false を返す。**時間ではなく事実で失効させる。**
        /// </summary>
        public static bool HasUnresolvedFailure()
        {
            UpdateRunResult result = TryLoadUpdateResult();
            if (result == null) return false;
            if (result.Success)
            {
                ClearUpdateResult();
                return false;
            }
            Version target;
            Version running = VersionInventory.ReadManagerVersion();
            if (running != null
                && !string.IsNullOrEmpty(result.TargetManagerVersion)
                && Version.TryParse(result.TargetManagerVersion, out target)
                && running >= target)
            {
                Logger.Info("[UpdaterClient] 前回の失敗記録は解消済みのため削除します (実行中 v"
                    + running + " >= 目標 v" + target + ")");
                ClearUpdateResult();
                return false;
            }
            return true;
        }

        /// <summary>
        /// (旧経路) Updater ログの末尾から成否を推測する。**`TryLoadUpdateResult` が使えないときだけ**
        /// 使う fallback (= 旧 Updater が書いた実行結果ファイルが無いケース)。
        ///
        /// 末尾 20 行に `[ERROR]` があれば失敗とみなすヒューリスティックで、致命的でない Error 行でも
        /// 失敗に倒れる。「どの実行の話か」が分からないため直近 2 分のログしか見ない。
        /// 新しい判定はすべて <see cref="TryLoadUpdateResult"/> を一次情報にすること (#440)。
        /// </summary>
        public static int? TryLoadLastExitCode()
        {
            string dir = PathManager.UpdaterLogDir;
            if (!Directory.Exists(dir)) return null;
            try
            {
                DateTime cutoff = DateTime.Now.AddMinutes(-2);
                FileInfo latest = null;
                foreach (string path in Directory.EnumerateFiles(dir, "updater_*.log"))
                {
                    var fi = new FileInfo(path);
                    if (fi.LastWriteTime < cutoff) continue;
                    if (latest == null || fi.LastWriteTime > latest.LastWriteTime) latest = fi;
                }
                if (latest == null) return null;
                // ログ末尾近辺に Run() の各 Step 結果 / 例外を Logger が書いている。
                // exit code 自体はログには直接書かない (return statement なので)、ただし「全工程完了」/
                // 「予期しない例外で abort」/ 「[Step X/4] ... abort」等の言い回しから推測可能。
                // (#108 Phase 4 round 1 H3 fix) 旧実装は 0 か null のみ返却で 1-8 失敗 dispatch path が
                // dead だった。defensive fallback: 末尾 20 行を scan して "Updater 全工程完了" 検出 → 0、
                // それ以外で `[FATAL]` / `[ERROR]` 含む行があれば「不明だが失敗」として 1 を返す
                // (DispatchExitCode(1) = "内部エラー、ログを確認" の汎用文言になり、少なくとも banner
                // 自体は表示される)。詳細な exit code 取得は将来 event-driven 通知 (= Updater spawn 時に
                // pipe 経由で exit code 受信) に置換予定、本 fallback は中間 measure。
                // (#108 Phase 4 round 3 M-4) 順方向 scan に変更。旧 backward scan は「全工程完了」を
                // 見つけた瞬間 return 0 する pattern だったが、log が `[早] 全工程完了 ... [遅] [ERROR]`
                // (= Logger.Shutdown 周辺で後続 ERROR が出る path) のケースで失敗を見落とす false negative
                // があった。順方向で `sawFailure` と `sawComplete` 両方を track、最終的に **failure 優先**
                // (= 後続 ERROR が出てれば成功 marker を上書きする) で判定。
                string[] lines = File.ReadAllLines(latest.FullName);
                int startIdx = Math.Max(0, lines.Length - 20);
                bool sawFailure = false;
                bool sawComplete = false;
                // (#108 Phase 4 round 5 L-3) `[20` literal prefix は 2100 年問題、regex で世紀非依存化。
                // (#108 Phase 4 round 8 L-7) `|FATAL` 分岐は dead code: Updater 側 Logger
                // (`Companions/Updater/Logger.cs`) は `Logger.Fatal(...)` API を持たず INFO/WARN/ERROR の
                // 3 レベルのみ。`Companions/Updater/FileReplacer.cs:260` の `Logger.Error("FATAL rollback: ...")`
                // は `[ERROR]` レベルで Message body に "FATAL" 文字列を含む形のため `[ERROR]` 部分が
                // 既にマッチして失敗判定に流れる。regex を `(ERROR)` に縮小して dead code 排除。
                // 将来 Updater 側に `Logger.Fatal` を追加する場合は本 regex を `(ERROR|FATAL)` に戻す
                // 対称同期 fence (Manager / Updater Logger の規約整合は SPEC §3.6 で管理)。
                var logLevelRegex = new System.Text.RegularExpressions.Regex(
                    @"^\[\d{4}-\d{2}-\d{2}.*\]\s*\[ERROR\]");
                for (int i = startIdx; i < lines.Length; i++)
                {
                    string line = lines[i];
                    if (line.Contains("Updater 全工程完了")) sawComplete = true;
                    // 行頭 Logger format prefix (`[YYYY-MM-DD HH:mm:ss] [LEVEL]`) を regex で確認、
                    // message 本文に偶然 `[ERROR]` 文字列を含む log line (例: `Logger.Info(
                    // "[FOO] mode=ERROR_RECOVERY")`) を false positive しないように anchor 厳密化。
                    if (logLevelRegex.IsMatch(line))
                    {
                        sawFailure = true;
                    }
                }
                if (sawFailure) return 1; // failure 優先
                if (sawComplete) return 0;
                return null;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Updater の exit code を user-facing なメッセージ + 推奨アクションに変換 (SPEC §3.7.4 dispatch 規約)。
        /// 8 種類の exit code それぞれに対応した user 向け文言を返す。
        /// </summary>
        public static ExitCodeDispatch DispatchExitCode(int exitCode)
        {
            switch (exitCode)
            {
                case 0:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Success,
                        Title = "アップデート完了",
                        Message = "アップデートに成功しました。",
                        SuggestedAction = ExitAction.NoOp,
                    };
                case 1:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Error,
                        Title = "内部エラー",
                        Message = "Updater で予期しない例外が発生しました。ログを確認の上、再試行してください。",
                        SuggestedAction = ExitAction.OpenLog,
                    };
                case 2:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Error,
                        Title = "内部 bug",
                        Message = "Updater の引数組立に失敗しました。本問題は開発側の bug です。GitHub Issue で報告してください。",
                        SuggestedAction = ExitAction.OpenIssueTracker,
                    };
                case 3:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Warn,
                        Title = "Manager が時間内に閉じませんでした",
                        Message = "Manager プロセスの終了待機が timeout しました。手動で Manager を閉じてから再試行するか、「強制終了して再試行」を選んでください。",
                        SuggestedAction = ExitAction.RetryWithForceKill,
                    };
                case 4:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Warn,
                        Title = "ファイル置換失敗",
                        Message = "ファイル置換に失敗しました (旧 Manager は復元済)。ディスク空き容量とアンチウイルスソフトの設定を確認してから再試行してください。",
                        SuggestedAction = ExitAction.Retry,
                    };
                case 5:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Critical,
                        Title = "致命的エラー (手動復旧要)",
                        Message = "rollback にも失敗しました。`.bak` フォルダから手動で復元する必要があります。ログをコピーして開発者に連絡してください。",
                        SuggestedAction = ExitAction.OpenLog,
                    };
                case 6:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Warn,
                        Title = "新 Manager 起動失敗",
                        Message = "新しい Manager が起動できませんでした (旧 Manager は復元済)。再試行で改善しない場合は Install.bat で再 install してください。",
                        SuggestedAction = ExitAction.Retry,
                    };
                case 7:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Error,
                        Title = "Manager 強制終了不能",
                        Message = "force-kill 試行が上限に達しました (権限不足等)。タスクマネージャから Manager を終了してから再試行してください。",
                        SuggestedAction = ExitAction.Retry,
                    };
                case 8:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Warn,
                        Title = "一時的な不調",
                        Message = "プロセス列挙が連続失敗しました (IPC / WMI 一時障害の可能性)。数分後に再試行してください。",
                        SuggestedAction = ExitAction.Retry,
                    };
                default:
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Error,
                        Title = "不明な exit code: " + exitCode,
                        Message = "Updater が想定外の exit code (" + exitCode + ") を返しました。ログを確認してください。",
                        SuggestedAction = ExitAction.OpenLog,
                    };
            }
        }

        /// <summary>
        /// Process.Start の Arguments 用に文字列を quote する (空白 path を扱う)。
        ///
        /// **既知の制約 (round 1 L1 + round 2 L13 + round 6 L-3)**: 内部 `"` の escape は
        /// `s.Replace("\"", "\\\"")` の簡易実装で、CommandLineToArgvW 厳密規約 (`\` ペアと `"` escape
        /// の interaction、preceding backslash 連続のとき偶数化が必要) は満たさない。現 caller は
        /// path 内 `"` を含まないため実害なし、規約準拠が必要になった場合は `Process.Start` の
        /// `ArgumentList` API (= .NET 5+、本 project 4.8 では未提供) 移行または自前 escape の整備が必要。
        /// </summary>
        private static string Quote(string s)
        {
            if (string.IsNullOrEmpty(s)) return "\"\"";
            // (#108 Phase 4 round 5 L-6 + round 6 L-1) trailing backslash defensive 正規化。`C:\foo\` を
            // quote すると `"C:\foo\"` → CommandLineToArgvW が末尾 `\"` を escaped quote と解釈して
            // 次の引数まで延長する known bug。caller が trailing backslash を含む path を渡しても
            // 安全に動くよう先に TrimEnd で剥がす。
            // **drive root 例外** (round 6 L-1): `C:\` → `C:` は path semantic が変わる (前者は root、
            // 後者は drive-relative cwd)。通常 dir では同等だが drive root だけは別物。現 caller
            // (StagingRootForUpdate / ManagerDir / Environment.ProcessPath / UpdaterLogDir) は drive root を
            // 渡さないため実害なし、将来 caller 追加時に注意。
            s = s.TrimEnd('\\');
            if (string.IsNullOrEmpty(s)) return "\"\"";
            // 既に quote 付きならそのまま、含まない場合は囲む
            if (s.Contains(" ") || s.Contains("\t"))
            {
                // 内部 quote の簡易 escape (= 上記 docstring の通り CommandLineToArgvW 厳密規約とは
                // 非互換、現 caller は path 内 `"` を含まないため簡易実装で十分)
                return "\"" + s.Replace("\"", "\\\"") + "\"";
            }
            return s;
        }
    }

    internal sealed class ExitCodeDispatch
    {
        public ExitSeverity Severity { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public ExitAction SuggestedAction { get; set; }
    }
    internal enum ExitSeverity { Success, Warn, Error, Critical }
    internal enum ExitAction { NoOp, Retry, RetryWithForceKill, OpenLog, OpenIssueTracker }
}
