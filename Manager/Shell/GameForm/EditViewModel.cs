using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using TonePrism.Manager;
using TonePrism.Manager.Controls;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;

namespace TonePrism.Manager.Shell.GameForm
{
    /// <summary>
    /// (#324 PR1) ゲーム編集の WPF bindable state。<see cref="GameFormViewModel"/>(共通コア) に版管理を足す。
    /// 旧 EditGameForm の LoadVersions / LoadGameDataForVersion / SaveGameDataToVersion を移植し、
    /// 「版切替で前版へ commit → 新版を load」を <see cref="SelectedVersion"/> setter に集約する。
    ///
    /// 移植の方針:
    /// - **アクティブ版フォールバック**(旧初期版行の空フィールドを games 行値で healing) は本物のドメインロジックなので保存。
    ///   active 判定は version 文字列比較でなく **DB id 比較** (rename 後も維持、#234/#158 round 7 M-2)。
    /// - 人数/難易度/時間/年を <c>int?</c> 直持ちにしたことで WinForms の null 保護スナップショット glue は不要に。
    /// - 範囲外の破損 DB 値 (人数 0/200 等) は load 時に [1,99] 等へ clamp。旧は「clamp 値を書き戻さない」snapshot 保護が
    ///   あったが、それを再現するとスナップショット復活で int? 化の意味が消えるため PR1 では簡素化 (= 破損は保存時に healing)。
    /// - 外部画像 (gameFolder 外の選択) は保存時に <c>.toneprism/</c> へ取り込む (#386)。<see cref="CommitToVersion"/> は外部画像を
    ///   null 化せず絶対のまま保持し (<c>ToRelOrKeepExternal</c>)、取り込みオーケストレーションは EditGamePage が全版に対して行う。
    /// 保存オーケストレーション(旧 btnOK_Click) は EditGamePage 側に置き、抽出済み service を呼ぶ。
    /// </summary>
    public class EditViewModel : GameFormViewModel
    {
        public const int PlayerMin = 1;
        public const int PlayerMax = 99;

        private readonly DatabaseManager _db;

        public GameInfo OriginalGame { get; }
        public string GameFolder { get; private set; }

        public ObservableCollection<GameVersion> Versions { get; } = new ObservableCollection<GameVersion>();

        /// <summary>初期選択 = 起動対象 (games.version 一致) 版の DB id。OK 時のアクティブ版切替検出 + load 時の healing 判定基準。</summary>
        public int? InitialSelectedVersionId { get; private set; }

        /// <summary>LoadVersions 時点の DB-fetched version 文字列 (id→ver)。版フォルダ rename 検出 / disk leaf 解決の SoT。</summary>
        public Dictionary<int, string> OriginalVersionByDbId { get; } = new Dictionary<int, string>();

        /// <summary>SemVer 不正な version (load 時に警告表示するため page が読む。"  - id=N: 'ver'" 形式)。</summary>
        public List<string> MalformedVersionsOnLoad { get; } = new List<string>();

        /// <summary>不正 version の集約警告を EditGamePage が一度だけ出すためのフラグ。VM 単位 (= 編集 1 回単位) で
        /// 持つことで、NavigationView がページを type 単位で cache・再利用しても別ゲーム編集で再警告できる
        /// (ページインスタンス固定フラグだと 2 ゲーム目以降で警告が抑止される)。</summary>
        public bool MalformedWarningShown { get; set; }

        // ===== 版固有フィールド (共通コアに無いもの) =====
        private string _versionName;   // semver 文字列 (SemverInput が parse/format)
        public string VersionName { get => _versionName; set => SetField(ref _versionName, value); }

        private string _versionUpdateNote;
        public string VersionUpdateNote { get => _versionUpdateNote; set => SetField(ref _versionUpdateNote, value); }

