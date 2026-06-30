using System.IO;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// (#386 / #242 共通化③) 保存時にゲーム画像 (thumbnail/background) を版フォルダの <c>.toneprism/</c> へ取り込む共通ロジック。
    /// ADD/EDIT の保存フローから呼ぶ (旧 EditGamePage の「外部画像はブロック」直書きを置換し共有化、CLAUDE.md「UI は薄く、ロジックは外へ」)。
    ///
    /// 版オブジェクトの画像パス (相対=既に内部 / 絶対外部=未取り込み) を受け、外部なら <see cref="GameImageAssetHelper"/> で取り込み、
    /// gameFolder 基準の<b>相対パス</b> (forward slash) を返す。以降は既存フローがそのまま正しく扱う:
    /// - <c>.toneprism/</c> は版 leaf の直下 (<c>v&lt;leaf&gt;/.toneprism/...</c>) なので、版 rename の
    ///   <c>VersionFolderRenameService.ReplaceVersionPrefix</c> (先頭 <c>v&lt;leaf&gt;/</c> 書換) と整合する。
    /// - gameFolder 内 (legacy の非 .toneprism 含む) は触らない = 既存データはそのまま、外部だけ取り込む最小変更。
    ///
    /// <b>保存 abort 時に取り込みファイルを削除しないこと (#386 指摘1)</b>: 削除すると、非選択版の in-memory パスは既に相対化
    /// 済 (= VM に元の絶対パスが無く復元できない) なので dangling になり、retry 時に「相対=内部済」とみなされ再取り込みされず、
    /// 欠落ファイルを指す相対パスが保存成功してしまう (silent loss)。ファイルを残せば retry でその相対パスが実体を解決して
    /// 正常保存できる。abort 後に放棄した場合の <c>.toneprism</c> 内 orphan は役割固定名の dead bytes (#348 地続き) で無害。
    ///
    /// VM 非依存 (paths を受けて paths を返す) = Services が Shell に依存せず、単体テスト容易・ADD/EDIT 双方から同形で使える。
    /// </summary>
    public static class GameImageSaveImporter
    {
        /// <summary>
        /// 版オブジェクトの画像パス (相対=既に内部 / 絶対外部=未取り込み) を受け、外部なら
        /// <c>&lt;gameId&gt;/v&lt;diskVersion&gt;/.toneprism/&lt;role&gt;.&lt;ext&gt;</c> へ取り込み、gameFolder 基準の<b>相対パス</b>
        /// (forward slash) を返す。相対 (既に内部) はそのまま返す。保存フローが全版に適用する想定
        /// (#386 指摘1: CommitToVersion が外部画像を絶対のまま残すので、選択版だけでなく全版を取り込む)。
        /// </summary>
        /// <param name="versionImagePath">版オブジェクトの画像パス (相対 or 絶対外部)。</param>
        /// <param name="gameId">取り込み先のゲーム ID (rename 前 = ディスク上の現 ID)。</param>
        /// <param name="diskVersion">取り込み先の版文字列 (rename 前 = ディスク上の現 leaf)。</param>
        /// <param name="role">thumbnail / background。</param>
        /// <param name="imported">実際に外部画像を <c>.toneprism/</c> へコピーした場合 true (= games/ に新バイト書込。
        /// caller は assetsChanged を立ててアセットバックアップ対象にする。round3 指摘1: 画像のみ編集で rename 無しの保存が
        /// DB-only バックアップになり、その世代から復元すると画像欠落する gap を防ぐ)。相対/内部/空は false。</param>
        public static string ImportIfExternalToRelative(string versionImagePath, string gameId, string diskVersion,
            GameImageAssetHelper.ImageRole role, out bool imported)
        {
            imported = false;
            if (string.IsNullOrWhiteSpace(versionImagePath)) return versionImagePath;
            if (!Path.IsPathRooted(versionImagePath)) return versionImagePath;   // 相対 = 既に内部 (DB 保存形)、そのまま

            string gameFolder = PathManager.GetGameFolder(gameId);
            if (PathConversionHelper.IsPathInside(gameFolder, versionImagePath))
                return PathConversionHelper.ToRelativePath(gameFolder, versionImagePath).Replace('\\', '/');   // 内部絶対 → 相対化 (防御的)

            imported = true;   // 外部 = 必ずコピー (外部パスが取り込み先 = gameFolder 内に一致することは無い)
            return GameImageAssetHelper.ImportImage(gameId, diskVersion, role, versionImagePath);   // 外部 → 取り込み (forward slash 相対)
        }
    }
}
