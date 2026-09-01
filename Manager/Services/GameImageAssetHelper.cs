using System;
using System.IO;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// (#386) ゲームのサムネイル / 背景画像を版フォルダ配下の予約名前空間 <c>&lt;version&gt;/.toneprism/</c> へ
    /// 取り込む共有ヘルパー。ADD/EDIT の WPF 画面 (#242/#324) で共用する想定の共有基盤 (本 PR の配線は EDIT のみ、ADD は #324)。guide の
    /// <see cref="IntroGuideAssetHelper"/> と同流儀 (コピー取り込み + 相対パス保存 + 再利用) だが、games は
    /// <b>役割正規化</b>が肝: コピー先名は元ファイル名でなく役割固定名 <c>thumbnail.&lt;ext&gt;</c> /
    /// <c>background.&lt;ext&gt;</c> にする (予測可能・1 役割 1 ファイル)。
    ///
    /// 設計理由:
    /// - <b>絶対外部パス保存の footgun 回避</b> (#386): 外部画像を naive に扱うと絶対パスが DB に残り (例
    ///   <c>PathConversionHelper.ToRelativePathAfterCopy</c> の「コピー先外は絶対のまま返す」フォールバック)、他 PC /
    ///   ファイルサーバで解決できず壊れる。本 helper は必ず版フォルダ内へコピーし相対パスを返すことでこれを避ける。
    ///   ※ pre-#386 EDIT / 現行 AddGameForm は外部画像を <c>IsPathInside</c> で検証ブロックしていた (= 絶対保存はしない
    ///   代わりに外部取り込み不可)。本 helper は EDIT でその「取り込み解禁」を安全に成立させる (ADD は #324 で移行)。
    /// - <b>予約名前空間 <c>.toneprism/</c></b>: 画像を版フォルダ直下に置くと game 本体ファイルと混在し、役割正規化が
    ///   game の同名アセットを clobber しうる。サブフォルダに隔離して物理分離する。
    /// - <b>copy-not-move</b>: 元画像は消さない (先輩らのゲームに「game 本体が使ってるとも言い切れない画像」を
    ///   サムネ指定したものがあり、move で実行時参照を壊さないため)。
    /// - <b>orphan</b>: 同拡張子の差し替えは <c>overwrite</c> で orphan なし。拡張子が変わると旧役割ファイル
    ///   (例 png→jpg で thumbnail.png) が残る → <b>#348 と地続き</b>で本 PR では掃除しない (= 役割解決は DB の
    ///   保存パスが指す実体で行うため表示は壊れない。dead bytes が残るだけ)。
    /// - Launcher 解決は確認済み (GamePathResolver が <c>games/&lt;id&gt;</c> 起点で相対サブフォルダを path_join 解決、
    ///   読み出しコード変更不要)。保存パスは forward slash で統一 (guide と同・#388 の方向)。
    ///
    /// UI を持たない純ロジック (= 単体テスト可能)。本番 wrapper (<see cref="ImportImage(string,string,ImageRole,string)"/>)
    /// のみ <see cref="PathManager"/> に依存し、コア (<see cref="CopyImageInto(string,ImageRole,string)"/>) は
    /// 版フォルダパスを引数で受ける。
    /// </summary>
    public static class GameImageAssetHelper
    {
        /// <summary>版フォルダ配下の予約サブフォルダ名。game 本体ファイルと画像を物理分離する。</summary>
        public const string ReservedFolderName = ".toneprism";

        /// <summary>画像の役割。コピー先の固定 leaf 名 (拡張子を除く) になる。</summary>
        public enum ImageRole { Thumbnail, Background }

        private static string RoleLeafBase(ImageRole role) => role == ImageRole.Thumbnail ? "thumbnail" : "background";

        /// <summary>
        /// 本番: 選択画像を <c>&lt;games&gt;/&lt;gameId&gt;/v&lt;version&gt;/.toneprism/&lt;role&gt;.&lt;ext&gt;</c> へ取り込み、
        /// DB 保存用の <b>ゲームフォルダ基準の相対パス</b> (<c>v&lt;version&gt;/.toneprism/&lt;role&gt;.&lt;ext&gt;</c>、forward slash) を返す。
        /// </summary>
        public static string ImportImage(string gameId, string version, ImageRole role, string sourceAbsolutePath)
            => ImportImage(gameId, version, role, sourceAbsolutePath, out _);

        /// <summary>
        /// 本番: 上記に加え、新規にコピーしたか (<paramref name="createdNewFile"/>=true)、既に同一実体が所定位置にあり
        /// 複製しなかったか (false) を返す。※現状 games の production caller はこの out 版を使わない (round2 で保存失敗時の
        /// orphan 掃除を撤去＝掃除しない設計にしたため。理由は <see cref="GameImageSaveImporter"/> の doc 参照)。guide 実装
        /// (<see cref="IntroGuideAssetHelper"/>) との対称性 + no-op 検出の単体テスト用に残置。
        /// </summary>
        public static string ImportImage(string gameId, string version, ImageRole role, string sourceAbsolutePath, out bool createdNewFile)
        {
            string versionFolder = PathManager.GetVersionFolder(gameId, version);
            string gameFolder = PathManager.GetGameFolder(gameId);
            string destAbs = CopyImageInto(versionFolder, role, sourceAbsolutePath, out createdNewFile);
            // ゲームフォルダ基準で相対化し forward slash に統一 (Launcher は games/<id> 起点で解決、guide と同方向・#388)。
            return PathConversionHelper.ToRelativePath(gameFolder, destAbs).Replace('\\', '/');
        }

        /// <summary>
        /// (テスト可能コア) <paramref name="sourceAbsolutePath"/> を <c>&lt;versionFolderAbs&gt;/.toneprism/&lt;role&gt;.&lt;ext&gt;</c>
        /// へ取り込み、コピー先の絶対パスを返す。フォルダは無ければ作成。同拡張子は overwrite (orphan なし)。
        /// </summary>
        public static string CopyImageInto(string versionFolderAbs, ImageRole role, string sourceAbsolutePath)
            => CopyImageInto(versionFolderAbs, role, sourceAbsolutePath, out _);

        /// <summary>
        /// (テスト可能コア) 上記に加え、新規コピー (<paramref name="createdNewFile"/>=true) か、source が既にコピー先と
        /// 同一実体で複製不要だったか (false) を返す。後者は EDIT で画像を変えずに再保存したとき
        /// (<c>File.Copy(src, src)</c> が例外になる経路) を no-op にするため。
        /// </summary>
        public static string CopyImageInto(string versionFolderAbs, ImageRole role, string sourceAbsolutePath, out bool createdNewFile)
        {
            if (string.IsNullOrWhiteSpace(sourceAbsolutePath) || !File.Exists(sourceAbsolutePath))
            {
                throw new FileNotFoundException("コピー元の画像が見つかりません。", sourceAbsolutePath ?? "(null)");
            }

            string ext = Path.GetExtension(sourceAbsolutePath).ToLowerInvariant();   // 役割固定名 + 小文字拡張子で予測可能に
            string reservedDir = Path.Combine(versionFolderAbs, ReservedFolderName);
            string destAbs = Path.GetFullPath(Path.Combine(reservedDir, RoleLeafBase(role) + ext));

            // source が既にコピー先と同一実体なら何もしない (Windows は case-insensitive。EDIT 再保存で自分自身を
            // overwrite コピーしようとして File.Copy が throw するのを回避)。
            if (string.Equals(Path.GetFullPath(sourceAbsolutePath), destAbs, StringComparison.OrdinalIgnoreCase))
            {
                createdNewFile = false;
                return destAbs;
            }

            Directory.CreateDirectory(reservedDir);
            File.Copy(sourceAbsolutePath, destAbs, overwrite: true);   // copy-not-move: source は残す
            createdNewFile = true;
            return destAbs;
        }
    }
}
