using System;
using System.Collections.Generic;
using System.Data.SQLite;
using System.IO;
using TonePrism.Manager;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;
using TonePrism.Manager.Shell.GameForm;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#383) EditViewModel の未保存判定 (HasUnsavedChanges = load 時署名との比較) の回帰テスト。一時 DB から
    /// VM を構築し、(a) 無編集は dirty でない、(b) 変更→元戻しは dirty でない (署名比較の対称性)、(c) 自由入力に
    /// 区切り文字を含む状態でも false-negative を起こさない (指摘5: 長さプレフィックス符号化) を検証する。
    /// (c) が崩れると「未保存なのに無確認で破棄」= ガードが防ぎたい事故そのものになるため重点的に固める。
    /// VersionDeletionTests と同じ #239 方針 (PathManager 非依存の一時 DB)。
    /// </summary>
    [Collection("PathManagerStatic")]   // (#386) 静的 PathManager base dir 共有のため直列化
    public class EditViewModelDirtyTests : IDisposable
    {
        private readonly string _root;   // EditViewModel ctor が PathManager.GetGameFolder を引くため一時 install dir を向ける。
        private readonly string _dbPath;
        private readonly DatabaseConnection _conn;
        private readonly DatabaseManager _db;

        public EditViewModelDirtyTests()
        {
            _root = Path.Combine(Path.GetTempPath(), "tp_sig_root_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
            PathManager.SetBaseDirectoryForTest(_root);   // (#239 seam) GameFolder 解決を一時 dir へ (フォルダ実在は不要)
            _dbPath = Path.Combine(Path.GetTempPath(), "tp_sig_" + Guid.NewGuid().ToString("N") + ".db");
            _conn = new DatabaseConnection(_dbPath);
            new SchemaManager(_conn).InitializeDatabase();
            _db = new DatabaseManager(_conn);
        }

        public void Dispose()
        {
            PathManager.ResetBaseDirectoryForTest();
            try { SQLiteConnection.ClearAllPools(); } catch { /* ignore */ }
            foreach (var p in new[] { _dbPath, _dbPath + "-wal", _dbPath + "-shm", _dbPath + "-journal" })
            {
                try { if (File.Exists(p)) File.Delete(p); } catch { /* ignore */ }
            }
            try { if (Directory.Exists(_root)) Directory.Delete(_root, true); } catch { /* ignore */ }
        }

        // active 版 (games.version 一致) を 1 つ持つゲームを seed し、編集対象の GameInfo を返す。
        private GameInfo Seed(string gameId, string title, string description)
        {
            var game = new GameInfo
            {
                GameId = gameId,
                Title = title,
                Version = "v1.0.0",
                Description = description,
                ExecutablePath = "v1.0.0/game.exe",
                ThumbnailPath = "v1.0.0/thumb.png",
                Genre = new List<string>(),
                Developers = new List<DeveloperInfo>(),
                IsVisible = true,
            };
            _db.AddGame(game);
            _db.AddGameVersion(new GameVersion
            {
                GameId = gameId,
                Version = "v1.0.0",
                Title = title,
                Description = description,
                ExecutablePath = "v1.0.0/game.exe",
                ThumbnailPath = "v1.0.0/thumb.png",
                Genre = new List<string>(),
                Developers = new List<DeveloperInfo>(),
            });
            return game;
        }

        [Fact]
        public void NoEdit_IsNotDirty()
        {
            var vm = new EditViewModel(_db, Seed("sig0", "タイトル", "説明"));
            Assert.False(vm.HasUnsavedChanges());
        }

        [Fact]
        public void RevertEdit_BackToOriginal_IsNotDirty()
        {
            // 変更 → 元に戻すと未保存なしに戻る (フィールド dirty フラグ方式なら false dirty になる回帰を防ぐ)。
            var vm = new EditViewModel(_db, Seed("sig1", "タイトル", "説明"));
            vm.Title = "変更後";
            Assert.True(vm.HasUnsavedChanges());
            vm.Title = "タイトル";
            Assert.False(vm.HasUnsavedChanges());
        }

        [Fact]
        public void CommitToVersion_KeepsExternalImagePath_NotNulled()
        {
            // (#386 指摘1) 外部 (gameFolder 外) 画像パスは版へ commit しても null 化されず絶対のまま残る。これにより
            // 版切替 (= 前版への commit) で非選択版の外部画像指定が silent に消えず、保存時に全版まとめて取り込める。
            // 旧実装は ToRel が外部を null 化していた (= 切替で消失)。
            var vm = new EditViewModel(_db, Seed("sigExt", "T", "D"));
            string external = Path.Combine(Path.GetTempPath(), "outside_" + Guid.NewGuid().ToString("N") + ".png");
            vm.ThumbnailPath = external;

            vm.CommitToVersion(vm.SelectedVersion);

            Assert.Equal(external, vm.SelectedVersion.ThumbnailPath);   // 保持 (旧実装は null だった)
        }

        [Fact]
        public void DelimiterShiftBetweenFields_IsDetectedAsDirty()
        {
            // load: Title="A|B", Description="C"。編集で区切り '|' をフィールド間でずらす: Title="A", Description="B|C"。
            // 素朴な "Title|Description" 連結だと両者が "A|B|C" に潰れて未保存を見逃す。長さプレフィックスで弾く (指摘5)。
            var vm = new EditViewModel(_db, Seed("sig2", "A|B", "C"));
            Assert.False(vm.HasUnsavedChanges());

            vm.Title = "A";
            vm.Description = "B|C";
            Assert.True(vm.HasUnsavedChanges());
        }

        [Fact]
        public void NewlineAndDelimiterInDescription_RoundTripsCleanly()
        {
            // 改行・区切り文字を含む説明文でも、無編集なら dirty でない (符号化が描画と対称)。
            var vm = new EditViewModel(_db, Seed("sig3", "T", "line1\nline2|x:y;z~w"));
            Assert.False(vm.HasUnsavedChanges());
            vm.Description = "line1\nline2|x:y;z~w!";   // 末尾に 1 文字足すだけでも検知する
            Assert.True(vm.HasUnsavedChanges());
        }
    }
}