        private GameVersion _selectedVersion;
        public GameVersion SelectedVersion
        {
            get => _selectedVersion;
            set
            {
                if (ReferenceEquals(_selectedVersion, value)) return;
                // 切替前に現版へ in-memory commit (旧 cmbVersionList_SelectedIndexChanged の commit→load)。
                if (_selectedVersion != null) CommitToVersion(_selectedVersion);
                _selectedVersion = value;
                Raise();
                if (_selectedVersion != null) LoadFromVersion(_selectedVersion);
            }
        }

        public EditViewModel(DatabaseManager db, GameInfo game)
        {
            _db = db ?? throw new ArgumentNullException(nameof(db));
            OriginalGame = game ?? throw new ArgumentNullException(nameof(game));
            GameFolder = PathManager.GetGameFolder(game.GameId);
            GameId = game.GameId;          // slug 手入力 (編集可)
            IsVisible = game.IsVisible;
            // 破損 DB の範囲外 release_year (手書き SQL / 旧 schema 由来。例 0 / 9999) は NumberBox の範囲 [1970,3000] と
            // ズレて「表示クランプ値 ≠ VM 生値」になり破損値を温存する。範囲外は「不明」に倒す (旧 EditGameForm 踏襲)。
            bool yearInRange = game.ReleaseYear.HasValue && game.ReleaseYear.Value >= 1970 && game.ReleaseYear.Value <= 3000;
            ReleaseYear = yearInRange ? game.ReleaseYear : (int?)null;
            ReleaseYearUnknown = !yearInRange;
            LoadVersions();
            _originalSignature = ComputeStateSignature();   // (#383) load 完了時の状態を未保存判定の基準にする。
        }

        // ===== (#383) 未保存判定: load 時スナップショットとの比較 =====
        // フィールド単位の dirty フラグだと「変更 → 元に戻す」で false dirty になる。保存対象の状態 (ゲーム項目 +
        // 全版 + 選択版 + 製作者) を canonical 文字列化し、load 時と比較する。正規化済データなら版の閲覧切替も戻せば
        // 一致する (CommitToVersion 往復が冪等)。非正規化の legacy 版 (外部/絶対パス・null 人数等) を閲覧すると版切替の
        // commit で正規化が焼いて署名が食い違い「未保存」と出うるが、安全側 (確認が出るだけ・データ損失なし) なので許容
        // (本番データは #386 で正規化済 = ほぼ発生しない。非破壊な対称署名化での恒久対応は #394 で追跡)。
        // ※全版を基準時に正規化する案 (旧 NormalizeAllVersionsForBaseline) は不採用: 保存対象の版オブジェクトを破壊的に
        //   正規化し、ToRel が非選択版の外部パスを silent に null 化して保存に乗せる (silent データ消失) ため (#383 レビュー指摘1)。
        private string _originalSignature;

        /// <summary>現在の編集状態が load 時から実質的に変わっているか (戻る時の確認要否)。
        /// ※意図的な副作用あり・離脱直前専用: <see cref="ComputeStateSignature"/> が表示中版へ in-memory commit する
        ///   (= 署名が「いま保存したら DB に乗る内容」と一致する対称性を保つため)。冪等なので連続呼び出しは安全だが、
        ///   保存ボタン活性制御や定期 dirty チェックなど別文脈から呼ぶと閲覧中の版が黙って正規化される。新たな呼び出し
        ///   元を足すときは非破壊化を検討すること (#383 指摘7)。</summary>
        public bool HasUnsavedChanges() => ComputeStateSignature() != _originalSignature;

        /// <summary>(#383) 保存成功時に基準を現在状態へ更新し、以降は未保存なし扱いにする (保存直後の GoBack で離脱割り込みが再確認しないように)。</summary>
        public void MarkSaved() => _originalSignature = ComputeStateSignature();

