using System;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Services;
using Xunit;
using Role = TonePrism.Manager.Services.GameImageAssetHelper.ImageRole;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#386) GameImageSaveImporter（保存時の外部画像取り込み共通ロジック）の単体テスト。版オブジェクトのパス
    /// (相対=内部 / 絶対外部=未取り込み) を受け、外部は .toneprism へ取り込んで gameFolder 基準の相対 (forward slash) を返す。
    /// 相対/空はそのまま、新規ファイルの追跡、best-effort 掃除を一時 install dir で検証。
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
        public void ExternalAbsolute_Imported_ReturnsForwardSlashRelative_TracksCreated()
        {
            string src = ExternalImage("cover.png", new byte[] { 1, 2, 3 });

            string rel = GameImageSaveImporter.ImportIfExternalToRelative(src, "g1", "v1.0.0", Role.Thumbnail, out string created);

            Assert.Equal("v1.0.0/.toneprism/thumbnail.png", rel);   // gameFolder 基準・forward slash
            string abs = Path.Combine(_root, "games", "g1", "v1.0.0", ".toneprism", "thumbnail.png");
            Assert.True(File.Exists(abs));
            Assert.Equal(Path.GetFullPath(abs), Path.GetFullPath(created));   // 新規コピーは追跡
            Assert.True(File.Exists(src));                                    // copy-not-move
        }

        [Fact]
        public void RelativePath_ReturnedUnchanged_NotTracked()
        {
            // 既に相対 (= 内部・DB 保存形) のパスは取り込まず素通り。
            string result = GameImageSaveImporter.ImportIfExternalToRelative("v1.0.0/.toneprism/thumbnail.png", "g2", "v1.0.0", Role.Thumbnail, out string created);
            Assert.Equal("v1.0.0/.toneprism/thumbnail.png", result);
            Assert.Null(created);
        }

        [Fact]
        public void InternalAbsolute_RelativizedToForwardSlash_NotTracked()
        {
            // gameFolder 内の絶対パス (防御経路) は相対化して返す (取り込みはしない)。
            string internalAbs = Path.Combine(_root, "games", "g3", "v2.0.0", ".toneprism", "background.jpg");
            string result = GameImageSaveImporter.ImportIfExternalToRelative(internalAbs, "g3", "v2.0.0", Role.Background, out string created);
            Assert.Equal("v2.0.0/.toneprism/background.jpg", result);
            Assert.Null(created);
        }

        [Fact]
        public void EmptyOrNull_ReturnedUnchanged()
        {
            Assert.Null(GameImageSaveImporter.ImportIfExternalToRelative(null, "g4", "v1.0.0", Role.Background, out string c1));
            Assert.Null(c1);
            Assert.Equal("", GameImageSaveImporter.ImportIfExternalToRelative("", "g4", "v1.0.0", Role.Background, out string c2));
            Assert.Null(c2);
        }

        [Fact]
        public void CleanupBestEffort_DeletesCreated_AndSkipsMissing()
        {
            string src = ExternalImage("bg.jpg", new byte[] { 9 });
            GameImageSaveImporter.ImportIfExternalToRelative(src, "g5", "v1.0.0", Role.Background, out string created);
            string createdAbs = Path.Combine(_root, "games", "g5", "v1.0.0", ".toneprism", "background.jpg");
            Assert.True(File.Exists(createdAbs));

            GameImageSaveImporter.CleanupBestEffort(new[] { created, Path.Combine(_ext, "never_existed.png") });

            Assert.False(File.Exists(createdAbs));   // 取り込んだファイルは消える。存在しないパスは無視 (no throw)。
        }
    }
}
