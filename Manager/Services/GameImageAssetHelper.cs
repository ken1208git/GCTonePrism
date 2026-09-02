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
    ///   (例 png→jpg で thumbnail.png) が残るが、保存<b>成功後</b>に <see cref="CleanupStaleRoleFiles"/> で
    ///   その版の現行 thumbnail/background 以外の役割ファイルを掃除する (#348。1 つの .toneprism を参照するのはその 1 版
    ///   だけなので、その版の 2 パスだけ見れば安全)。※取り込み時 (保存確定前) に消すと abort で旧画像消失 + DB dangling
    ///   になるため必ず成功後に行う (#417 と同根)。
    /// - Launcher 解決は確認済み (GamePathResolver が <c>games/&lt;id&gt;</c> 起点で相対サブフォルダを path_join 解決、
    ///   読み出しコード変更不要)。<b>取り込み時</b>の保存パスは forward slash (guide と同方向)。※既存内部パスの再保存は
    ///   <c>ToRel</c> が backslash を返すため区切りは混在しうる (Windows は両方解決可・完全統一は #388)。
    /// - <b>検証責務は caller</b> (round7 指摘6): 拡張子・存在の検証は本 helper でなく caller が行う (EDIT は手順4c で全版検証)。
    ///   helper は取り込みに専念する。ADD (#324) 配線時も同等の事前検証を入れること (拡張子無しファイルは <c>thumbnail</c>
    ///   のような拡張子なし名で取り込まれてしまうため)。
    /// - <b>版フォルダを作成しうる</b> (round7 指摘10): <see cref="CopyImageInto"/> の <c>Directory.CreateDirectory</c> が
    ///   <c>.toneprism</c> と<b>親の版フォルダ</b>を作る。DB にあるが disk 不在の版に取り込むと版フォルダが materialize され、
    ///   後続の版 rename 判定 (SourceExists) に影響しうる (#417)。
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
            string rel = PathConversionHelper.ToRelativePath(gameFolder, destAbs).Replace('\\', '/');
            // (#386 round6 指摘7) ToRelativePath は基準フォルダ外だと警告なしで絶対を返す silent fallback を持つ。gameId の末尾
            // 空白やセパレータ差で GetGameFolder/GetVersionFolder が食い違うと絶対パスが DB に流入し、#386 が潰した footgun が
            // silent 復活する。相対化に失敗したら例外にして呼び出し側の取り込みエラーダイアログ経路に載せる (silent を許さない)。
            if (Path.IsPathRooted(rel))
            {
                Logger.Error("[GameImageAssetHelper] (#386) 取り込み画像の相対化に失敗 (絶対のまま)。gameFolder=" + gameFolder + " dest=" + destAbs);
                throw new InvalidOperationException("画像の取り込み先パスを相対化できませんでした (gameId / version の不整合の可能性)。");
            }
            return rel;
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

        /// <summary>
        /// (#386) 保存<b>成功後</b>に呼ぶ orphan 掃除。各版の <c>.toneprism</c> 内の役割ファイル (<c>thumbnail.*</c> /
        /// <c>background.*</c>) のうち、<b>どの版のどの役割からも参照されていない</b>ものを削除する (拡張子変更後の旧ファイル等)。
        /// 「1 つの .toneprism ← 1 版」は本来の運用不変条件だが強制されていない (パス欄は自由入力・別版フォルダも選べる) ため、
        /// <b>削除は不可逆</b>ゆえ防御的に「全版の thumbnail/background 相対パスを keep セットにし、<b>ファイル名でなく完全な
        /// 相対パス</b>で照合」する (= 版跨ぎ参照や legacy 直下配置があっても live を消さない。SPEC §機能3 の旧規約「他版が
        /// 参照しうるので旧画像は削除禁止」の意図を実装で満たす)。best-effort (個々の削除失敗は握り潰す＝残っても dead bytes)。
        /// <b>※必ず保存確定 (DB write 成功) 後に呼ぶこと</b>: 取り込み時に消すと abort で旧画像消失 + DB dangling になる (#417 と同根)。
        /// guide 側の同種 orphan は #348。
        /// </summary>
        /// <param name="gameFolder">ゲームフォルダ (rename 後の live 値)。</param>
        /// <param name="versions">走査する版文字列 (各版の .toneprism を特定するため)。</param>
        /// <param name="liveRelativePaths">全版の thumbnail/background 相対パス (= 参照されている = 残すべきファイル)。区切りは正規化して扱う。</param>
        public static void CleanupStaleRoleFiles(string gameFolder, System.Collections.Generic.IEnumerable<string> versions,
            System.Collections.Generic.IEnumerable<string> liveRelativePaths)
        {
            if (string.IsNullOrWhiteSpace(gameFolder) || versions == null) return;
            var live = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (liveRelativePaths != null)
                foreach (var p in liveRelativePaths)
                    if (!string.IsNullOrWhiteSpace(p)) live.Add(p.Replace('\\', '/'));

            foreach (var version in versions)
            {
                if (string.IsNullOrWhiteSpace(version)) continue;
                try
                {
                    string leaf = PathManager.GetVersionFolderLeaf(version);
                    string reservedDir = Path.Combine(gameFolder, leaf, ReservedFolderName);
                    if (!Directory.Exists(reservedDir)) continue;
                    foreach (var file in Directory.GetFiles(reservedDir))
                    {
                        string stem = Path.GetFileNameWithoutExtension(file);
                        if (!string.Equals(stem, RoleLeafBase(ImageRole.Thumbnail), StringComparison.OrdinalIgnoreCase)
                            && !string.Equals(stem, RoleLeafBase(ImageRole.Background), StringComparison.OrdinalIgnoreCase))
                            continue;   // 役割ファイル (thumbnail/background) 以外は触らない
                        string rel = leaf + "/" + ReservedFolderName + "/" + Path.GetFileName(file);   // 完全な相対パスで照合 (ファイル名だけだと別版/legacy 直下の同名を誤判定)
                        if (live.Contains(rel)) continue;   // どれかの版が参照 = 残す
                        try { File.Delete(file); }
                        catch (Exception delEx) { Logger.Warn("[GameImageAssetHelper] (#386) orphan 削除失敗 (無害・dead bytes 残置): " + file + " — " + delEx.Message); }
                    }
                }
                catch (Exception verEx)
                {
                    // (round7 指摘5) 列挙失敗 (権限/ロック) は当該版だけ skip し、残り版の掃除は続ける (握り潰さない=CLAUDE.md §例外作法)。
                    Logger.Warn("[GameImageAssetHelper] (#386) 版 '" + version + "' の orphan 掃除を skip (列挙失敗): " + verEx.Message);
                }
            }
        }
    }
}