        private string ComputeStateSignature()
        {
            // 表示中版へ in-memory commit してから全版 + ゲーム項目を直列化 (load 時と同手順で対称比較。正規化 = trim/
            // 人数コアース/Grade 整形も両側で同じく効くため、保存しても変わらない編集は「未保存」と判定されない)。
            if (_selectedVersion != null) CommitToVersion(_selectedVersion);
            var sb = new System.Text.StringBuilder();
            // 自由入力文字列は Field() で長さプレフィックス付き連結する。区切り文字 (| / : 改行等) が Title/Description/
            // Genre 名/製作者名などに含まれても、異なる状態が同一署名へ潰れない (= false-negative で未保存を無確認破棄
            // する事故) を構造的に防ぐ (#383 指摘5)。数値/bool は区切り文字を含み得ないので素で append してよい。
            sb.Append("year=").Append(ReleaseYearUnknown ? "?" : ReleaseYear?.ToString())
              .Append("|vis=").Append(IsVisible)
              .Append("|sel=").Append(_selectedVersion?.Id ?? -1).Append("|gid=");
            Field(sb, GameId);
            sb.Append('\n');
            foreach (var v in Versions.OrderBy(x => x.Id))
            {
                sb.Append(v.Id).Append(':');
                Field(sb, v.Version); Field(sb, v.Title); Field(sb, v.Description);
                Field(sb, v.Arguments); Field(sb, v.UpdateNote);
                sb.Append(v.Genre?.Count ?? -1).Append(':');
                if (v.Genre != null) foreach (var g in v.Genre) Field(sb, g);
                sb.Append(v.MinPlayers).Append('/').Append(v.MaxPlayers).Append('|')
                  .Append(v.Difficulty).Append('|').Append(v.PlayTime).Append('|')
                  .Append(v.ControllerSupport).Append('|').Append(v.SupportedConnection).Append('|');
                Field(sb, v.ExecutablePath); Field(sb, v.ThumbnailPath); Field(sb, v.BackgroundPath);
                sb.Append(v.Developers?.Count ?? -1).Append(':');
                if (v.Developers != null)
                    foreach (var d in v.Developers) { Field(sb, d.LastName); Field(sb, d.FirstName); Field(sb, d.Grade); }
                sb.Append('\n');
            }
            return sb.ToString();
        }

        // 長さプレフィックス連結 ("<len>:<value>|")。value に区切り文字が含まれても境界が一意に定まり、異なる状態が
        // 同じ署名へ衝突しない (injective)。署名はメモリ内比較専用なので parse はしない (衝突回避だけが目的・#383 指摘5)。
        private static void Field(System.Text.StringBuilder sb, string s)
            => sb.Append(s?.Length ?? -1).Append(':').Append(s).Append('|');

        private bool IsActive(GameVersion v) => InitialSelectedVersionId.HasValue && v != null && v.Id == InitialSelectedVersionId.Value;

        /// <summary>gameId rename 成功後に in-memory 状態を新 ID へ追従させる (GameFolder + 全版の GameId)。
        /// 版フォルダ rename はこの新 GameFolder を base に走るため、gameId rename の効果を取り込む (#158 H1 と同趣旨)。</summary>
        public void ApplyGameIdRename(string newGameId, string newFolder)
        {
            GameFolder = newFolder;
            GameId = newGameId;
            foreach (var v in Versions) v.GameId = newGameId;
        }

        private void LoadVersions()
        {
            OriginalVersionByDbId.Clear();
            Versions.Clear();
            MalformedVersionsOnLoad.Clear();
            var versions = _db.GetGameVersions(OriginalGame.GameId);
            foreach (var v in versions)
            {
                Versions.Add(v);
                OriginalVersionByDbId[v.Id] = v.Version;
                if (!SemverInputControl.TryNormalize(v.Version ?? "", out _))
                    MalformedVersionsOnLoad.Add("  - id=" + v.Id + ": '" + (v.Version ?? "(null)") + "'");
            }

            // 起動対象版 = games.version と一致する版 (OrdinalIgnoreCase、rename normalize 揺れ吸収)。無ければ先頭 (最新)。
            GameVersion initial = null;
            if (OriginalGame.Version != null)
                initial = Versions.FirstOrDefault(v => string.Equals(v.Version, OriginalGame.Version, StringComparison.OrdinalIgnoreCase));
            if (initial == null && Versions.Count > 0) initial = Versions[0];

            // InitialSelectedVersionId は SelectedVersion 設定 (= LoadFromVersion) より前に確定させる
            // (旧 #158 H2: active 判定を初回 load から有効にして healing 非対称を防ぐ)。
            InitialSelectedVersionId = initial?.Id;
            if (initial != null) SelectedVersion = initial;   // setter が LoadFromVersion を呼ぶ
        }

