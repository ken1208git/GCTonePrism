using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace TonePrism.Updater
{
    /// <summary>
    /// `WaitForManagerExit` の戻り値 (round 4 H-1 対応)。
    /// 旧 `bool` 返しでは 3 種類の失敗 (timeout / force-kill bounded retry exhausted /
    /// enumeration 連続失敗) を全て同じ exit 3 に倒していたため、Phase 4 Manager UI が
    /// 再試行戦略を分岐実装する際に区別できなかった問題を解消。各失敗を別 exit code に
    /// マップするための切り分け enum。
    /// </summary>
    internal enum WaitResult
    {
        /// <summary>Manager プロセスが期待通り終了した (→ exit 0 経路)</summary>
        Success,
        /// <summary>timeout 経過 + `--force-kill` 未指定 (→ exit 3、caller は --force-kill 付与か手動 close で再試行可能)</summary>
        TimedOutNoForceKill,
        /// <summary>`--force-kill` 指定下で MaxForceKillAttempts (3 回) 連続で kill 失敗 (→ exit 7、permission denied 等の構造的問題、機械的再試行は無意味)</summary>
        ForceKillExhausted,
        /// <summary>process enumeration が MaxEnumerationFailures (5 回) 連続で throw (→ exit 8、IPC/WMI 一時障害、短時間後再試行に意味あり)。round 5 M-3 で「連続 N 回失敗の早期 abort path 専用」に限定、timeout 経路では使わない (両者排他)</summary>
        EnumerationFailed,
        /// <summary>
        /// (#440) Manager プロセスの**同一性を確認できない状態**が <see cref="UnidentifiedCapSeconds"/> 続いた
        /// (→ **exit 9**、user 介入経路へ倒す。exit 3 と分けるのは、3 の推奨アクション = 強制終了して再試行が
        /// この経路では必ず同じ所へ戻る行き止まりになるため)。
        ///
        /// 生きているが `MainModule` を読めないプロセス (権限差・AV による module 列挙阻害等) に当たると、
        /// 「終了済みと誤判定して置換に進む」(= #440 の静かなデータ不整合) と「永久に待つ」(= 管理ソフトが
        /// 消えたまま戻らない) の両方を避ける必要がある。**待たずに進むのも、無限に待つのも駄目**なので、
        /// 一定時間で諦めて Manager dir に触らずに降りる。呼び出し側は失敗として扱い、再試行できる。
        /// </summary>
        UnidentifiableTimeout,
    }

    /// <summary>
    /// Manager プロセスの完全終了を polling で待機する。
    ///
    /// SPEC §3.7.4 [責務 2]: Manager は Updater の **parent process (Updater を spawn した側)**。
    /// spawn 直後に graceful 終了を始めるが、.NET CLR の cleanup に数秒かかることがある。Updater
    /// 側は polling して結果が空になるまで待つ。timeout 経過後の挙動は --force-kill 引数で制御。
    /// (round 8 Low-3: 旧 docstring の「Manager は caller」表現を「parent process」に明示化、
    /// 「caller = この関数を呼ぶ側」と読まれる ambiguity を排除)
    ///
    /// 注: Launcher / 常駐 Companions の終了待機は **Manager UI 側の責務** (SPEC §3.7.3 [4]、Phase 4 で実装)。
    /// Updater は Manager のみを対象にする。
    ///
    /// **wait/kill 対象の決定** (Codex round 2 P1 #1 対応):
    ///   - `callerPid > 0` (Manager UI から `--caller-pid` 指定) → caller + 同一 install の Manager を wait/kill (#444)
    ///     (`Process.GetProcessById(pid)` で対象を絞る、同 PC の他 install Manager を巻き添えにしない)
    ///   - `callerPid == -1` (未指定) → system-wide fallback (`GetProcessesByName("TonePrism_Manager")`)
    ///     (round 1 L5 で acknowledged、校内 1 PC 1 install 前提なら実害なしの fallback)
    ///   Phase 4 で Manager UI が `Process.GetCurrentProcess().Id` を渡す前提。
    /// </summary>
    internal static class ProcessWaiter
    {
        private const string ManagerProcessName = "TonePrism_Manager";
        private const int PollIntervalMs = 500;
        // 待機継続ログを N iter ごとに 1 回出す (PollIntervalMs × LogEveryNIter = 実 interval)。
        // 名前付き定数化 (シニアレビュー round 2 L4) で「PollIntervalMs を変えるとログ間隔も連動して
        // 暗黙に変わる」silent magic number 連動を解消、変更時に意図して両方触る形に。
        // 現状: 500ms × 10 = 5 秒ごとログ。
        private const int LogEveryNIter = 10;
        // force-kill 試行回数の上限 (Codex round 2 P2 #2)。permission denied 等で kill が失敗し続けると
        // continue で無限ループ → Updater が hang する path があった。bounded retry で必ず終わらせる。
        private const int MaxForceKillAttempts = 3;
        // process enumeration 失敗の連続許容回数 (Codex round 2 P2 #4)。IPC / WMI 一時不調等での throw を
        // 空配列 fallback すると「Manager 既終了」誤判定 → Manager 生存中に置換に進む silent path に。
        // 連続 N 回まで「unknown state、待機継続」扱いにし、それ以降は abort。
        private const int MaxEnumerationFailures = 5;

        /// <summary>
        /// (#440) 「生きているが同一性を確認できない」状態を待つ上限 (秒)。これを超えたら
        /// <see cref="WaitResult.UnidentifiableTimeout"/> で降りる。
        ///
        /// **`--wait-timeout 0` (無制限) でもこの上限は効く。** Manager は通常経路で常に無制限を渡すため
        /// (`UpdaterClient`)、ここを timeout 任せにすると識別不能ケースで永久ループになる。Manager は既に
        /// 終了処理へ入っていて UI が無いので、ユーザーからは「管理ソフトが消えたまま何も起きない」に見える。
        ///
        /// **(レビュー 9) 既定 `--wait-timeout` (60s) より小さくしてある。** 同値だと、CLI から既定値で
        /// 走らせたとき識別不能の 60 秒と timeout の 60 秒のどちらが先に発火するかが「いつ識別不能に
        /// なったか」次第になる。timeout 側が勝つと exit 3 が返り、その案内 (`--force-kill` を付けて再試行)
        /// に従うと下の `forceKill && unidentified` ガードで必ず exit 9 に落ちる = 1 往復無駄になる。
        /// 小さくしておけば「識別不能の方が必ず先に判定される」を機械的に保証できる。
        /// (明示的にこの値未満の timeout を渡した場合は timeout が勝つが、それは呼び出し側の明示的な選択。
        ///  Manager は常に `--wait-timeout 0` を渡すので通常運用はどちらにせよ本上限のみが効く。)
        ///
        /// **この値を変えたら `CliArgs.UsageText` は自動追従する** (補間で参照済み) が、
        /// `Program` の docstring と SPEC §3.7.4 の exit 9 の行は手で直すこと (レビュー A-2)。
        /// </summary>
        internal const int UnidentifiedCapSeconds = 45;

        /// <summary>
        /// (#444) **caller は終了したのに、同一 install の他の Manager が残っている**状態を待つ上限 (秒)。
        ///
        /// #444 で「caller だけでなく同一 install の Manager を全部待つ」ようにしたが、Manager は
        /// 通常経路で `--wait-timeout 0` (無制限) を渡すため、**残った 2 個目が永久に閉じられないと
        /// Updater が永久に待つ**という新しい詰み方が生まれる。しかもその 2 個目が生きている典型的な
        /// 理由は「1 つだけ起動できます」の modal を誰も押していないことなので、放っておいても
        /// 閉じられない可能性が高い。caller (= 更新を始めた Manager) は既に終了していて画面が無いので、
        /// ユーザーからは「管理ソフトが消えたまま何も起きない」に見える — <see cref="UnidentifiedCapSeconds"/>
        /// を入れたのとまったく同じ理由で、ここにも上限が要る。
        ///
        /// 上限に達したら `TimedOutNoForceKill` (exit 3) を返す。exit 3 の案内は
        /// 「手動で Manager を閉じてから再試行」で、この状況にそのまま当てはまる。
        ///
        /// caller 自身が残っている間はこの上限は効かない (caller は必ず終了するので待ってよい)。
        /// </summary>
        private const int OtherManagersCapSeconds = 120;

        /// <summary>
        /// Manager プロセスが全て終了するまで polling で待機する。
        /// </summary>
        /// <param name="timeoutSeconds">timeout 秒数 (0 で無制限)</param>
        /// <param name="forceKill">timeout 経過時に強制 kill するか</param>
        /// <param name="callerPid">caller Manager の PID (> 0 で同一 install モード、-1 で system-wide fallback、Codex round 2 P1 #1)</param>
        /// <param name="expectedExePath">同一 install 判定で MainModule.FileName と一致を要求する Manager.exe の絶対 path (round 8 Codex P2-1、同名 exe 別 install / session の PID 再利用検知に使用)</param>
        /// <returns>失敗種別を区別した <see cref="WaitResult"/> (round 4 H-1、旧 bool 返しから差し替え)。caller (Program.cs) が switch で exit code 0/3/7/8 に分岐する</returns>
        public static WaitResult WaitForManagerExit(int timeoutSeconds, bool forceKill, int callerPid, string expectedExePath)
        {
            var sw = Stopwatch.StartNew();
            int iter = 0;
            int forceKillAttempts = 0;
            int consecutiveEnumerationFailures = 0;
            var unidentifiedSince = new Stopwatch();
            var othersOnlySince = new Stopwatch();

            if (callerPid > 0)
            {
                Logger.Info($"同一 install モード: caller-pid={callerPid} + 同じ exe path から起動している Manager を wait/kill 対象にする (#444)");
            }
            else
            {
                Logger.Info($"system-wide モード: {ManagerProcessName}.exe 全て (--caller-pid 未指定、巻き添えリスクあり)");
            }

            while (true)
            {
                Process[] procs;
                bool enumerationFailed = false;
                bool unidentified = false;
                try
                {
                    // (#440) verboseLog: 識別不能の警告は待機継続ログと同じ間引き (500ms ごとに出すと
                    // 無限待機時にログが 2 行/秒で肥大する)。
                    procs = GetTargetProcesses(callerPid, expectedExePath, iter % LogEveryNIter == 0, out unidentified);
                    consecutiveEnumerationFailures = 0;  // 成功で reset
                }
                catch (Exception ex)
                {
                    consecutiveEnumerationFailures++;
                    Logger.Warn($"process enumeration 失敗 ({iter} iter、連続 {consecutiveEnumerationFailures} 回): {ex.Message}");
                    procs = new Process[0];
                    enumerationFailed = true;
                    if (consecutiveEnumerationFailures >= MaxEnumerationFailures)
                    {
                        Logger.Error($"process enumeration が連続 {MaxEnumerationFailures} 回失敗、abort");
                        return WaitResult.EnumerationFailed;
                    }
                }

                try
                {
                    // Codex round 2 P2 #4: enumeration 失敗時は「unknown state」扱い、空配列を Manager 既終了
                    // と誤判定しないよう、待機継続経路に流す (timeout 経過で fail)。
                    if (!enumerationFailed && procs.Length == 0)
                    {
                        if (iter > 0)
                        {
                            Logger.Info($"Manager プロセス終了確認 ({sw.Elapsed.TotalSeconds:F1}s 経過)");
                        }
                        else
                        {
                            // シニアレビュー round 1 L1: 初回 polling で既に終了済の場合もログを残す
                            Logger.Info("Manager プロセスは既に終了済み、待機 skip");
                        }
                        return WaitResult.Success;
                    }

                    if (!enumerationFailed)
                    {
                        if (iter == 0)
                        {
                            // round 6 Low-2: `--wait-timeout 0 = 無制限待機` は UsageText / XML doc /
                            // SPEC §3.7.4 で公式仕様化済だが、ランタイムログには反映されておらず
                            // 「timeout 0s」と表示されると「0 秒待ち = 即 timeout」と誤読される
                            // 可能性。三項演算で表記分岐。
                            string timeoutDisplay = timeoutSeconds == 0 ? "無制限" : $"{timeoutSeconds}s";
                            Logger.Info($"Manager プロセス {procs.Length} 件検出、終了待機 (timeout {timeoutDisplay})");
                        }
                        else if (iter % LogEveryNIter == 0)
                        {
                            Logger.Info($"...待機継続中 ({sw.Elapsed.TotalSeconds:F1}s 経過、{procs.Length} 件残存)");
                        }
                    }

                    // (#444) caller は終了したのに同一 install の他の Manager が残っている状態の上限。
                    // 通常経路は `--wait-timeout 0` (無制限) なので、下の timeout 判定では拾えない。
                    if (!enumerationFailed && callerPid > 0 && procs.Length > 0 && !ContainsPid(procs, callerPid))
                    {
                        if (!othersOnlySince.IsRunning) othersOnlySince.Restart();
                        if (othersOnlySince.Elapsed.TotalSeconds >= OtherManagersCapSeconds)
                        {
                            Logger.Error($"更新を始めた Manager は終了しましたが、同じ install の別の Manager が"
                                + $" {OtherManagersCapSeconds} 秒経っても残っています。"
                                + " 起動中のまま置換に進むとデータが不整合になるため、Manager dir には触らずに中止します"
                                + " (「Manager は 1 つだけ起動できます」の小窓が他のウィンドウの裏に隠れていないか"
                                + " 確認し、すべての管理ソフトを閉じてからもう一度お試しください)");
                            return WaitResult.TimedOutNoForceKill;
                        }
                    }
                    else
                    {
                        othersOnlySince.Reset();
                    }

                    // (#440) 「生きているが同一性を確認できない」状態の上限。**timeout 判定より先に見る** —
                    // 通常経路は `--wait-timeout 0` (無制限) なので、下の timeout 判定はこのケースを拾えない。
                    if (unidentified)
                    {
                        if (!unidentifiedSince.IsRunning) unidentifiedSince.Restart();
                        if (unidentifiedSince.Elapsed.TotalSeconds >= UnidentifiedCapSeconds)
                        {
                            Logger.Error($"Manager プロセスの同一性を {UnidentifiedCapSeconds} 秒間確認できませんでした。"
                                + " 起動中のまま置換に進むとデータが不整合になるため、Manager dir には触らずに中止します"
                                + " (管理ソフトを手動で閉じてから、もう一度お試しください)");
                            return WaitResult.UnidentifiableTimeout;
                        }
                    }
                    else
                    {
                        unidentifiedSince.Reset();
                    }

                    if (timeoutSeconds > 0 && sw.Elapsed.TotalSeconds >= timeoutSeconds)
                    {
                        if (forceKill && unidentified)
                        {
                            // **(レビュー A-3) 出荷される 2 設定では到達しない防御コード。**
                            // 上の UnidentifiedCapSeconds 判定が timeout 判定より前にあり、Manager が渡すのは
                            // `--wait-timeout 0` (通常) か既定 60s (force-kill 経路) のどちらかなので、
                            // 前者はこの分岐に入らず、後者は 45s で先に exit 9 へ降りる。
                            // それでも残すのは、将来 `--force-kill` の配線や上限値を変えたときの防波堤のため。
                            // 「dead では？」で消さないこと。
                            //
                            // (#440) 同一性を確認できていないプロセスは **kill しない**。ここを kill すると
                            // 「同名 exe の別 install / 別権限の Manager を巻き添えで落とす」という、
                            // path 検証がまさに防いでいる事故が読み取り不能ケースについてだけ復活する。
                            // user 介入経路 (手動で閉じてから再試行) へ倒す。
                            Logger.Error("timeout 経過。ただし Manager プロセスの同一性を確認できていないため"
                                + " force-kill しません (別 install を巻き添えにしないため)。"
                                + " 管理ソフトを手動で閉じてから、もう一度お試しください");
                            return WaitResult.UnidentifiableTimeout;
                        }
                        if (forceKill && !enumerationFailed)
                        {
                            forceKillAttempts++;
                            if (forceKillAttempts > MaxForceKillAttempts)
                            {
                                // Codex round 2 P2 #2: bounded retry 超過で abort、無限ループ防止
                                Logger.Error($"force-kill 試行が {MaxForceKillAttempts} 回連続で残存プロセスを終了できず、abort");
                                return WaitResult.ForceKillExhausted;
                            }
                            Logger.Warn($"timeout {timeoutSeconds}s 経過、force-kill 試行 {forceKillAttempts}/{MaxForceKillAttempts}: Manager プロセスを強制終了します ({procs.Length} 件)");
                            KillAll(procs);
                            // kill 後 1 秒待って再 check
                            Thread.Sleep(1000);
                            // round 8 Low-1: continue で while ループ底の `Thread.Sleep + iter++` を skip
                            // するため、明示的に iter++ を実行 (ログ表記の重複防止、round 5 M-2 / Low-2
                            // のログ表記精度との整合)。
                            iter++;
                            continue;
                        }
                        else
                        {
                            // round 5 M-3: timeout 経路は **常に** TimedOutNoForceKill (exit 3) を返す。
                            //
                            // round 4 H-1 では「timeout 時に enumerationFailed なら EnumerationFailed
                            // (exit 8)」と分岐していたが、`enumerationFailed` 単独 (1 回でも失敗) で exit 8
                            // を返すと「偶発的 1 回失敗 + timeout コインシデンス」が exit 8 になり、Phase 4
                            // Manager UI が「短時間後再試行する価値あり」と誤判定 → 同じ timeout で再度
                            // exit 8 → 無限ループ化する path があった (round 5 M-3)。
                            //
                            // 修正方針: timeout 経路は常に TimedOutNoForceKill (exit 3) で、user 介入経路
                            // (--force-kill 付与 or 手動 close 後 retry) に倒す。EnumerationFailed (exit 8)
                            // は **`consecutiveEnumerationFailures >= MaxEnumerationFailures` の早期 abort
                            // path 専用** に限定 (line 100 付近)、両者排他。
                            string reason = enumerationFailed ? "enumeration 失敗中" : $"{procs.Length} 件残存";
                            Logger.Error($"timeout {timeoutSeconds}s 経過 ({reason})。--force-kill 未指定 or enumeration 失敗のため中止。");
                            return WaitResult.TimedOutNoForceKill;
                        }
                    }
                }
                finally
                {
                    foreach (var p in procs)
                    {
                        try { p.Dispose(); } catch { }
                    }
                }

                Thread.Sleep(PollIntervalMs);
                iter++;
            }
        }

        /// <summary>
        /// 待機対象の Manager プロセスを解決する。
        ///
        /// **`--caller-pid` 指定時でも caller だけを見ない (2026-09-04 の本番事故)。** 同じ install から起動して
        /// いる Manager が他にもあれば、それも待機対象に含める。実際に本番で
        /// 「2 個目の Manager が『1 つだけ起動できます』の modal を出したまま生きていて、caller だけを
        ///  待った Updater が Manager dir の rename でアクセス拒否になる」事故が起きた。
        ///
        /// caller PID だけを見る設計 (round 2 P1 #1) は **他 install を巻き添えにしない**ためのもので、
        /// 「同一 install の別プロセスを無視してよい」という意味ではなかった。exe path 一致で絞れば
        /// 巻き添えリスクは増えないまま、この穴だけ塞げる。
        /// </summary>
        private static Process[] GetTargetProcesses(int callerPid, string expectedExePath, bool verboseLog, out bool unidentified)
        {
            unidentified = false;
            if (callerPid <= 0)
            {
                // system-wide fallback
                return Process.GetProcessesByName(ManagerProcessName);
            }

            var targets = new List<Process>();
            bool anyUnidentified = false;
            bool u;

            // [A] caller 自身。GetProcessById は対象不在で ArgumentException (= 終了済 = 期待状態)。
            Process caller = null;
            try { caller = Process.GetProcessById(callerPid); }
            catch (ArgumentException) { /* PID 不在 = 終了済 (期待状態)、caller は null のまま */ }
            if (caller != null)
            {
                // caller は **自分が起動した Manager** なので、path を読めなくても待つ (#440)。
                if (IsSameInstallManager(caller, callerPid, expectedExePath, verboseLog,
                        treatUnreadablePathAsMatch: true, unidentified: out u))
                {
                    anyUnidentified |= u;
                    targets.Add(caller);
                }
                else
                {
                    try { caller.Dispose(); } catch { }
                }
            }

            // [B] 同じ install から起動している **caller 以外の** Manager。
            //
            // (レビュー Medium-1) **ここでの列挙失敗は握り潰さない。** 通常経路では caller は既に
            // 終了していて [A] は空なので、握り潰すと targets が空 = 「Manager は既に終了済み」→
            // WaitResult.Success に落ち、#444 で塞いだ穴が enumeration 失敗時にそのまま復活する。
            // 例外は呼び出し元へ抜けて consecutiveEnumerationFailures に積まれ、連続 5 回で exit 8
            // (= 一時障害、短時間後の再試行で回復見込み) になる — caller 側の失敗と同じ扱い。
            Process[] others = Process.GetProcessesByName(ManagerProcessName);
            foreach (Process o in others)
            {
                int otherPid;
                try { otherPid = o.Id; }
                catch (Exception) { try { o.Dispose(); } catch { } continue; }

                if (otherPid == callerPid) { try { o.Dispose(); } catch { } continue; }

                // (レビュー High-2) **caller 以外は path を確認できたものだけ対象にする。**
                // caller の「識別できないなら待つ」(#440) は *自分の* Manager だから正しいが、
                // caller 以外では risk profile が逆転する — 他 install / 他 user session の Manager は
                // MainModule が access denied で読めないため、待つ側に倒すと `unidentified` が立ち、
                // **無関係なプロセス 1 つで更新が exit 9 で中止される**。「path 一致で絞るので巻き添え
                // リスクは増えない」という本 PR の主張も、読めない経路では成立していなかった。
                if (IsSameInstallManager(o, otherPid, expectedExePath, verboseLog,
                        treatUnreadablePathAsMatch: false, unidentified: out u))
                {
                    anyUnidentified |= u;
                    if (verboseLog)
                    {
                        Logger.Warn("PID=" + otherPid + " も同じ install の Manager です (caller=" + callerPid + " 以外)。"
                            + " これも終了を待ちます — 待たずに進むと Manager dir の rename が"
                            + " アクセス拒否になります (2026-09-04 の本番事故)");
                    }
                    targets.Add(o);
                }
                else
                {
                    try { o.Dispose(); } catch { }
                }
            }

            unidentified = anyUnidentified;
            return targets.ToArray();
        }

        /// <summary>
        /// そのプロセスが「**この install の** Manager」かを判定する。
        ///
        /// 2 段の識別検証を行う:
        ///   1. **ProcessName 検証** (round 3 H1): Windows は exit 済プロセスの PID を再利用する。
        ///      caller が Updater spawn 直後に exit → OS が同 PID を別プロセス (例: notepad) に割当 →
        ///      `GetProcessById` がそれを返して Manager と誤認 → `--force-kill` 時に kill する danger。
        ///      `ProcessName == "TonePrism_Manager"` で「異名 exe による PID 再利用」を排除する。
        ///   2. **MainModule.FileName 検証** (round 8 Codex P2-1): ProcessName だけでは「**同名** exe
        ///      (= 同 PC 別 install / 別 session の Manager)」を区別できない。`expectedExePath`
        ///      (Program.cs が `--restart-exe` を渡す) と比較して install 単位で識別する。
        ///      `expectedExePath` が null/empty なら本検証は skip (後方互換)。
        ///
        /// <paramref name="treatUnreadablePathAsMatch"/> が **path を読めなかったときの倒し方**を決める。
        ///   - `true` (caller 用): 待機対象に含め、<paramref name="unidentified"/> を立てる。
        ///     「識別できない」を「終了済み」と読むと起動中の Manager dir を置換しに行って静かな
        ///     データ不整合を作る (#440 の根本原因そのもの)。無限には待たず caller 側が
        ///     <see cref="UnidentifiedCapSeconds"/> で打ち切る。
        ///   - `false` (caller 以外用、レビュー High-2): **対象外にする。** 他 install / 他 user session の
        ///     Manager は access denied で path を読めないので、待つ側に倒すと無関係なプロセス 1 つで
        ///     更新が exit 9 で中止される。caller と違って「自分の Manager である保証」が無い以上、
        ///     読めないものは他人のものとして扱う方が正しい。
        ///
        /// 識別できていないプロセスは**いずれの場合も kill 対象には入れない** (別 install の巻き添え防止、
        /// SPEC §3.7.6.1)。
        /// </summary>
        private static bool IsSameInstallManager(Process p, int pid, string expectedExePath, bool verboseLog,
            bool treatUnreadablePathAsMatch, out bool unidentified)
        {
            unidentified = false;

            // [1] ProcessName 検証 (PID 再利用での異名 exe 誤認防止、round 3 H1)。
            // `.exe` 拡張子は ProcessName には含まれないので比較値は "TonePrism_Manager"。
            string actualName;
            try { actualName = p.ProcessName; }
            catch (InvalidOperationException) { return false; }  // アクセス中に exit = 終了済と同じ扱い
            if (!string.Equals(actualName, ManagerProcessName, StringComparison.OrdinalIgnoreCase))
            {
                if (verboseLog) Logger.Info("PID=" + pid + " は別プロセス '" + actualName + "' (PID 再利用と判定)、対象外");
                return false;
            }

            // [2] MainModule.FileName 検証 (round 8 Codex P2-1、同名 exe 別 install / session 識別)。
            // expectedExePath 未指定時は path 検証なし (caller が渡さない場合の後方互換、
            // 現状 Program.cs は常に `--restart-exe` を渡す)。
            if (string.IsNullOrEmpty(expectedExePath)) return true;

            string actualPath;
            try
            {
                // .NET Framework 4.8 で MainModule は 32-64 bit cross-platform / access denied 等で
                // 例外を投げうる: Win32Exception (access denied / 32-64 mismatch)、
                // InvalidOperationException (process exited)、NotSupportedException (rare)。
                actualPath = p.MainModule != null ? p.MainModule.FileName : null;
            }
            catch (Exception ex) when (ex is System.ComponentModel.Win32Exception
                                    || ex is NotSupportedException)
            {
                // **「識別できない」を「終了済み」と読んではいけない** (#440)。
                //
                // 旧実装はここで空配列を返し、Manager が動いたままでも「既に終了済み」として
                // 待機を skip していた。その結果 Manager dir の rename がアクセス拒否で失敗し、
                // ロールバックして「内部エラー」になる — しかも Launcher / CHANGELOG は先に
                // 置換済みなので、**Manager だけ古いまま「最新版を実行中」と表示される**
                // 静かな不整合に落ちる。実際に Bundle v0.9.0 以降ずっとこれが起きていた。
                //
                // 判定を諦める方向の「安全側」は kill の話であって、待機の話ではない。
                // ここまでで ProcessName の一致は確認済みなので、**同名プロセスが生きている
                // 以上は待つ**方に倒す。無限には待たず UnidentifiedCapSeconds で打ち切る。
                if (!treatUnreadablePathAsMatch)
                {
                    // (レビュー High-2) caller 以外。他 install / 他 user session の可能性があり、
                    // 待つ側に倒すと無関係なプロセスで更新が止まる。対象外にする。
                    if (verboseLog)
                    {
                        Logger.Info("PID=" + pid + " の MainModule を読めませんでした (" + ex.Message + ")。"
                            + " caller ではないため同一 install と確認できず、待機対象から外します");
                    }
                    return false;
                }
                unidentified = true;
                if (verboseLog)
                {
                    Logger.Warn("PID=" + pid + " の MainModule を読めませんでした (" + ex.Message + ")。"
                        + " プロセス名は一致しているため Manager が起動中とみなして待機します"
                        + " (同一性を確認できていないので kill 対象にはしません)。"
                        + " Updater が 32bit で動いている場合はこの経路に入ります (#440)");
                }
                return true;
            }
            catch (InvalidOperationException)
            {
                // アクセス中にプロセス exit → 期待状態
                return false;
            }

            if (actualPath == null)
            {
                // (レビュー Medium-2) `MainModule` は例外を投げずに **null を返すこともある**。
                // これを path 比較に流すと「別 path 'null'」= 別 install と判定され、
                // #440 と同じ「識別できない」を「終了済み」と読む挙動が残る。
                if (!treatUnreadablePathAsMatch)
                {
                    if (verboseLog)
                    {
                        Logger.Info("PID=" + pid + " の MainModule が null でした。"
                            + " caller ではないため同一 install と確認できず、待機対象から外します");
                    }
                    return false;
                }
                unidentified = true;
                if (verboseLog)
                {
                    Logger.Warn("PID=" + pid + " の MainModule が null でした。"
                        + " プロセス名は一致しているため Manager が起動中とみなして待機します"
                        + " (同一性を確認できていないので kill 対象にはしません)");
                }
                return true;
            }

            if (!string.Equals(actualPath, expectedExePath, StringComparison.OrdinalIgnoreCase))
            {
                if (verboseLog) Logger.Info("PID=" + pid + " は同名 exe だが別 path '" + actualPath + "' (期待: '" + expectedExePath + "')、別 install / session と判定、対象外");
                return false;
            }
            return true;
        }

        /// <summary>指定 PID が配列に含まれるか。`Id` アクセス中の例外は「含まれない」に倒す。</summary>
        private static bool ContainsPid(Process[] procs, int pid)
        {
            foreach (Process p in procs)
            {
                try { if (p.Id == pid) return true; }
                catch (Exception) { /* 列挙中に exit 等。含まれない扱い */ }
            }
            return false;
        }

        private static void KillAll(Process[] procs)
        {
            foreach (var p in procs)
            {
                try
                {
                    if (!p.HasExited)
                    {
                        Logger.Info($"  kill PID={p.Id}");
                        p.Kill();
                    }
                }
                catch (Exception ex)
                {
                    Logger.Warn($"  kill PID={p.Id} 失敗: {ex.Message}");
                }
            }
        }
    }
}
