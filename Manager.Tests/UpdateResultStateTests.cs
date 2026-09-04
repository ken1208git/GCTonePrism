using System;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Services;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#440) `.update_result` の状態遷移。
    ///
    /// **なぜ要るか**: レビューで見つかった 2 件の High（成功後に旧ログ推測へ落ちて矛盾表示 /
    /// 版数比較の粒度不一致で失敗記録が永久に残る）は、どちらも wire contract のテストでは捕まらず、
    /// **この層のテストがあれば静的に落ちた**種類だった。JSON の往復だけでなく「どう解釈するか」を固定する。
    /// </summary>
    [Collection("PathManagerStatic")]
    public class UpdateResultStateTests : IDisposable
    {
        private readonly string _root;

        public UpdateResultStateTests()
        {
            _root = Path.Combine(Path.GetTempPath(), "tp_upd_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
            PathManager.SetBaseDirectoryForTest(_root);
        }

        public void Dispose()
        {
            PathManager.ResetBaseDirectoryForTest();
            try { Directory.Delete(_root, true); } catch { /* ignore */ }
        }

        private void WriteResult(int? exitCode, string targetManagerVersion)
        {
            string exit = exitCode.HasValue ? exitCode.Value.ToString() : null;
            string json = "{" + Quote("finishedAt") + ":" + Quote("2026-09-04T00:00:00Z")
                + (exit != null ? "," + Quote("exitCode") + ":" + exit : "")
                + "," + Quote("targetManagerVersion") + ":"
                + (targetManagerVersion == null ? "null" : Quote(targetManagerVersion))
                + "}";
            File.WriteAllText(Path.Combine(_root, ".update_result"), json, new System.Text.UTF8Encoding(false));
        }

        private static string Quote(string s) { return "\"" + s + "\""; }

        private bool ResultFileExists()
        {
            return File.Exists(Path.Combine(_root, ".update_result"));
        }

        [Fact]
        public void SuccessRecord_IsConsumedAndDeleted()
        {
            // 成功はもう覚えておく必要が無いので、読んだ時点で消える (平常時はファイルが存在しない)。
            WriteResult(0, "0.34.1.0");
            Assert.False(UpdaterClient.HasUnresolvedFailure());
            Assert.False(ResultFileExists());
        }

        [Fact]
        public void FailureRecord_Survives_WhenVersionHasNotCaughtUp()
        {
            // 失敗はアップデートタブが再試行ボタンを有効に戻すために後で参照するので残す。
            // 目標版数が実行中よりずっと先なので、まだ解消していない。
            WriteResult(4, "99.0.0.0");
            Assert.True(UpdaterClient.HasUnresolvedFailure());
            Assert.True(ResultFileExists());
        }

        [Fact]
        public void FailureRecord_Survives_EvenWhenRunningVersionMatchesTarget()
        {
            // **版数では失効させない (レビュー High-1)。**
            // 以前は「実行中が目標に追いついたら解消済み」として消していたが、Manager の版数が
            // 変わらない Bundle リリース (Launcher だけ上げた等) では失敗した瞬間から一致するので、
            // 最初の参照で即座に消えてしまう。すると起動時ダイアログが「タブからもう一度」と案内した
            // 直後に、そのタブが「最新版を実行中」+ ボタン無効になる = 案内先が行き止まりになる。
            Version running = VersionInventory.ReadManagerVersion();
            Assert.NotNull(running);
            WriteResult(4, running.ToString(3) + ".0");
            Assert.True(UpdaterClient.HasUnresolvedFailure());
            Assert.True(ResultFileExists());
        }

        [Fact]
        public void FileExists_DistinguishesMissingFromUnreadable()
        {
            // (レビュー Medium) 「無い」と「あるが読めない」は消費側で意味が正反対。
            // TryLoadUpdateResult はどちらも null を返すので、存在確認を別に持つ。
            Assert.False(UpdaterClient.UpdateResultFileExists());
            File.WriteAllText(Path.Combine(_root, ".update_result"), "これは JSON ではない",
                new System.Text.UTF8Encoding(false));
            Assert.True(UpdaterClient.UpdateResultFileExists());
            Assert.Null(UpdaterClient.TryLoadUpdateResult());
        }

        [Fact]
        public void RecordWithoutExitCode_IsNotTreatedAsFailure()
        {
            // 「欠けている」を「失敗」と読むと偽の警告になる。判定材料から外す。
            // ただし **消さない** (レビュー Medium-6) — SPEC が宣言する 3 つの削除経路の外に
            // 4 つ目を作らない。壊れた記録は次の試行の上書きか Install.bat が掃除する。
            WriteResult(null, "0.34.1.0");
            Assert.False(UpdaterClient.HasUnresolvedFailure());
            Assert.True(ResultFileExists());
        }

        [Fact]
        public void NoRecord_IsNotFailure()
        {
            // 一度も更新していない / 旧 Updater。ここで失敗扱いすると通常起動のたびに警告が出る。
            Assert.False(UpdaterClient.HasUnresolvedFailure());
        }

        [Fact]
        public void ManagerWrittenRecord_IsReadableByTheReader()
        {
            // (レビュー Medium-3) 他のテストはどれも**テスト自身が組み立てた JSON** を読ませており、
            // 製品コードが手書きしている文字列を一度も通っていない。producer 側の typo
            // (キー名・クォート・カンマ) はそれでは落ちない。ここだけは実 producer を呼ぶ。
            UpdaterClient.RecordFailureWithoutUpdaterResult("0.34.2.0");

            var dto = UpdaterClient.TryLoadUpdateResult();
            Assert.NotNull(dto);
            Assert.Equal(1, dto.ExitCode);          // Updater が残せなかったときの汎用エラー
            Assert.False(dto.Success.Value);
            Assert.Equal("0.34.2.0", dto.TargetManagerVersion);
            Assert.True(UpdaterClient.HasUnresolvedFailure());
        }

        [Fact]
        public void ManagerWrittenRecord_WithoutTargetVersion_IsStillReadable()
        {
            // 目標版数が無い場合に `null` を裸で書く分岐 (クォートしない) も producer を通して固定する。
            UpdaterClient.RecordFailureWithoutUpdaterResult(null);

            var dto = UpdaterClient.TryLoadUpdateResult();
            Assert.NotNull(dto);
            Assert.Equal(1, dto.ExitCode);
            Assert.Null(dto.TargetManagerVersion);
        }

        [Fact]
        public void FailureWithoutTargetVersion_NeverExpiresByVersion()
        {
            // 目標版数の有無に関わらず、失敗の記録は残る (版数では失効させない方針)。
            // MainForm 側が「期待版数が取れないときは記録しない」のは、その場合の失敗判定が
            // ログ推測由来で当てにならないためであって、失効可否の話ではない。
            WriteResult(4, null);
            Assert.True(UpdaterClient.HasUnresolvedFailure());
            Assert.True(ResultFileExists());
        }
    }
}
