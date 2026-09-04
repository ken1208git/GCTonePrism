using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;

namespace TonePrism.Updater
{
    /// <summary>
    /// (#440) Updater の実行結果を <c>&lt;install&gt;/.update_result</c> に残す。
    ///
    /// <b>なぜ要るか</b>: アップデートは「今の Manager が終了 → Updater が置換 → 別の Manager が起動」なので、
    /// Manager は Updater の**プロセス終了コードを受け取れない**（受け取るには待つ必要があるが、待っていると
    /// dir を置換できない）。そのため Manager 側は長らく「Updater のログ末尾 20 行を読んで <c>[ERROR]</c> が
    /// あれば失敗」という推測をしていた。これには 3 つ問題があった:
    ///
    /// <list type="number">
    ///   <item>ログは人間向けの副産物であって API ではない。文言を変えた人が判定を壊せる</item>
    ///   <item>致命的でない <c>Logger.Error</c>（<c>.bak</c> の削除失敗など、処理は継続する）で失敗に倒れる</item>
    ///   <item>「どの実行の話か」が分からないので「直近 2 分のログだけ見る」という窓が要り、
    ///         失敗の翌朝に起動すると読めない</item>
    /// </list>
    ///
    /// 答えは Updater が既に持っている（終了コード）ので、解析で復元するのではなく**消えない場所に書く**。
    /// ログは人間のために残し、判定だけをそこから剥がす。
    ///
    /// <b>寿命</b>: 消費側 (Manager の起動時) が読んで、**成功なら即削除・失敗なら残す**。
    /// 成功はもう覚えておく必要が無いが、失敗は「アップデートタブの再試行ボタンを有効に戻す」ために
    /// 後で（別セッションでも）参照する必要があるため。したがって<b>平常時はこのファイルは存在しない</b>。
    ///
    /// 残った失敗の記録は、実行中の Manager が `targetManagerVersion` に達していれば消費側が失効させる
    /// （手動で <c>Install.bat</c> を実行して直した場合も自動で解消する = 時間ではなく事実で失効させる）。
    /// 次の更新試行でも上書きされるので、いずれにせよ溜まらない。
    /// </summary>
    internal static class UpdateResult
    {
        internal const string FileName = ".update_result";

        /// <summary>
        /// 結果を書き出す。**書き込み失敗は握り潰す** — ここで落とすとアップデート自体の成否が
        /// 変わってしまう。読めなければ消費側が従来のログ推測にフォールバックする。
        /// </summary>
        /// <param name="managerTargetDir">`--manager-target`。この親を install root とみなす</param>
        /// <param name="stagingDir">`--staging`。中の `files/Manager/TonePrism_Manager.exe` から目標版数を読む</param>
        /// <param name="exitCode">Updater の終了コード (0 = 成功)</param>
        internal static void Write(string managerTargetDir, string stagingDir, int exitCode)
        {
            try
            {
                if (string.IsNullOrEmpty(managerTargetDir)) return;
                string installRoot = Path.GetDirectoryName(managerTargetDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
                if (string.IsNullOrEmpty(installRoot)) return;

                string targetVersion = ReadStagingManagerVersion(stagingDir);
                // 依存を増やさないため手書きの JSON。値は自前で生成した版数文字列と数値のみで、
                // ユーザー入力は入らない (escape が要る文字が混ざらない)。
                string json = "{"
                    + "\"finishedAt\":\"" + DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture) + "\","
                    + "\"exitCode\":" + exitCode.ToString(CultureInfo.InvariantCulture) + ","
                    + "\"success\":" + (exitCode == 0 ? "true" : "false") + ","
                    + "\"targetManagerVersion\":" + (targetVersion == null ? "null" : "\"" + targetVersion + "\"")
                    + "}";

                string path = Path.Combine(installRoot, FileName);
                File.WriteAllText(path, json, new System.Text.UTF8Encoding(false));
                Logger.Info($"実行結果を書き出しました: {path} (exit={exitCode})");
            }
            catch (Exception ex)
            {
                Logger.Warn($"実行結果の書き出しに失敗 (処理は継続): {ex.GetType().Name}: {ex.Message}");
            }
        }

        /// <summary>
        /// staging の Manager.exe から「この更新で入るはずだった版数」を読む。
        /// 消費側はこれと実行中の Manager を比べ、追いついていれば失敗記録を失効させる。
        /// 読めなければ null (失効判定なし = 次の更新で上書きされるまで残る)。
        /// </summary>
        private static string ReadStagingManagerVersion(string stagingDir)
        {
            try
            {
                if (string.IsNullOrEmpty(stagingDir)) return null;
                // FileReplacer.Replace と同じ導出 (`<staging>/files/Manager`)。
                string exe = Path.Combine(stagingDir, "files", "Manager", "TonePrism_Manager.exe");
                if (!File.Exists(exe)) return null;
                return FileVersionInfo.GetVersionInfo(exe).FileVersion;
            }
            catch
            {
                return null;
            }
        }
    }
}
