using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// Launcher / Companion プロセスの検出 + 待機 + (最終手段の) kill。Phase 4 (#108) の Manager UI が
    /// 置換前に呼ぶ。
    ///
    /// SPEC §3.7.3 [4] で「Launcher / 常駐 Companions 起動中なら閉じるよう案内」を Manager UI 側の責務と
    /// 定義。本 class は:
    ///   - <see cref="EnumerateRunning"/>: 起動中のプロセスをリストアップ (UI で「以下のプロセスを閉じてください」表示)
    /// のみを提供。手動 close を retry loop で促す UX (UpdateSectionPanel.btnUpdateNow_Click) に統一済。
    ///
    /// (#108 Phase 4 round 1 M5 fix) 旧版は `WaitForExit` / `KillAll` も持っていたが、UI 側から呼ばれる
    /// 配線がなく、`UpdaterClient.Spawn` の `forceKill` 引数も常に false 固定だったため dead code 化
    /// していた。docstring と実装の乖離が「強制終了 path が動くように見える」誤読を生むため削除。
    /// 将来 `--force-kill` UI を Manager UI 側に配線する場合は本 class に再導入する。
    ///
    /// process name 判定は AGENTS.md「Naming Conventions」の `TonePrism_<Name>` 命名規約に従う:
    ///   - Launcher: "TonePrism_Launcher"
    ///   - Companion (Updater 以外): `<install>/Companions/<Name>/` の dir 名から「TonePrism_<Name>」を導出
    ///   - Updater 自身は Manager UI から終了対象にしない (Manager が自分で spawn する仕組み)
    /// </summary>
    internal static class ProcessTerminator
    {
        public const string LauncherProcessName = "TonePrism_Launcher";

        /// <summary>
        /// 置換対象プロセス (Launcher + Companions/Updater 以外) で起動中のものを返す。
        /// 各 dir に対応する exe が起動中なら ProcessInfo を 1 件含める。
        /// </summary>
        public static IReadOnlyList<RunningProcessInfo> EnumerateRunning()
        {
            var list = new List<RunningProcessInfo>();

            // Launcher
            AppendIfRunning(list, LauncherProcessName, "Launcher");

            // 自分以外の Manager (2026-09-04 の本番事故)
            AppendOtherManagers(list);

            // Companions (Updater 以外)
            if (Directory.Exists(PathManager.CompanionsDir))
            {
                foreach (string companionDir in SafeEnumerateDirectories(PathManager.CompanionsDir))
                {
                    string name = Path.GetFileName(companionDir.TrimEnd('\\', '/'));
                    if (string.IsNullOrEmpty(name)) continue;
                    if (string.Equals(name, "Updater", StringComparison.OrdinalIgnoreCase)) continue;
                    string procName = "TonePrism_" + name;
                    AppendIfRunning(list, procName, "Companion: " + name);
                }
            }
            return list;
        }

        /// <summary>
        /// **自分以外の Manager プロセス**を検出する (2026-09-04 の本番事故)。
        ///
        /// 2 個目の Manager を起動すると、単一起動チェックに引っかかって
        /// 「Manager は 1 つだけ起動できます」の modal が出る。**この modal は OK を押すまで閉じず、
        /// その間そのプロセスは生きたまま `Manager/` 配下の exe / dll を掴み続ける。**
        /// 本番ではこの 2 個目が裏に隠れたまま 2 分 42 秒生き残り、Updater の
        /// `Manager` → `Manager.bak` rename がアクセス拒否になって更新が失敗した。
        ///
        /// Updater 側でも同じ install の Manager を全部待つように直したが (ProcessWaiter)、
        /// **更新を始める前に気付いて閉じてもらう方が早い**ので両方で塞ぐ。
        ///
        /// **対象は「自分と同じ exe path から起動している Manager」だけ** (置換されるのは自分の install の
        /// dir だけなので、別 install の Manager を閉じさせる理由が無い)。
        ///
        /// (レビュー Medium-2) **path を読めなかったプロセスは数えない。** 呼び出し側
        /// (`UpdateSectionPanel.btnUpdateNow_Click`) はリストが空になるまで Retry/Cancel を回すループで、
        /// 「無視して続行」の出口が無い。つまり false positive は「更新が二度と始められない」に直結する。
        /// 他 user session の Manager は `MainModule` が access denied で読めないので、読めないものまで
        /// 数えると**見えないウィンドウを閉じろと言われて詰む**。実際に塞ぎたい #444 のケース
        /// (同一ユーザー・同一 install の 2 個目) では path は問題なく読めるし、読めなかった場合も
        /// Updater 側が待機と 120 秒上限 (exit 3) で拾うので、ここは false positive を避ける側に倒す。
        ///
        /// 自分の path は `AppContext.BaseDirectory` から組み立てる (`MainModule` 経由だと自分自身の
        /// 読み取りに失敗したときに全 Manager を数えてしまい、上記の詰みを招く)。
        /// </summary>
        private static void AppendOtherManagers(List<RunningProcessInfo> list)
        {
            const string managerProcessName = "TonePrism_Manager";
            int count = 0;
            try
            {
                int selfPid;
                using (Process self = Process.GetCurrentProcess())
                {
                    selfPid = self.Id;
                }
                // 自分の exe path。MainModule と違い例外経路が無い。
                string selfExe = Path.Combine(AppContext.BaseDirectory, managerProcessName + ".exe");

                foreach (Process p in Process.GetProcessesByName(managerProcessName))
                {
                    try
                    {
                        if (p.Id == selfPid) continue;

                        string path = null;
                        try { path = p.MainModule != null ? p.MainModule.FileName : null; }
                        catch { path = null; }

                        // path を確認できたものだけ数える (上の docstring 参照)。
                        if (path == null) continue;
                        if (!string.Equals(path, selfExe, StringComparison.OrdinalIgnoreCase)) continue;

                        count++;
                    }
                    catch (Exception)
                    {
                        // 列挙中に exit した等。数えないだけで続行。
                    }
                    finally
                    {
                        try { p.Dispose(); } catch { }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Warn("[ProcessTerminator] 他の Manager プロセスの列挙に失敗 (チェックを skip): " + ex.Message);
                return;
            }

            if (count > 0)
            {
                list.Add(new RunningProcessInfo
                {
                    ProcessName = managerProcessName,
                    DisplayLabel = "Manager (この PC で開いている別のウィンドウ。"
                        + "「1 つだけ起動できます」の小窓が裏に隠れていないか確認してください)",
                    InstanceCount = count,
                });
            }
        }

        private static void AppendIfRunning(List<RunningProcessInfo> list, string processName, string displayLabel)
        {
            int count = CountRunning(processName);
            if (count > 0)
            {
                list.Add(new RunningProcessInfo
                {
                    ProcessName = processName,
                    DisplayLabel = displayLabel,
                    InstanceCount = count,
                });
            }
        }

        private static int CountRunning(string processName)
        {
            Process[] procs;
            try
            {
                procs = Process.GetProcessesByName(processName);
            }
            catch
            {
                return 0;
            }
            int n = procs.Length;
            foreach (var p in procs)
            {
                try { p.Dispose(); } catch { }
            }
            return n;
        }

        private static IEnumerable<string> SafeEnumerateDirectories(string root)
        {
            try
            {
                return Directory.EnumerateDirectories(root);
            }
            catch
            {
                return new string[0];
            }
        }
    }

    internal sealed class RunningProcessInfo
    {
        public string ProcessName { get; set; }
        public string DisplayLabel { get; set; }
        public int InstanceCount { get; set; }
    }
}
