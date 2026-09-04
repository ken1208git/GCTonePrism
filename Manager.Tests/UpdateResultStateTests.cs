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
        public void FailureRecord_Expires_WhenRunningVersionCaughtUp()
        {
            // 実行中の Manager が目標版数に達していれば、その失敗は解消済み
            // (手動で Install.bat から復旧した場合など)。時間ではなく事実で失効させる。
            Version running = VersionInventory.ReadManagerVersion();
            Assert.NotNull(running);
            WriteResult(4, running.ToString(3) + ".0");
            Assert.False(UpdaterClient.HasUnresolvedFailure());
            Assert.False(ResultFileExists());
        }

        [Fact]
        public void FailureRecord_Expires_EvenWhenOnlyRevisionDiffers()
        {
            // **3-part 比較**。running は AssemblyVersion、target は apphost の FileVersion で SoT が違い、
            // リリースゲートも 3-part までしか一致を強制しない。4-part で比べると revision の drift だけで
            // 失効条件を満たせず、失敗記録が永久に残る (= タブが恒久的に「未完了」と言い続ける)。
            Version running = VersionInventory.ReadManagerVersion();
            Assert.NotNull(running);
            WriteResult(4, string.Format("{0}.{1}.{2}.{3}", running.Major, running.Minor,
                running.Build < 0 ? 0 : running.Build, 99));
            Assert.False(UpdaterClient.HasUnresolvedFailure());
        }

        [Fact]
        public void RecordWithoutExitCode_IsNotTreatedAsFailure()
        {
            // 「欠けている」を「失敗」と読むと偽の警告になる。判定材料から外して捨てる。
            WriteResult(null, "0.34.1.0");
            Assert.False(UpdaterClient.HasUnresolvedFailure());
            Assert.False(ResultFileExists());
        }

        [Fact]
        public void NoRecord_IsNotFailure()
        {
            // 一度も更新していない / 旧 Updater。ここで失敗扱いすると通常起動のたびに警告が出る。
            Assert.False(UpdaterClient.HasUnresolvedFailure());
        }

        [Fact]
        public void FailureWithoutTargetVersion_NeverExpiresByVersion()
        {
            // 目標版数が無い記録は版数では失効できない (次の更新が上書きするまで残る)。
            // だからこそ MainForm 側は「期待版数が取れないときは記録しない」ようにしてある。
            WriteResult(4, null);
            Assert.True(UpdaterClient.HasUnresolvedFailure());
            Assert.True(ResultFileExists());
        }
    }
}
