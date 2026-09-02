using System;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Services;
using Xunit;
using Role = TonePrism.Manager.Services.GameImageAssetHelper.ImageRole;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#386) GameImageAssetHelper の単体テスト。版フォルダ配下 <c>.toneprism/&lt;role&gt;.&lt;ext&gt;</c> への
    /// コピー取り込み・役割正規化・copy-not-move・overwrite/orphan・再保存 no-op・相対パス返却を一時フォルダで検証。
    /// VersionDeletionTests と同じ #239 方針 (PathManager 非依存の一時フォルダ。本番 wrapper のみ seam で base を差し替え)。
    /// </summary>
    [Collection("PathManagerStatic")]   // (#386) 静的 PathManager base dir 共有のため直列化
    public class GameImageAssetHelperTests : IDisposable
    {
        private readonly string _tmp;

        public GameImageAssetHelperTests()
        {
            _tmp = Path.Combine(Path.GetTempPath(), "tp_img_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_tmp);
        }

        public void Dispose()
        {
            try { if (Directory.Exists(_tmp)) Directory.Delete(_tmp, true); } catch { /* ignore */ }
        }

        private string WriteSource(string name, byte[] content)
        {
            string p = Path.Combine(_tmp, name);
            File.WriteAllBytes(p, content);
            return p;
        }

        private string VersionFolder() => Path.Combine(_tmp, "games", "g1", "v1.0.0");

        // ---- (#348) CleanupStaleRoleFiles ----

        [Fact]
        public void CleanupStaleRoleFiles_DeletesOtherExtRoleFiles_KeepsCurrent_AndNonRole()
        {
            string dir = Path.Combine(VersionFolder(), ".toneprism");
            Directory.CreateDirectory(dir);
            File.WriteAllText(Path.Combine(dir, "thumbnail.png"), "old-orphan");    // 旧拡張子 (削除対象)
            File.WriteAllText(Path.Combine(dir, "thumbnail.jpg"), "current-thumb"); // 現行 (残す)
            File.WriteAllText(Path.Combine(dir, "background.png"), "current-bg");    // 現行 (残す)
            File.WriteAllText(Path.Combine(dir, "readme.txt"), "keep");             // 非役割 (触らない)

            // 現行 = thumbnail.jpg / background.png (backslash 区切りでも正規化されることも確認)。
            GameImageAssetHelper.CleanupStaleRoleFiles(
                Path.Combine(_tmp, "games", "g1"),
                new[] { "v1.0.0" },
                new[] { "v1.0.0\\.toneprism\\thumbnail.jpg", "v1.0.0/.toneprism/background.png" });

            Assert.False(File.Exists(Path.Combine(dir, "thumbnail.png")));  // 旧拡張子 orphan は削除
            Assert.True(File.Exists(Path.Combine(dir, "thumbnail.jpg")));   // 現行サムネは残る
            Assert.True(File.Exists(Path.Combine(dir, "background.png")));  // 現行背景は残る
            Assert.True(File.Exists(Path.Combine(dir, "readme.txt")));      // 非役割ファイルは温存
        }

        [Fact]
        public void CleanupStaleRoleFiles_KeepsFileReferencedByAnotherVersion()
        {
            // (round6 指摘1) v1.0.0/.toneprism/thumbnail.png を v2.0.0 が参照している場合、v1.0.0 掃除で消してはいけない
            // (版跨ぎ参照は運用上異常だが手入力で入りうる。削除は不可逆なので「どの版も参照しないファイル」だけ消す)。
            string dir = Path.Combine(_tmp, "games", "g1", "v1.0.0", ".toneprism");
            Directory.CreateDirectory(dir);
            File.WriteAllText(Path.Combine(dir, "thumbnail.png"), "shared");   // v2.0.0 が参照
            File.WriteAllText(Path.Combine(dir, "thumbnail.jpg"), "orphan");   // どの版も参照しない

            GameImageAssetHelper.CleanupStaleRoleFiles(
                Path.Combine(_tmp, "games", "g1"),
                new[] { "v1.0.0", "v2.0.0" },
                new[] { "v2.0.0/.toneprism/thumbnail.jpg", "v1.0.0/.toneprism/thumbnail.png" });

            Assert.True(File.Exists(Path.Combine(dir, "thumbnail.png")));   // 別版が参照 = 残す
            Assert.False(File.Exists(Path.Combine(dir, "thumbnail.jpg")));  // どの版も参照しない = 削除
        }

        [Fact]
        public void CleanupStaleRoleFiles_NoToneprismFolder_NoThrow()
        {
            // .toneprism が無い版でも例外にならない (no-op)。
            GameImageAssetHelper.CleanupStaleRoleFiles(Path.Combine(_tmp, "games", "g1"), new[] { "v9.9.9" }, new string[0]);
        }

        // ---- コア CopyImageInto ----

        [Fact]
        public void CopyImageInto_PlacesRoleFileUnderToneprism_AndKeepsSource()
        {
            string src = WriteSource("anything.png", new byte[] { 1, 2, 3 });
            string vf = VersionFolder();

            string dest = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, src, out bool created);

            Assert.True(created);
            Assert.Equal(Path.GetFullPath(Path.Combine(vf, ".toneprism", "thumbnail.png")), dest);
            Assert.True(File.Exists(dest));
            Assert.True(File.Exists(src));                       // copy-not-move: 元画像は残る
            Assert.Equal(new byte[] { 1, 2, 3 }, File.ReadAllBytes(dest));
        }

        [Fact]
        public void CopyImageInto_NormalizesByRole_NotBySourceName()
        {
            // 元ファイル名に依らず thumbnail/background の固定名になる。
            string a = WriteSource("logo.png", new byte[] { 1 });
            string b = WriteSource("scene.jpg", new byte[] { 2 });
            string vf = VersionFolder();

            string t = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, a);
            string g = GameImageAssetHelper.CopyImageInto(vf, Role.Background, b);

            Assert.Equal("thumbnail.png", Path.GetFileName(t));
            Assert.Equal("background.jpg", Path.GetFileName(g));
            Assert.True(File.Exists(t) && File.Exists(g));        // 役割が別 = 別ファイルで共存
        }

        [Fact]
        public void CopyImageInto_SameExtension_Overwrites_NoOrphan()
        {
            string vf = VersionFolder();
            GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("old.png", new byte[] { 9 }));
            string dest = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("new.png", new byte[] { 7, 7 }));

            Assert.Equal(new byte[] { 7, 7 }, File.ReadAllBytes(dest));               // 上書き済
            Assert.Single(Directory.GetFiles(Path.Combine(vf, ".toneprism")));        // thumbnail.png 1 個のみ
        }

        [Fact]
        public void CopyImageInto_ExtensionChange_LeavesOldRoleFile_AsDocumentedOrphan()
        {
            // png→jpg の差し替えで、CopyImageInto 単体では旧 thumbnail.png を残す (掃除は別 = 保存成功後に
            // CleanupStaleRoleFiles が実施)。ここは「コア copy が上書きでなく別ファイルを作り、旧拡張子を残す」挙動の固定。
            string vf = VersionFolder();
            GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("a.png", new byte[] { 1 }));
            GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("b.jpg", new byte[] { 2 }));

            string dir = Path.Combine(vf, ".toneprism");
            Assert.True(File.Exists(Path.Combine(dir, "thumbnail.png")));   // 旧拡張子の orphan
            Assert.True(File.Exists(Path.Combine(dir, "thumbnail.jpg")));   // 新拡張子
        }

        [Fact]
        public void CopyImageInto_SourceAlreadyAtDestination_IsNoOp()
        {
            // EDIT で画像を変えず再保存する経路: source が既に .toneprism/thumbnail.png 自身。複製せず no-op。
            string vf = VersionFolder();
            string dest = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("first.png", new byte[] { 5 }));

            string again = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, dest, out bool created);

            Assert.False(created);
            Assert.Equal(dest, again);
            Assert.Equal(new byte[] { 5 }, File.ReadAllBytes(dest));        // 内容そのまま
        }

        [Fact]
        public void CopyImageInto_LowercasesExtension()
        {
            string vf = VersionFolder();
            string dest = GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, WriteSource("UP.PNG", new byte[] { 1 }));
            Assert.Equal("thumbnail.png", Path.GetFileName(dest));
        }

        [Fact]
        public void CopyImageInto_MissingSource_Throws()
        {
            string vf = VersionFolder();
            Assert.Throws<FileNotFoundException>(() =>
                GameImageAssetHelper.CopyImageInto(vf, Role.Thumbnail, Path.Combine(_tmp, "does_not_exist.png")));
        }

        // ---- 本番 wrapper ImportImage (PathManager seam) ----

        [Fact]
        public void ImportImage_ReturnsGameRelativeForwardSlashPath()
        {
            PathManager.SetBaseDirectoryForTest(_tmp);
            try
            {
                string src = WriteSource("ext.png", new byte[] { 1, 2 });
                string rel = GameImageAssetHelper.ImportImage("g1", "v1.0.0", Role.Thumbnail, src);

                Assert.Equal("v1.0.0/.toneprism/thumbnail.png", rel);   // ゲームフォルダ基準・forward slash
                string abs = Path.Combine(_tmp, "games", "g1", "v1.0.0", ".toneprism", "thumbnail.png");
                Assert.True(File.Exists(abs));
            }
            finally { PathManager.ResetBaseDirectoryForTest(); }
        }

        [Fact]
        public void ImportImage_NormalizesVersionLeaf()
        {
            PathManager.SetBaseDirectoryForTest(_tmp);
            try
            {
                // 生値 "1.0.0" でも leaf は "v1.0.0" に正規化される (GetVersionFolderLeaf)。
                string rel = GameImageAssetHelper.ImportImage("g1", "1.0.0", Role.Background, WriteSource("bg.jpg", new byte[] { 3 }));
                Assert.Equal("v1.0.0/.toneprism/background.jpg", rel);
            }
            finally { PathManager.ResetBaseDirectoryForTest(); }
        }
    }
}
