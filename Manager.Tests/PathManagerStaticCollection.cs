using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#386) <see cref="TonePrism.Manager.PathManager.SetBaseDirectoryForTest"/> は静的 <c>_baseDirectory</c> を
    /// 差し替える。これを使う test class を並列実行すると base dir をクロバーし合って flaky になる
    /// (実害が出た: GameImageAssetHelperTests 追加で 3 クラス目になり race 顕在化)。同一 collection に入れて
    /// 直列化する (xUnit は collection 単位で並列化・同 collection 内は逐次)。<c>DisableParallelization</c> で
    /// 他 collection とも並列にしない (静的はプロセス全体で 1 つのため完全直列化で安全側)。
    /// 対象: EditViewModelDirtyTests / GameImageAssetHelperTests / GameImageSaveImporterTests / RestoreReconciliationServiceTests。
    /// </summary>
    [CollectionDefinition("PathManagerStatic", DisableParallelization = true)]
    public class PathManagerStaticCollection { }
}
