using System;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using TonePrism.Manager.Models;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// (#179 / #178 (c)) 別の Manager / Launcher (他 PC または同一 PC) を検出した時に表示する modal dialog の context。
    /// </summary>
    internal enum SessionConflictDialogContext
    {
        /// <summary>Manager 起動時、`MainForm.Load` 冒頭で別の Manager / Launcher を検出した場合。Cancel = Manager 終了。</summary>
        Startup,
        /// <summary>編集操作前 (ゲーム追加/編集/削除、ストア編集、設定変更、Backup/Restore 等の DB write 直前)。Cancel = その操作を中止。</summary>
        EditOperation,
    }

    /// <summary>
    /// (#179 / #178 (c)) 別の Manager / Launcher (他 PC または同一 PC) を検出した時の modal 警告 dialog の SoT。
    ///
    /// 文言は **「データ破損」「競合」のような技術用語を避け、部員が「何が起きるか」を想像できる
    /// 具体表現** に統一 (「データが破損したり消えたりする恐れ」「別の Manager / Launcher を閉じてから」)。
    /// (#251) 「他 PC」前提の表現は撤回 — SPEC §3.8.7.6 のとおり同一 PC 上の Launcher も検出対象で
    /// 検出 list に自 PC が並ぶ case があるため、他 PC / 同一 PC どちらでも読める汎用文にする。
    /// `MessageBoxIcon.Stop` + `MessageBoxButtons.OKCancel` で「OK = 続行 (data 喪失 risk 承知)」/
    /// 「Cancel = 中止 (context に応じて Manager 終了 or その操作中止)」を user 判断に委ねる設計。
    ///
    /// 詳細仕様は SPECIFICATION.md §3.8 参照。
    /// </summary>
    internal static class SessionConflictDialog
    {
        /// <summary>
        /// 別の Manager / Launcher 検出時の dialog を表示。OK で続行、Cancel で abort。
        ///
        /// (#179 PR3b) Manager + Launcher の 2 系統検出を 1 dialog に merge 表示する設計。
        /// 検出 list は行毎に component 種別 (Manager / Launcher) を区別、最大 5 件 + 残件数要約は
        /// merge count で算出。caller (`MainForm`) は両 service から detect 結果を取り、本 method に
        /// 渡す。SPEC §3.8.7.4 参照。
        /// </summary>
        /// <param name="owner">
        /// 親 form (modal の親)。**可視の窓か <c>null</c> のどちらかを渡すこと (#449)。**
        /// 不可視の窓 (Opacity=0 / Hide 済の MainForm 等) を渡すと、所有ダイアログはタスクバー
        /// ボタンも Alt+Tab エントリも持たないため、z-order で下に潜ると前面に戻せなくなる。
        /// <c>null</c> なら top-level 窓になり必ず戻せる。
        /// </param>
        /// <param name="context">context (Startup / EditOperation) で文言切替。</param>
        /// <param name="managerOthers">検出した他 PC Manager session list (= self 除外、`ManagerSessionService.DetectOtherActiveSessions` の戻り値)。空 list 可、ただし `launcherOthers` と合算で 1 件以上が caller 契約。</param>
        /// <param name="launcherOthers">検出した active Launcher session list (PR3b 追加、= `LauncherSessionService.DetectActiveLauncherSessions` の戻り値)。**`managerOthers` と非対称で self-PC Launcher も含みうる** (SPEC §3.8.7.6、同 PC 上の Manager 編集 × Launcher SQLite read の競合も検出対象、安全側設計)。空 list 可。</param>
        /// <param name="operationDescription">EditOperation 時の操作名 (例: "ゲーム編集")、Startup 時は null。</param>
        /// <returns>user 選択 (DialogResult.OK / DialogResult.Cancel)。</returns>
        public static DialogResult Show(
            IWin32Window owner,
            SessionConflictDialogContext context,
            IReadOnlyList<ManagerSessionInfo> managerOthers,
            IReadOnlyList<LauncherSessionInfo> launcherOthers,
            string operationDescription = null)
        {
            // (round 5 L-4) 空 list / null の事前 guard は caller の contract に倒す:
            //   - `MainForm.CheckSessionConflictBeforeWrite`: `managerOthers.Count + launcherOthers.Count == 0` で early return
            //   - `MainForm_Load` startup check: 合算 Count > 0 内側でのみ呼出
            // 同 assembly internal sealed class で caller は grep で全数確認可能、defensive 二重を撤去。
            long nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            string detectedListLines = BuildMergedDetectedList(managerOthers, launcherOthers, nowMs);

            int totalCount = managerOthers.Count + launcherOthers.Count;

            // (round 2 High-1) MessageBox は markdown を解釈しないため `**...**` 等の強調記法は literal 表示
            // される。本文は plain text で OS button label (= 「OK」/「キャンセル」) と一貫させる。
            // (round 2 Medium-1) operationDescription が「ゲーム削除」「データベース初期化」等の場合に
            // 「{op} の内容と...」が日本語として grammatical に合わない問題を解消するため、template を
            // 「このまま {op} を実行すると...」の汎用文に統一 (op は名詞句のままで grammar 違和感なし)。
            // (round 8 L-3) 文言の semantic 修正: 「他 PC の **編集内容と** お互いに上書きされて消える」
            // は ゲーム編集 / Store 編集 / Settings 系には正しいが、「バックアップ作成」「バックアップ削除」
            // 「バックアップ復元」「バックアップ設定変更」では「他 PC の編集内容を上書きする」関係性が
            // 薄く文脈と乖離していた (= 13 callsite のうち 4 件 = BackupSection 3 + BackupSettings 1 が
            // 該当)。「他 PC の **作業と競合して** データ破損や保存内容の喪失が起きる恐れ」のように
            // 「上書き」「編集内容」依存を撤回した一般語に書換え、全 callsite で semantic と整合させる。
            // Startup 側も同方針 (= 「編集内容や バックアップが お互いに上書き」を「データや バックアップが
            // 競合して破損したり 消えたりする」に書換え)。
            // (#251) 上記引用の「他 PC の 作業と競合して」は #251 で「別の Manager / Launcher と競合して」へ
            // 更に汎用化済 (現行本文は Startup=L88-93 / EditOperation=L102-107 を参照)。
            string title;
            string body;
            if (context == SessionConflictDialogContext.Startup)
            {
                // (#179 PR3b) Startup title を「Manager / Launcher」の汎用形に書換え。
                // 旧 (PR #184) は「Manager が起動中」固定だったが、Launcher 検出も merge 表示するため
                // 「Manager / Launcher が稼働中」に汎用化、文言と検出 list を一致させる。
                // (#251) 「他 PC」前提を撤回: 同一 PC 上の Launcher も検出対象 (SPEC §3.8.7.6) で検出 list に
                // 自 PC 名が並ぶ case があるため、「別の Manager / Launcher」の汎用文に統一 (他 PC / 同一 PC
                // どちらでも正しく読める)。挙動 (Cancel = Manager 終了) は不変。
                title = "【危険】別の Manager / Launcher が稼働中です";
                body =
                    detectedListLines + "\n\n" +
                    "別の Manager や Launcher が動いたままこの Manager を使うと、保存中のデータや\n" +
                    "バックアップが競合して、データが破損したり消えたりする恐れがあります。\n\n" +
                    "「OK」を押す: このまま起動する (データが消える可能性を承知)\n" +
                    "「キャンセル」を押す: Manager を終了する (別の Manager / Launcher を閉じてから起動し直す)";
            }
            else
            {
                // (#251) EditOperation title/body も「他 PC」前提を撤回し Startup と同じ「別の Manager /
                // Launcher」汎用形に統一 (同一 PC 上の Launcher 検出で「他 PC で誰かが作業中」が噛み合わ
                // ない case を解消)。挙動 (Cancel = その操作中止) は不変。
                title = "【危険】別の Manager / Launcher が稼働中です";
                string opLabel = string.IsNullOrEmpty(operationDescription) ? "この操作" : operationDescription;
                body =
                    detectedListLines + "\n\n" +
                    "このまま " + opLabel + " を実行すると、\n" +
                    "別の Manager / Launcher と競合して、データが破損したり保存内容が消えたりする恐れがあります。\n\n" +
                    "「OK」を押す: このまま実行する (データが消える可能性を承知)\n" +
                    "「キャンセル」を押す: 実行を中止する (別の Manager / Launcher を閉じてから実行する)";
            }

            Logger.Warn("[SessionConflictDialog] " + context + " context で別の Manager / Launcher を検出 (Manager=" + managerOthers.Count + " Launcher=" + launcherOthers.Count + " total=" + totalCount + " 件) → dialog 表示");
            // (#179 PR3b round 3 L-2) 検出 PC の pc_name / pid を debug trail に embed。
            // 同 PC 検出時に「自 Process.Id と一致 → 自 PC Launcher」を log 解析で判定可能化。
            // dialog body (= user 視点) には pid は出さず (= 部員視点で意味なし)、log のみ。
            foreach (var info in managerOthers)
            {
                Logger.Info("[SessionConflictDialog]   - Manager: pc=" + info.PcName + " pid=" + info.Pid + " ver=" + info.ManagerVersion);
            }
            foreach (var info in launcherOthers)
            {
                Logger.Info("[SessionConflictDialog]   - Launcher: pc=" + info.PcName + " pid=" + info.Pid + " ver=" + info.LauncherVersion);
            }

            // (#186 round 3 確定) Startup context の taskbar entry 不在 / focus 喪失で見失う UI bug は
            // **caller (`MainForm_Load`) 側で `BeginInvoke` defer + `ContinueLoadAfterSessionCheck`
            // chain pattern を採用** することで解消。本 dialog 自身は標準 owner-modal MessageBox 呼出
            // に留め、Startup / EditOperation の文言切替のみが本関数の責務。
            //
            // 詳細 rationale (round 1 `MessageBoxOptions.DefaultDesktopOnly` 試行 → user feedback
            // 「常時最前面うざい」で撤回 / round 2 BeginInvoke defer のみ → reviewer High 指摘
            // 「gate → 事後通知 regression」で再修正 / round 3 chain pattern で gate 物理維持 +
            // taskbar entry 確保の両立) は `MainForm.MainForm_Load` 起動時 check 部の inline コメント
            // 参照。本 dialog 単独では「caller が owner Form を visible 状態で渡せば自然な owner-modal
            // child 挙動になる」前提のみが API contract。
            return MessageBox.Show(
                owner,
                body,
                title,
                MessageBoxButtons.OKCancel,
                MessageBoxIcon.Stop,
                MessageBoxDefaultButton.Button2 /* Cancel を default に倒して反射押下で続行する path を抑制 */);
        }

        private static string BuildMergedDetectedList(
            IReadOnlyList<ManagerSessionInfo> managerOthers,
            IReadOnlyList<LauncherSessionInfo> launcherOthers,
            long nowMs)
        {
            // (#179 PR3b) Manager + Launcher の検出結果を merge 表示。
            // 各行に component 種別 (Manager vX.Y.Z / Launcher vX.Y.Z) を区別して列挙、最大 5 件 +
            // 残件数要約は merge count。表示順は Manager → Launcher (= 既存 PR #184 の Manager 表示
            // を上に維持しつつ Launcher を後段に追加、user が「Manager 系の検出」を先に視覚的に確認)。
            //
            // (round 1 L-4 既存) version embed の意義: 「別の Manager / Launcher が古い version で開いている」
            // case を user が認知可能 (compatibility 警告の材料)、Launcher 側でも同 logic。
            var sb = new StringBuilder();
            sb.Append("検出した PC:");
            int totalCount = managerOthers.Count + launcherOthers.Count;
            const int maxShown = 5;
            int shown = 0;

            // Manager session を先に列挙
            for (int i = 0; i < managerOthers.Count && shown < maxShown; i++)
            {
                var info = managerOthers[i];
                int sec = info.SecondsSinceLastHeartbeat(nowMs);
                string version = string.IsNullOrEmpty(info.ManagerVersion) ? "(version 不明)" : "Manager v" + info.ManagerVersion;
                sb.Append("\n  - " + info.PcName + " (" + version + "、最終確認: " + sec + " 秒前)");
                shown++;
            }

            // Launcher session を後段に列挙 (= remaining quota の範囲で)
            for (int i = 0; i < launcherOthers.Count && shown < maxShown; i++)
            {
                var info = launcherOthers[i];
                int sec = info.SecondsSinceLastHeartbeat(nowMs);
                string version = string.IsNullOrEmpty(info.LauncherVersion) ? "(version 不明)" : "Launcher v" + info.LauncherVersion;
                sb.Append("\n  - " + info.PcName + " (" + version + "、最終確認: " + sec + " 秒前)");
                shown++;
            }

            if (totalCount > maxShown)
            {
                // (round 2 M-4) Manager → Launcher の表示順で 5 件 cap が共有されるため、Manager が 5 件
                // 以上検出された場合 Launcher が 0 件しか表示されない drift がある。残件数要約に
                // component 内訳を embed して、Launcher 検出があるのに表示外な状況を user に明示する。
                int shownManager = Math.Min(managerOthers.Count, maxShown);
                int shownLauncher = shown - shownManager;
                int hiddenManager = managerOthers.Count - shownManager;
                int hiddenLauncher = launcherOthers.Count - shownLauncher;
                if (hiddenManager > 0 && hiddenLauncher > 0)
                {
                    sb.Append("\n  ...他 " + (totalCount - maxShown) + " 件 (Manager " + hiddenManager + " 件 / Launcher " + hiddenLauncher + " 件 表示外)");
                }
                else if (hiddenManager > 0)
                {
                    sb.Append("\n  ...他 " + hiddenManager + " 件 (Manager 表示外)");
                }
                else if (hiddenLauncher > 0)
                {
                    sb.Append("\n  ...他 " + hiddenLauncher + " 件 (Launcher 表示外)");
                }
            }
            return sb.ToString();
        }
    }
}