        /// <summary>版 → VM フィールド (アクティブ版は空欄を games 行値でフォールバック healing)。</summary>
        private void LoadFromVersion(GameVersion v)
        {
            bool active = IsActive(v);
            VersionName = v.Version ?? "";

            Title = !string.IsNullOrWhiteSpace(v.Title) ? v.Title : (active ? (OriginalGame.Title ?? "") : "");
            Description = !string.IsNullOrWhiteSpace(v.Description) ? v.Description : (active ? OriginalGame.Description : null);
            Arguments = !string.IsNullOrWhiteSpace(v.Arguments) ? v.Arguments : (active ? OriginalGame.Arguments : null);
            VersionUpdateNote = v.UpdateNote ?? "";

            var genre = (v.Genre != null && v.Genre.Count > 0) ? v.Genre : (active ? OriginalGame.Genre : null);
            SelectedGenres.Clear();
            if (genre != null) foreach (var g in genre) SelectedGenres.Add(g);

            // プレイ人数は常に数値 (旧 WinForms の NumericUpDown 同様、不明=null 不可)。DB が null でも 1 にコアース。
            // 範囲 [1,99] は load 時クランプ。ただし min>max の破損は連動クランプを抑止して温存し (SetPlayerCountsForLoad)、
            // 保存時に GameVersionSetValidator.PlayerCountViolations でブロック → ユーザーに直させる。連動クランプを load 時に
            // 効かせると「閲覧しただけで 5/3 → 3/3 に silent heal」して検証が dead になるため (#324 PR1 レビュー C-1)。
            SetPlayerCountsForLoad(
                ClampPlayer(v.MinPlayers ?? (active ? OriginalGame.MinPlayers : null)) ?? 1,
                ClampPlayer(v.MaxPlayers ?? (active ? OriginalGame.MaxPlayers : null)) ?? 1);
            Difficulty = ValidLevel(v.Difficulty) ?? (active ? ValidLevel(OriginalGame.Difficulty) : null);
            PlayTime = ValidLevel(v.PlayTime) ?? (active ? ValidLevel(OriginalGame.PlayTime) : null);
            // 通信/コントローラは非 nullable で「未設定」を判別できないため、アクティブ版は games 行 (mirror=真値) を採用。
            // 破損 DB の範囲外値 (手書き SQL / 旧 schema 由来) は 0-2 にクランプ。これが無いと ComboBox.SelectedIndex が
            // 範囲外 → WPF が -1 を書き戻し → 保存で -1 格納の恐れ (旧 LoadGameDataForVersion の connToShow クランプを踏襲)。
            SupportedConnection = ClampConnection(active ? OriginalGame.SupportedConnection : v.SupportedConnection);
            ControllerSupport = active ? OriginalGame.ControllerSupport : v.ControllerSupport;

            string exe = !string.IsNullOrEmpty(v.ExecutablePath) ? v.ExecutablePath : (active ? OriginalGame.ExecutablePath : null);
            string thumb = !string.IsNullOrEmpty(v.ThumbnailPath) ? v.ThumbnailPath : (active ? OriginalGame.ThumbnailPath : null);
            string bg = !string.IsNullOrEmpty(v.BackgroundPath) ? v.BackgroundPath : (active ? OriginalGame.BackgroundPath : null);
            ExecutablePath = string.IsNullOrEmpty(exe) ? "" : PathConversionHelper.ToAbsolutePath(GameFolder, exe);
            ThumbnailPath = string.IsNullOrEmpty(thumb) ? "" : PathConversionHelper.ToAbsolutePath(GameFolder, thumb);
            BackgroundPath = string.IsNullOrEmpty(bg) ? "" : PathConversionHelper.ToAbsolutePath(GameFolder, bg);

            // Developers (版が空ならアクティブ版に限り games の製作者をディープコピー。Id は引き継がない)。
            // カードでインライン編集するため DeveloperEditViewModel に wrap (Grade 文字列 ↔ 数値+不明/教員)。
            Developers.Clear();
            var devs = (v.Developers != null && v.Developers.Count > 0) ? v.Developers
                       : (active ? OriginalGame.Developers : null);
            if (devs != null)
                foreach (var d in devs)
                    Developers.Add(new DeveloperEditViewModel(d));
        }

