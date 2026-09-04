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
            /// <summary>
            /// Updater の終了コード (0 = 成功)。**null は「ファイルはあるが値を読めなかった」**
            /// を意味する (JSON が壊れている / フィールドが無い)。`int` にすると欠落が 0 = 成功に
            /// 化けてしまうので nullable にしてある。
            /// </summary>
            public int? ExitCode { get; set; }
            /// <summary>この更新で入るはずだった Manager の FileVersion (読めなければ null)。</summary>
            public string TargetManagerVersion { get; set; }

            /// <summary>
            /// 成否。**`ExitCode` から導出する** — 同じ事実をファイルに 2 つ持たせない
            /// (食い違ったときどちらが正か決まらないため)。値を読めなければ null (= 不明)。
            /// </summary>
            public bool? Success
            {
                get { return ExitCode.HasValue ? (bool?)(ExitCode.Value == 0) : null; }
            }
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
        /// (#440) Updater が結果を残さずに終わった場合に、**Manager 側から失敗を記録する**。
        ///
        /// 申し送り (`.update_completed`) は読んだ時点で必ず消える一度きりの通知なので、これを書かないと
        /// 次回起動で判断材料が全部無くなり、「最新版を実行中」+ ボタン無効の袋小路に戻る
        /// (= #440 と同じ行き止まり)。申し送りを残す案は採らない — 手動で `Install.bat` から復旧しても
        /// 結果ファイルは生まれないため、直したのに永久に警告が出続けることになる。
        ///
        /// 状態の置き場所を `.update_result` 1 つに保てば、`targetManagerVersion` に版数が追いついた
        /// 時点で自動失効するので、手動復旧でも勝手に解消する。
        ///
        /// 終了コードは 1 (汎用エラー = 「内部エラー、ログを確認」) として記録する。Updater が実際の
        /// コードを残せなかった以上、原因は本当に分からない。
        /// </summary>
        public static void RecordFailureWithoutUpdaterResult(string targetManagerVersion)
        {
            try
            {
                string json = "{"
                    + "\"finishedAt\":\"" + DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", System.Globalization.CultureInfo.InvariantCulture) + "\","
                    + "\"exitCode\":1,"
                    + "\"targetManagerVersion\":" + (string.IsNullOrEmpty(targetManagerVersion) ? "null" : "\"" + targetManagerVersion + "\"")
                    + "}";
                File.WriteAllText(UpdateResultPath, json, new System.Text.UTF8Encoding(false));
                Logger.Info("[UpdaterClient] Updater が結果を残さなかったため、Manager 側で未完了を記録しました");
            }
            catch (Exception ex)
            {
                Logger.Warn("[UpdaterClient] 未完了の記録に失敗 (継続): " + ex.Message);
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
            if (!result.Success.HasValue)
            {
                // ファイルはあるが値を読めない。ここで「失敗」と決めつけると偽の警告を出すので、
                // 判定材料として使わず捨てる (呼び出し側は版数比較や従来の推測に倒れる)。
                Logger.Warn("[UpdaterClient] .update_result に終了コードがありません。判定材料として使いません");
                ClearUpdateResult();
                return false;
            }
            if (result.Success.Value)
            {
                ClearUpdateResult();
                return false;
            }
            Version target;
            Version running = VersionInventory.ReadManagerVersion();
            if (running != null
                && !string.IsNullOrEmpty(result.TargetManagerVersion)
                && Version.TryParse(result.TargetManagerVersion, out target)
                // **3-part で比べる。** running は AssemblyVersion、target は apphost の FileVersion で
                // SoT が違い、リリースゲートも 3-part までしか一致を強制しない。4-part だと revision の
                // drift で失効条件を満たせず、失敗記録が永久に残る (MainForm 側と粒度を揃える)。
                && CompareThreePart(running, target) >= 0)
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
        /// <summary>
        /// 版数を 3-part (major.minor.build) で比較する。revision は無視する。
        /// AssemblyVersion と FileVersion は SoT が違い、リリースゲートも 3-part までしか一致を
        /// 強制しないため、4-part で比べると revision drift だけで判定が壊れる。
        /// </summary>
        private static int CompareThreePart(Version a, Version b)
        {
            if (a.Major != b.Major) return a.Major.CompareTo(b.Major);
            if (a.Minor != b.Minor) return a.Minor.CompareTo(b.Minor);
            int ab = a.Build < 0 ? 0 : a.Build;
            int bb = b.Build < 0 ? 0 : b.Build;
            return ab.CompareTo(bb);
        }

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
                case 9:
                    // (#440 レビュー Medium) 「同一性を確認できないまま上限に達した」専用。
                    // exit 3 を再利用すると `RetryWithForceKill` が案内されるが、この経路は
                    // **同一性を確認できないプロセスを kill しない**方針なので、強制終了で再試行しても
                    // また同じところに戻る = 行き止まりループになる。#440 の教訓 (行き止まりを作らない)
                    // に反するため、force-kill を勧めない専用の案内に分ける。
                    return new ExitCodeDispatch
                    {
                        Severity = ExitSeverity.Warn,
                        Title = "Manager を確認できませんでした",
                        Message = "起動中の Manager を特定できなかったため、データを壊さないよう更新を中止しました。管理ソフトを手動で閉じてから、もう一度お試しください。",
                        SuggestedAction = ExitAction.Retry,
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
