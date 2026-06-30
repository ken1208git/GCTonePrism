using System;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Services;
using Xunit;
using Role = TonePrism.Manager.Services.GameImageAssetHelper.ImageRole;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#386) GameImageSaveImporter（保存時の外部画像取り込み共通ロジック）の単体テスト。外部→.toneprism 取り込み、
    /// 内部/空はそのまま、新規ファイルの追跡、best-effort 掃除を一時 install dir で検証。
    /// </summary>
    [Collection("PathManagerStatic")]   // (#386) 静的 PathManager base dir 共有のため直列化
    public class GameImageSaveImporterTests : IDisposable
    {
        private readonly string _root;
        private readonly string _ext;   // games/ の外 (= 外部画像置き場)

        public GameImageSaveImporterTests()
        {
            _root = Path.Combine(Path.GetTempPath(), "tp_imp_root_" + Guid.NewGuid().ToString("N"));
            _ext = Path.Combine(Path.GetTempPath(), "tp_imp_ext_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
            Directory.CreateDirectory(_ext);
            PathManager.SetBaseDirectoryForTest(_root);
        }

        public void Dispose()
        {
            PathManager.ResetBaseDirectoryForTest();
            foreach (var d in new[] { _root, _ext })
            {
                try { if (Directory.Exists(d)) Directory.Delete(d, true); } catch { /* ignore */ }
            }
        }

        private string ExternalImage(string name, byte[] content)
        {
            string p = Path.Combine(_ext, name);
            File.WriteAllBytes(p, content);
            return p;
        }

        [Fact]
        public void ExternalImage_ImportedToToneprism_ReturnsInternalAbs_AndTracksCreated()
        {
            string src = ExternalImage("cover.png", new byte[] { 1, 2, 3 });

            // (imagePath, gameId, diskVersion, role, out created)
            string result = GameImageSaveImporter.ImportIfExternal(src, "g1", "v1.0.0", Role.Thumbnail, out string created);

            string expected = Path.Combine(_root, "games", "g1", "v1.0.0", ".toneprism", "thumbnail.png");
            Assert.Equal(Path.GetFullPath(expected), Path.GetFullPath(result));
            Assert.True(File.Exists(result));
            Assert.Equal(Path.GetFullPath(expected), Path.GetFullPath(created));   // 新規コピーは追跡される
            Assert.True(File.Exists(src));                                          // copy-not-move
        }

        [Fact]
        public void InternalImage_ReturnedUnchanged_NotTracked()
        {
            // gameFolder 内のパスはそのまま返り、取り込み・追跡しない。
            string internalPath = Path.Combine(_root, "games", "g2", "v1.0.0", ".toneprism", "thumbnail.png");
            string result = GameImageSaveImporter.ImportIfExternal(internalPath, "g2", "v1.0.0", Role.Thumbnail, out string created);

            Assert.Equal(internalPath, result);
            Assert.Null(created);
        }

        [Fact]
        public void EmptyOrNull_ReturnedUnchanged()
        {
            Assert.Null(GameImageSaveImporter.ImportIfExternal(null, "g3", "v1.0.0", Role.Background, out string c1));
            Assert.Null(c1);
            Assert.Equal("", GameImageSaveImporter.ImportIfExternal("", "g3", "v1.0.0", Role.Background, out string c2));
            Assert.Null(c2);
        }

        [Fact]
        public void CleanupBestEffort_DeletesCreated_AndSkipsMissing()
        {
            string src = ExternalImage("bg.jpg", new byte[] { 9 });
            GameImageSaveImporter.ImportIfExternal(src, "g4", "v1.0.0", Role.Background, out string created);
            Assert.True(File.Exists(created));

            GameImageSaveImporter.CleanupBestEffort(new[] { created, Path.Combine(_ext, "never_existed.png") });

            Assert.False(File.Exists(created));   // 取り込んだファイルは消える。存在しないパスは無視 (no throw)。
        }
    }
}
