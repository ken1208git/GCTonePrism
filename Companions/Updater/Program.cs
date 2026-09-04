using System;
using System.Diagnostics;
using System.IO;

namespace TonePrism.Updater
{
    /// <summary>
    /// TonePrism_Updater entry point.
    ///
    /// 責務 / Run() のステップ構成 (SPEC §3.7.4 minimum scope、round 7 Medium-2 で docstring と
    /// log ラベルを同期):
    ///   Step 0   : CLI 引数 parse (Main 内、log には出ない)
    ///   Step 0.5 : Logger 初期化 (Main 内、log には出ない)
    ///   Step 1/4 : Manager プロセス完全終了を polling 待機 (Run 内、`[Step 1/4]` log)
    ///   Step 2/4 : `Manager/` dir を rename-rollback 方式で置換 (Run 内、`[Step 2/4]` log)
    ///   Step 3/4 : 新 Manager.exe を起動 + early-crash check (Run 内、`[Step 3/4]` log)
    ///   Step 4/4 : `.bak` を best-effort 削除 (起動成功確認後、Run 内、`[Step 4/4]` log)
    ///   exit     : 自分終了 (return exit code)
    ///
    /// Manager UI 側 (§3.7.3 [4]〜[10]、Phase 4) が Launcher / Companions / shortcut bat / Updater 自身の
    /// 置換まで担当した後で本 Updater を spawn する。本 Updater は spawn 後に Manager が graceful 終了
    /// するのを待ち、自分自身が Manager 置換 + 再起動を行う。
    ///
    /// Exit codes (CliArgs.UsageText() / SPEC §3.7.4 / CHANGELOG `## Companions` `### [Updater v0.1.0]` (#160 で rename、旧 `## Updater`) / PR #152 body と
    /// **5 者同期**、round 4 H-1 + M-1 で 3 を 3/7/8 分割 + 1 追記、round 5 H-1 で 5 者同期を review
    /// 完了基準として固定化、round 6 Medium-1 で本 docstring の同期表記を「三者」→「5 者」に訂正):
    ///   0 = 成功
    ///   1 = 予期しない実行時例外 (Logger に stack trace 残る、運用上 bug report 対象)
    ///   2 = 引数エラー (必須引数不足 / path 解析失敗 / --restart-exe が --manager-target 外 等)。
    ///       **注**: parse 段階で発生するので Logger 未初期化、ログファイルには残らず stderr のみ
    ///       (SPEC §3.7.4「exit 2 はログファイル不在」規約、round 6 Medium-4)
    ///   3 = Manager プロセス終了 timeout (--force-kill 未指定、caller は --force-kill 付与か手動 close で再試行可能)
    ///   4 = ファイル置換失敗 (rollback 実施済、旧 Manager 復元)。auto-recovery 経路 (Codex round 2 P1 #3) も同 code
    ///   5 = rollback も失敗した致命的状態 (手動復旧必要、`.bak` から手動 rename)。新 Manager 起動失敗時の
    ///       RollbackFromBak も失敗した case を含む (round 6 Codex P1)
    ///   6 = 新 Manager.exe 起動失敗 (Process.Start null/throw、restart-exe 不在、spawn 直後 early-crash 等。
    ///       round 6 Codex P1 + Medium-5 で失敗時に RollbackFromBak で旧 Manager 復元)
    ///   7 = force-kill 試行 bounded retry (3 回) 超過 (permission denied 等の構造的問題、機械的再試行は無意味)
    ///   8 = process enumeration 連続失敗 (5 回、IPC/WMI 一時障害、短時間後の再試行に意味あり)
    /// </summary>
    internal static class Program
    {
        private static int Main(string[] args)
        {
            // round 7 Codex P2: parse 段階の stderr 出力 (exit 2 / parse-stage exit 1) を UTF-8 で
            // 出すため、`Console.OutputEncoding = UTF-8` を Main 冒頭 (Logger.Initialize **より前**)
            // で先行設定する。
            //
            // 旧実装は `Logger.Initialize` (Step 0.5) 内でしか UTF-8 を設定していなかったため、
            // parse 失敗 path (exit 2 / parse-stage exit 1) は Logger 初期化前に走り stderr が OS
            // default codepage (日本語 Windows = CP932) で出ていた。round 6 Medium-4 で SPEC §3.7.4
            // に「Phase 4 Manager UI は UTF-8 で stderr capture する規約」と書いたのに、その capture
            // 対象の stderr 自体が UTF-8 で出ていない自己矛盾 → Manager UI 側で mojibake する path。
            //
            // .NET の `Console.OutputEncoding` setter は内部的に `Console.Out` と `Console.Error`
            // 両方の encoding を変えるので 1 行で stderr もカバー。失敗時 (テスト環境で Console
            // redirect 等) は best-effort で swallow、CLI 動作には影響なし。
            try { Console.OutputEncoding = System.Text.Encoding.UTF8; } catch { /* best-effort */ }

            // ----- Step 0: 引数 parse -----
            CliArgs parsed;
            try
            {
                parsed = CliArgs.Parse(args);
            }
            catch (ArgumentException ex)
            {
                if (ex.Message == "HELP")
                {
                    Console.Out.WriteLine(CliArgs.UsageText());
                    return 0;
                }
                Console.Error.WriteLine($"[ERROR] 引数解析失敗: {ex.Message}");
                Console.Error.WriteLine();
                Console.Error.WriteLine(CliArgs.UsageText());
                return 2;
            }
            catch (Exception ex)
            {
                // round 6 Codex P2: parse 中の非 ArgumentException (`Path.GetFullPath` からの
                // `SecurityException` / `UnauthorizedAccessException` / `IOException` 等の権限・環境
                // 問題、または .NET runtime 内部の予期しない例外) を明示的に exit 1 (documented
                // exit codes) に倒す。旧実装は本 catch が無く CLR 既定の uncaught exception で
                // 異常終了 → Manager UI Phase 4 の retry/diagnostic 分岐が documented 0-8 と乖離した
                // 予期しない exit code を受ける silent danger があった。Logger 未初期化なので stack
                // trace はログファイルに残らず stderr のみ (SPEC §3.7.4 「exit 2 / 1 (parse 段階)
                // はログファイル不在」規約、round 6 Medium-4)。
                Console.Error.WriteLine($"[ERROR] 引数解析中に予期しない例外: {ex.GetType().Name}: {ex.Message}");
                Console.Error.WriteLine(ex.ToString());
                Console.Error.WriteLine();
                Console.Error.WriteLine(CliArgs.UsageText());
                return 1;
            }

            // ----- Step 0.5: Logger 初期化 -----
            // log-dir 未指定なら manager-target の親 dir / logs / updater を default に使う
            // (SPEC §3.7.4: `<install>/logs/updater/`、シニアレビュー round 1 M1 + L3 で
            //  UsageText / Logger fallback の三者一致に揃え直した。Program 側で最終 path を確定
            //  して Logger.Initialize に渡す方針。Logger.Initialize 内の exe-relative fallback は
            //  **通常運用では到達しない** が、drive root 病的入力等の極限ケース用に残してある
            //  ※ round 3 M5 で "到達不能" 表現を訂正。fallback は defensive、消さないこと)
            string logDir = parsed.LogDir;
            if (string.IsNullOrEmpty(logDir))
            {
                // CliArgs.Parse で ManagerTargetDir は GetFullPath 済み (絶対パス保証、M3)
                // なので親 dir 計算は通常成功。null になる極限ケース (drive root が manager-target
                // 等の病的入力) のみ Logger 側 fallback に流れる。
                string managerParent = Path.GetDirectoryName(parsed.ManagerTargetDir.TrimEnd('\\', '/'));
                if (!string.IsNullOrEmpty(managerParent))
                {
                    logDir = Path.Combine(managerParent, "logs", "updater");
                }
            }
            // finally で結果を書き出すため初期値が要る (Run が例外で抜けた場合も 1 = 汎用エラーとして残る)。
            int exitCode = 1;
            try
            {
                // (#440) Logger.Initialize も try の中に入れる。ここで throw すると (log dir の権限問題等)
                // finally を通らず実行結果が残らない = Manager 側から「何も起きなかった」ように見えてしまう。
                Logger.Initialize(logDir);
                exitCode = Run(parsed);
            }
            catch (Exception ex)
            {
                Logger.Error("予期しない例外で abort", ex);
                exitCode = 1;
            }
            finally
            {
                // (#440) 終了コードを消えない場所に残す。Manager は Updater の終了を待てない
                // (待つと dir を置換できない) ため、これが無いとログ解析で推測するしかなくなる。
                // Logger.Shutdown より前に呼ぶ (書き出し結果自体もログに残したいため)。
                //
                // **書き出せない経路が 3 つある**: `--help` (exit 0) / 引数 parse 失敗 (exit 2) /
                // parse 中の예 예外 (exit 1)。いずれも本 try より前に return しており、そもそも
                // `--manager-target` が読めていないので**書き込み先が決まらない**。
                // ただしその 3 つは Manager 側が渡す引数の不具合であり、かつ Manager dir は一切
                // 触られていないため、起動側の版数比較 (期待版数 != 実行中版数) が失敗を捉える
                // (原因欄が「原因不明」になるだけ)。判定が漏れることはない。
                UpdateResult.Write(parsed.ManagerTargetDir, parsed.StagingDir, exitCode);
                Logger.Shutdown();
            }
            return exitCode;
        }

