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
    ///   <item>失敗判定が「末尾 20 行に <c>[ERROR]</c>」という**文言依存**で、ログの言い回しを変えた人が
    ///   判定を壊せる。現状は全ての <c>Logger.Error</c> が非 0 return 経路にあり偶然成立しているが、
    ///   非致命箇所に <c>Logger.Error</c> を 1 本足した瞬間に成功が失敗へ倒れる</item>
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
    /// 残った失敗の記録は**版数では失効しない**。**記録が消えるのは 3 経路だけ**: (1) 起動時に成功を確認したとき (2) 次の試行が上書きしたとき (3) `Install.bat` が掃除したとき。
    /// （版数で失効させると、Manager の版数が変わらない Bundle リリースで即座に消え、起動時ダイアログが
    ///  案内した再試行導線がその場で消える。）
    /// </summary>
    internal static class UpdateResult
    {
        internal const string FileName = ".update_result";

        /// <summary>
        /// 既に書き出したか。**成功を spawn 前に書いてから、`finally` が同じ値で上書きするのを防ぐ**ため。
        /// 新 Manager が読んで削除した後に `finally` が書き直すと、平常時にファイルが残ってしまう。
        /// 失敗 (exitCode != 0) のときは上書きする — spawn 前に成功を書いた後で Step 3/4 が失敗する
        /// 経路があり、そこでは最終的な終了コードが正しい。
        /// </summary>
        private static bool _written;

        /// <summary>
        /// 結果を書き出す。**書き込み失敗は握り潰す** — ここで落とすとアップデート自体の成否が
        /// 変わってしまう。読めなければ消費側が従来のログ推測にフォールバックする。
        /// </summary>
        /// <param name="managerTargetDir">`--manager-target`。この親を install root とみなす</param>
        /// <param name="stagingDir">`--staging`。中の `files/Manager/TonePrism_Manager.exe` から目標版数を読む</param>
        /// <param name="exitCode">Updater の終了コード (0 = 成功)</param>
        internal static void Write(string managerTargetDir, string stagingDir, int exitCode)
        {
            // 成功を既に書いてあるなら書き直さない (上記 _written のコメント参照)。
            if (_written && exitCode == 0) return;
            try
            {
                if (string.IsNullOrEmpty(managerTargetDir)) return;
                string installRoot = Path.GetDirectoryName(managerTargetDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
                if (string.IsNullOrEmpty(installRoot)) return;

                string targetVersion = ReadStagingManagerVersion(stagingDir);
                // 依存を増やさないため手書きの JSON。
                // (レビュー D-2) **targetVersion は自前生成ではない** — staging exe の VERSIONINFO
                // リソース由来の任意文字列で、"1.0.0.0 (release)" のような書式も実在しうる。
                // `"` / `\` が混ざると JSON が壊れ、次回起動で「あるが読めない」= 判定不能に落ちるので
                // 最小限の escape を通す。
                // 成否は `exitCode == 0` から導けるので **success フィールドは持たない**。
                // 同じ事実の出所が 2 つあると食い違ったときどちらが正か決まらず、しかも bool は
                // 「欠けている」と「false」を区別できないため、欠落したファイルを失敗と読んでしまう。
                string json = "{"
                    + "\"finishedAt\":\"" + DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture) + "\","
                    + "\"exitCode\":" + exitCode.ToString(CultureInfo.InvariantCulture) + ","
                    + "\"targetManagerVersion\":" + (targetVersion == null ? "null" : "\"" + EscapeJsonString(targetVersion) + "\"")
                    + "}";

                string path = Path.Combine(installRoot, FileName);
                File.WriteAllText(path, json, new System.Text.UTF8Encoding(false));
                _written = true;
                Logger.Info($"実行結果を書き出しました: {path} (exit={exitCode})");
            }
            catch (Exception ex)
            {
                Logger.Warn($"実行結果の書き出しに失敗 (処理は継続): {ex.GetType().Name}: {ex.Message}");
            }
        }

        /// <summary>
        /// (レビュー D-2) JSON 文字列値の最小 escape。
        /// </summary>
        private static string EscapeJsonString(string s)
        {
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        /// <summary>
        /// staging の Manager.exe から「この更新で入るはずだった版数」を読む。
        /// (レビュー A-4) 本メソッド自体は置換後の版数検証 (`Program.Run`) からも呼ばれる。
        /// consumer が無いのは **書き出した `targetManagerVersion` フィールドの方** — 版数による
        /// 自動失効を撤廃したため、Manager 側は判定に使わず、人が `.update_result` を開いて
        /// 「どの版へ更新しようとして失敗したか」を知るための診断情報として残してある。読めなければ null。
        /// </summary>
        internal static string ReadStagingManagerVersion(string stagingDir)
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