        /// <summary>VM フィールド → 版 (deep-copy developers / 画像は gameFolder 基準で相対化)。版切替前・保存前に呼ぶ。</summary>
        public void CommitToVersion(GameVersion v)
        {
            if (v == null) return;
            v.Version = string.IsNullOrWhiteSpace(VersionName) ? v.Version : VersionName.Trim();
            v.Title = (Title ?? "").Trim();
            v.Description = string.IsNullOrWhiteSpace(Description) ? null : Description.Trim();
            v.Arguments = string.IsNullOrWhiteSpace(Arguments) ? null : Arguments.Trim();
            v.UpdateNote = string.IsNullOrWhiteSpace(VersionUpdateNote) ? null : VersionUpdateNote.Trim();
            v.Genre = SelectedGenres.ToList();
            v.MinPlayers = MinPlayers ?? 1;   // プレイ人数は常に数値で保存 (編集中に空にされても 1 に倒す)
            v.MaxPlayers = MaxPlayers ?? 1;
            v.Difficulty = Difficulty;
            v.PlayTime = PlayTime;
            v.ControllerSupport = ControllerSupport;
            v.SupportedConnection = SupportedConnection;
            v.ExecutablePath = ToRel(ExecutablePath);
            // 画像は外部 (gameFolder 外) パスを null 化せず絶対のまま保持する。版切替でも消えず、保存時に
            // GameImageSaveImporter が全版まとめて .toneprism へ取り込む (#386 指摘1: 非選択版の外部画像 silent loss 防止)。
            v.ThumbnailPath = ToRelOrKeepExternal(ThumbnailPath);
            v.BackgroundPath = ToRelOrKeepExternal(BackgroundPath);
            // 姓名どちらも空のカード (未入力で追加されただけ) は除外して保存。
            v.Developers = Developers
                .Where(d => !d.IsBlank)
                .Select(d => d.ToModel())
                .ToList();
        }

        // gameFolder 基準で相対化。gameFolder 外 / 空は null (exe 用。外部 exe は保存時 step2 でブロック済)。
        private string ToRel(string abs)
        {
            if (string.IsNullOrWhiteSpace(abs)) return null;
            if (!PathConversionHelper.IsPathInside(GameFolder, abs)) return null;
            return PathConversionHelper.ToRelativePath(GameFolder, abs.Trim());
        }

        // 画像用: gameFolder 内は相対化、外は絶対のまま保持 (保存時に全版を GameImageSaveImporter で .toneprism へ取り込む)。
        // ToRel と違い外部を null 化しない = 版切替で非選択版の外部画像指定が silent に消えるのを防ぐ (#386 指摘1)。
        private string ToRelOrKeepExternal(string abs)
        {
            if (string.IsNullOrWhiteSpace(abs)) return null;
            if (!PathConversionHelper.IsPathInside(GameFolder, abs)) return abs.Trim();
            return PathConversionHelper.ToRelativePath(GameFolder, abs.Trim());
        }

        private static int? ClampPlayer(int? v) => v.HasValue ? Math.Max(PlayerMin, Math.Min(PlayerMax, v.Value)) : (int?)null;
        private static int? ValidLevel(int? v) => (v.HasValue && v.Value >= 1 && v.Value <= 3) ? v : (int?)null;
        private static int ClampConnection(int v) => (v >= 0 && v <= 2) ? v : 0;   // なし/ローカル/オンライン の 3 値
    }
}