        private static int Run(CliArgs args)
        {
            Logger.Info("============================================================");
            Logger.Info("TonePrism_Updater (Phase 3 minimal CLI)");
            Logger.Info("============================================================");
            Logger.Info($"  --staging         : {args.StagingDir}");
            Logger.Info($"  --manager-target  : {args.ManagerTargetDir}");
            Logger.Info($"  --restart-exe     : {args.RestartExe}");
            Logger.Info($"  --wait-timeout    : {args.WaitTimeoutSeconds}s");
            Logger.Info($"  --force-kill      : {args.ForceKill}");
            Logger.Info($"  --caller-pid      : {(args.CallerPid > 0 ? args.CallerPid.ToString() : "<未指定 = system-wide fallback>")}");
            Logger.Info("------------------------------------------------------------");

            // ----- Step 1: Manager プロセス終了待機 -----
            // round 4 H-1: ProcessWaiter は WaitResult enum を返すようになり、3 種の失敗
            // (timeout / force-kill 超過 / enumeration 失敗) を別 exit code に分岐できる。
            // Phase 4 Manager UI が再試行戦略を組む際に「再試行で直る (8)」「user 介入要 (3)」
            // 「構造的問題 (7)」を区別可能。
            Logger.Info("[Step 1/4] Manager プロセスの終了を待機");
            // round 8 Codex P2-1: PID 再利用検知に MainModule.FileName 検証を追加するため、
            // expected exe path として args.RestartExe を渡す (CliArgs で `--manager-target` 配下に
            // あることが round 4 M-3 で構造的に保証されているので、caller (Manager UI Phase 4) の
            // PID と RestartExe path の組が「自身の Manager.exe」を識別する key になる)。
            WaitResult waitResult = ProcessWaiter.WaitForManagerExit(args.WaitTimeoutSeconds, args.ForceKill, args.CallerPid, args.RestartExe);
            switch (waitResult)
            {
                case WaitResult.Success:
                    break;
                case WaitResult.TimedOutNoForceKill:
                    Logger.Error("Manager プロセスが timeout 内に終了せず (--force-kill 未指定)。--force-kill 付与か手動 close 後に再試行してください。");
                    return 3;
                case WaitResult.ForceKillExhausted:
                    Logger.Error("force-kill 試行が bounded retry 上限に達して abort。permission denied 等の構造的問題、機械的再試行では解決しません。");
                    return 7;
                case WaitResult.UnidentifiableTimeout:
                    // (#440) 生きているが同一性を確認できない Manager。「終了済みと誤判定して置換に進む」
                    // (静かなデータ不整合) と「永久に待つ」(管理ソフトが消えたまま戻らない) の両方を避け、
                    // Manager dir に触らずに降りる。exit 3 = user 介入経路 (手動 close 後に再試行) に倒す。
                    Logger.Error("Manager プロセスの同一性を確認できませんでした。データを壊さないため置換を中止します。管理ソフトを手動で閉じてから、もう一度お試しください。");
                    return 3;
                case WaitResult.EnumerationFailed:
                    Logger.Error("process enumeration が連続失敗で abort。IPC/WMI 一時不調の可能性、短時間後の再試行で回復するケースあり。");
                    return 8;
                default:
                    Logger.Error($"未知の WaitResult: {waitResult}");
                    return 1;
            }

            // ----- Step 2: Manager dir 置換 (Replace + restart-exe 検証 + CleanupBak) -----
            // シニアレビュー round 1 H1 対応: 旧実装は FileReplacer.Replace 内で .bak 削除まで
            // 行ってから restart-exe 検証していたため、release packaging bug 等で staging に新 exe
            // が無いケースで「旧 Manager 消失 + 新 Manager 不在」の復旧不能 broken state があった。
            // 修正: Replace は Step 1 (rename) + Step 2 (copy) のみ → restart-exe 存在検証 → OK なら
            // CleanupBak、NG なら RollbackFromBak で旧 Manager 復元。これで H1 silent path を閉じる。
            Logger.Info("[Step 2/4] Manager dir 置換 (rename-rollback)");
            bool replaced;
            try
            {
                replaced = FileReplacer.Replace(args.StagingDir, args.ManagerTargetDir);
            }
            catch (InvalidOperationException ex)
            {
                // rollback にも失敗した致命的状態
                Logger.Error($"FATAL: rollback failure", ex);
                return 5;
            }
            if (!replaced)
            {
                Logger.Error("ファイル置換失敗 (rollback で旧 Manager 復元済)");
                return 4;
            }

            // [Step 2 sub-validation] .bak 削除前に restart-exe が新 target に存在することを検証。
            // 不在なら旧 Manager を .bak から復元してから exit 6 (新 Manager 不在 + 旧 Manager 消失
            // の復旧不能 broken state を回避)。
            if (!File.Exists(args.RestartExe))
            {
                Logger.Error($"起動対象 exe が存在しません (staging に欠損か release packaging bug): {args.RestartExe}");
                Logger.Warn("旧 Manager を .bak から復元します...");
                try
                {
                    FileReplacer.RollbackFromBak(args.ManagerTargetDir);
                }
                catch (InvalidOperationException ex)
                {
                    Logger.Error($"FATAL: restart-exe 検証失敗後の rollback も失敗", ex);
                    return 5;
                }
                Logger.Warn("旧 Manager 復元完了。Install.bat 再実行で正しい staging から復旧してください。");
                return 6;
            }

            // round 6 Codex P1 + Medium-5 対応: `.bak` 削除は **新 Manager.exe の起動成功確認後** に
            // 移動 (旧実装は restart-exe 存在 check 後 / Process.Start 前で削除していたため、
            // Process.Start null/throw or spawn 直後 early-crash の各 path で「旧 Manager 消失 +
            // 新 Manager 起動失敗」の復旧不能 broken state を作る silent danger があった)。

            // ----- Step 3: 新 Manager.exe 起動 -----
            // round 4 M-2: Process.Start 戻り値 null check (起動が実体として走らなかった silent failure 排除)
            // round 6 Codex P1 + Medium-5: 起動失敗 (null / throw / early-crash) 時は RollbackFromBak で
            //   旧 Manager を復元 + exit 6。`.bak` は Step 4 (起動成功確認後) で削除。
            //
            // round 8 構造変更 (race condition 根治):
            //   round 7 test では 500ms WaitForExit が early-crash を検出したが、round 8 test 再実行で
            //   race condition (test dummy crasher の cold start が 500ms 以上かかる) で見逃した。
            //   原因は 2 層:
            //     [1] UseShellExecute=true: Windows shell 経由 spawn のため、Process オブジェクトと
            //         実 process の handle 紐付けが間接的、WaitForExit/HasExited の応答が遅延する path
            //         がある (.NET Framework 4.8 の公式ドキュメントでも UseShellExecute=true の場合
            //         WaitForExit の信頼性に制約あり)
            //     [2] 500ms threshold が borderline: csc cold start + 大きな .NET exe で実 race 範囲内
            //   両方を C 案で根治:
            //     [B] UseShellExecute=false に切替 → 直接 spawn、handle 紐付け確実、WaitForExit 安定
            //     [A] WaitForExit timeout を 500ms → 2000ms に拡大 → cold start race の確率的余裕
            //   副作用:
            //     - Manager.exe は GUI app なので stdout/stderr redirect なし inherit でも実害なし
            //       (Updater console は元々短命、Manager output が混じる懸念は実用上ゼロ)
            //     - 環境変数 / working dir inherit は default true で維持
            //     - SPEC §3.7.4 の round 4 M-5「UseShellExecute=true 経由 UAC prompt」記述は更新要
            //       (直接 spawn でも Manager.exe が requireAdministrator の場合 OS 既定の UAC prompt が
            //        出る仕組みは同じ、Manager は非 admin 前提も同じく維持)
            //     - Updater 完了が ~1.5 秒遅くなる (2000ms 待機)、ユーザー体験への影響は無視できる
            Logger.Info("[Step 3/4] 新 Manager.exe を起動");
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = args.RestartExe,
                    // round 8 C 案: UseShellExecute=true → false。handle 紐付け確実化で WaitForExit
                    // (= early-crash check) の信頼性を確保 (round 6 で導入した防御が race condition で
                    // 一部環境で機能しない silent danger を構造的に解消)。Manager.exe は GUI app
                    // (Application.Run loop) なので stdout/stderr inherit でも実害なし、stdin も
                    // 使わない、`.exe` 直接 spawn で問題なし。
                    UseShellExecute = false,
                    WorkingDirectory = Path.GetDirectoryName(args.RestartExe) ?? string.Empty
                };
                // round 5 M-4: 戻り値を using で wrap (handle leak 防止)。
                using (Process proc = Process.Start(psi))
                {
                    if (proc == null)
                    {
                        Logger.Error($"Process.Start が null を返却 (起動が実体として走らず、OS による起動抑止 等の可能性): {args.RestartExe}");
                        return RollbackAndReturn6(args.ManagerTargetDir, "Process.Start null");
                    }
                    // PID は best-effort で記録 (取得失敗しても起動自体は成功扱い)
                    int? pid = null;
                    // round 6 Low-3: bare catch を InvalidOperationException に絞る。
                    try { pid = proc.Id; }
                    catch (InvalidOperationException) { /* PID 取得不能、best-effort */ }
                    Logger.Info($"Manager spawn 成功 (PID={(pid.HasValue ? pid.Value.ToString() : "取得不能")})、early-crash check (2000ms)");

                    // early-crash check (round 8 C 案: 500ms → 2000ms)
                    bool earlyExited = false;
                    int? exitCode = null;
                    try
                    {
                        if (proc.WaitForExit(2000))
                        {
                            earlyExited = true;
                            try { exitCode = proc.ExitCode; }
                            catch (InvalidOperationException) { /* ExitCode 取得不能、HasExited だけ trust */ }
                        }
                    }
                    catch (InvalidOperationException)
                    {
                        // WaitForExit 自体不能 (極稀ケース) → false-positive 避けて生存とみなして続行
                        Logger.Warn("early-crash check 不能 (handle access 不可)、生存とみなして続行");
                    }

                    if (earlyExited)
                    {
                        Logger.Error($"新 Manager が spawn 直後に exit (ExitCode={(exitCode.HasValue ? exitCode.Value.ToString() : "取得不能")})。DLL load 失敗 / 即 crash 等の可能性");
                        return RollbackAndReturn6(args.ManagerTargetDir, "early-crash detected");
                    }
                    Logger.Info($"Manager 起動完了: {args.RestartExe} (early-crash check 通過、2000ms 生存確認)");
                }
            }
            catch (Exception ex)
            {
                Logger.Error($"Manager 起動失敗", ex);
                return RollbackAndReturn6(args.ManagerTargetDir, $"Process.Start throw: {ex.GetType().Name}");
            }

