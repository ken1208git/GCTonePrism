using System;
using System.Data.SQLite;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Models;
using TonePrism.Manager.Repositories;
using TonePrism.Manager.Services;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#250 PR2) `RestoreReconciliationService` の guide/ (イントロガイド画像) 突き合わせの検証。
    /// 旧実装は games/ しか突き合わせず、別時点 DB を復元すると `intro_slides.image_path` (guide/&lt;file&gt;) が
    /// 指す画像の欠落が silent だった。欠落→`BrokenIntroSlides` で検出・存在→非検出を確認する。
    /// PathManager は静的だがテスト seam (`SetBaseDirectoryForTest`) で一時 install dir に向ける。
    /// </summary>
    [Collection("PathManagerStatic")]   // (#386) 静的 PathManager base dir 共有のため直列化 (既存の潜在 flaky も解消)
    public class RestoreReconciliationServiceTests : IDisposable
    {
        private readonly string _root;
        private readonly DatabaseConnection _conn;
        private readonly DatabaseManager _dbManager;

        public RestoreReconciliationServiceTests()
        {
            _root = Path.Combine(Path.GetTempPath(), "tp_reconcile_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
            string dbPath = Path.Combine(_root, "toneprism.db");
            _conn = new DatabaseConnection(dbPath);
            new SchemaManager(_conn).InitializeDatabase();
            _dbManager = new DatabaseManager(_conn); // (#239) 内部 test ctor
            PathManager.SetBaseDirectoryForTest(_root);
        }

        public void Dispose()
        {
            PathManager.ResetBaseDirectoryForTest();
            try { SQLiteConnection.ClearAllPools(); } catch { }
            try { if (Directory.Exists(_root)) Directory.Delete(_root, true); } catch { }
        }

        [Fact]
        public void Analyze_MissingGuideImage_FlaggedAsBrokenIntroSlide_NotCritical()
        {
            // guide/present.png は実在、guide/missing.png は DB が参照するが実体なし、text-only は画像なしが正常。
            Directory.CreateDirectory(Path.Combine(_root, "guide"));
            File.WriteAllText(Path.Combine(_root, "guide", "present.png"), "img");
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 0, BodyText = "a", ImagePath = "guide/present.png" });
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 1, BodyText = "b", ImagePath = "guide/missing.png" });
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 2, BodyText = "text-only", ImagePath = null });

            var result = new RestoreReconciliationService(_dbManager).Analyze();

            // 欠落画像 1 件だけが検出される (実在・text-only は対象外)。修正前は guide を見ず 0 件 (silent)。
            Assert.Single(result.BrokenIntroSlides);
            Assert.Equal("guide/missing.png", result.BrokenIntroSlides[0].ImagePath);
            Assert.True(result.HasAnyFindings);
            Assert.False(result.HasCriticalFindings); // 画像欠落は warning (起動は妨げない)
        }

        [Fact]
        public void Analyze_AllGuideImagesPresent_NoFinding()
        {
            Directory.CreateDirectory(Path.Combine(_root, "guide"));
            File.WriteAllText(Path.Combine(_root, "guide", "a.png"), "img");
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 0, BodyText = "a", ImagePath = "guide/a.png" });
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 1, BodyText = "text", ImagePath = null });

            var result = new RestoreReconciliationService(_dbManager).Analyze();

            Assert.Empty(result.BrokenIntroSlides);
        }

        [Fact]
        public void Analyze_InvisibleSlideMissingImage_NotFlagged()
        {
            // (review #1) 非表示スライド (is_visible=0) の画像欠落は対象外 (Launcher は is_visible=1 のみ表示するため
            // ユーザーに見える breakage ではない)。修正前は GetAll が全件を返し非表示も検出していた。
            Directory.CreateDirectory(Path.Combine(_root, "guide"));
            _dbManager.AddIntroSlide(new IntroSlide { DisplayOrder = 0, BodyText = "hidden", ImagePath = "guide/missing.png", IsVisible = false });

            var result = new RestoreReconciliationService(_dbManager).Analyze();

            Assert.Empty(result.BrokenIntroSlides);
        }
    }
}
