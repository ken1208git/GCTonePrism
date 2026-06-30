using System;
using System.Collections.Generic;
using System.IO;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// (#386 / #242 共通化③) 保存時にゲーム画像 (thumbnail/background) を版フォルダの <c>.toneprism/</c> へ取り込む共通ロジック。
    /// ADD/EDIT の保存フローから呼ぶ (旧 EditGamePage の「外部画像はブロック」直書きを置換し共有化、CLAUDE.md「UI は薄く、ロジックは外へ」)。
    ///
    /// 選択版の画像が gameFolder の外 (= 外部選択) なら <see cref="GameImageAssetHelper"/> で取り込み、内部の絶対パスを返す。
    /// 以降は既存フローがそのまま正しく扱う:
    /// - <c>CommitToVersion</c> の <c>ToRel</c> が gameFolder 基準で相対化 (内部化済なので null 落ちしない)。
    /// - 版 rename の <c>VersionFolderRenameService.ReplaceVersionPrefix</c> が先頭 <c>v&lt;leaf&gt;/</c> を書換。<c>.toneprism/</c> は
    ///   版 leaf の直下 (= <c>v&lt;leaf&gt;/.toneprism/...</c>) なので prefix 書換と整合する。
    /// gameFolder 内 (legacy の非 .toneprism 含む) は触らない = 既存データはそのまま、外部だけ取り込む最小変更。
    ///
    /// VM 非依存 (paths を受けて paths を返す) = Services が Shell に依存せず、単体テスト容易・ADD/EDIT 双方から同形で使える。
    /// </summary>
    public static class GameImageSaveImporter
    {
        /// <summary>
        /// <paramref name="imagePath"/> が gameFolder 外なら <c>&lt;gameId&gt;/v&lt;diskVersion&gt;/.toneprism/&lt;role&gt;.&lt;ext&gt;</c> へ取り込み、
        /// 取り込み後の内部絶対パスを返す。内部 / 空はそのまま返す。新規コピーした場合のみ <paramref name="createdAbsPathOrNull"/> に
        /// その絶対パスを入れる (= 保存失敗時の best-effort 掃除対象。既存ファイル再利用や no-op のときは null)。
        /// </summary>
        /// <param name="imagePath">VM の画像パス (絶対・外部もありうる)。</param>
        /// <param name="gameId">取り込み先のゲーム ID (rename 前 = ディスク上の現 ID)。</param>
        /// <param name="diskVersion">取り込み先の版文字列 (rename 前 = ディスク上の現 leaf)。</param>
        /// <param name="role">thumbnail / background。</param>
        public static string ImportIfExternal(string imagePath, string gameId, string diskVersion,
            GameImageAssetHelper.ImageRole role, out string createdAbsPathOrNull)
        {
            createdAbsPathOrNull = null;
            if (string.IsNullOrWhiteSpace(imagePath)) return imagePath;

            string gameFolder = PathManager.GetGameFolder(gameId);
            if (PathConversionHelper.IsPathInside(gameFolder, imagePath)) return imagePath;   // 既に内部 = 既存フローに委ねる

            string rel = GameImageAssetHelper.ImportImage(gameId, diskVersion, role, imagePath, out bool created);
            string abs = PathConversionHelper.ToAbsolutePath(gameFolder, rel);
            if (created) createdAbsPathOrNull = abs;
            return abs;
        }

        /// <summary>
        /// (best-effort) 保存失敗時に取り込み済ファイルを掃除する。rename を跨いで元位置に無い場合は skip する
        /// (役割固定名 <c>&lt;role&gt;.&lt;ext&gt;</c> なので、残っても次回保存で上書きされ self-heal する)。掃除失敗は致命ではないので握り潰す。
        /// </summary>
        public static void CleanupBestEffort(IEnumerable<string> createdAbsPaths)
        {
            if (createdAbsPaths == null) return;
            foreach (var p in createdAbsPaths)
            {
                if (string.IsNullOrEmpty(p)) continue;
                try { if (File.Exists(p)) File.Delete(p); }
                catch { /* best-effort: 掃除失敗は self-heal に委ねる */ }
            }
        }
    }
}