            // ----- Step 4: .bak 削除 (起動成功確認後、Codex P1 で round 6 で本位置に移動) -----
            // best-effort、失敗してもアップデート自体は成功扱い (.bak 残骸は手動削除 or 次回 Replace で
            // 自動掃除)。round 7 Medium-1 で log ラベル `[Step 4/4]` を明示追加 (Step ラベル系列を
            // 3/3 → 4/4 に揃え、docstring 責務 5 ステップとの不整合も解消)。
            Logger.Info("[Step 4/4] .bak を best-effort 削除");
            FileReplacer.CleanupBak(args.ManagerTargetDir);

            Logger.Info("============================================================");
            Logger.Info("Updater 全工程完了");
            Logger.Info("============================================================");
            return 0;
        }

        /// <summary>
        /// round 6 Codex P1 + Medium-5: Step 3 で Manager 起動失敗 (null / throw / early-crash) を
        /// 検出した場合に `.bak` から旧 Manager を復元するヘルパー。
        ///
        /// 失敗時の挙動:
        ///   - rollback 成功 → exit 6 (起動失敗、旧 Manager 復元済、次回 Updater spawn で正常 path)
        ///   - rollback も失敗 (致命的状態) → exit 5 (`.bak` から手動復元要、Logger に詳細記録済)
        /// </summary>
        private static int RollbackAndReturn6(string managerTargetDir, string reason)
        {
            Logger.Warn($"旧 Manager を .bak から復元します (理由: {reason})...");
            try
            {
                FileReplacer.RollbackFromBak(managerTargetDir);
                Logger.Warn("旧 Manager 復元完了。Manager UI 側で原因 (release packaging / runtime 依存欠落 等) を調査後、再度アップデートしてください。");
                return 6;
            }
            catch (InvalidOperationException ex)
            {
                Logger.Error($"FATAL: 起動失敗時の rollback も失敗 (`.bak` から手動復元要)", ex);
                return 5;
            }
        }
    }
}
