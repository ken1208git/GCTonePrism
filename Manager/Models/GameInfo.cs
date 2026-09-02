using System;
using System.Collections.Generic;

namespace TonePrism.Manager.Models
{
    /// <summary>
    /// ゲーム情報を表すデータモデル
    /// データベースのgamesテーブルに対応
    /// </summary>
    public class GameInfo
    {
        /// <summary>
        /// ゲームID（一意の識別子）
        /// </summary>
        public string GameId { get; set; }

        /// <summary>
        /// (#297 PR2 / DB v24) ゲームに一度だけ振られる不変の内部番号。
        ///
        /// プレイ記録・アンケートの JSON (`responses/`) はこの番号でゲームを指す。<see cref="GameId"/> は
        /// スタッフが手入力する文字列でフォルダ名を兼ね、改名できてしまうため、JSON に書くと ID 改名で
        /// 過去の記録が全部どのゲームのものか分からなくなる (DB の FK と違い JSON には改名追随の仕組みが無い)。
        ///
        /// **UI には出さない**。部員が触るのは今までどおり <see cref="GameId"/> (「ゲームID」) で、本番号は
        /// 完全に内部専用。ログに出すのは番号を実際に使う処理 (JSON 書込・集計) に限り、
        /// その場合も <c>game_id (no.12)</c> の形で人間が引き当てられるよう併記する。
        ///
        /// 採番は games への INSERT 時のみ (<c>GameRepository.AddGameRowInTransaction</c>)。UPDATE 経路は本値を
        /// 書かないため不変性が構造的に保たれる。v24 migration 前の DB から読んだ場合は null になりうる。
        /// </summary>
        public long? GameNo { get; set; }

        /// <summary>
        /// ゲームタイトル
        /// </summary>
        public string Title { get; set; }

        /// <summary>
        /// 説明文
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// リリース年
        /// </summary>
        public int? ReleaseYear { get; set; }

        /// <summary>
        /// ジャンルのリスト（データベースではJSON形式またはカンマ区切りで保存）
        /// </summary>
        public List<string> Genre { get; set; }

        /// <summary>
        /// 最小プレイヤー数
        /// </summary>
        public int? MinPlayers { get; set; }

        /// <summary>
        /// 最大プレイヤー数
        /// </summary>
        public int? MaxPlayers { get; set; }

        /// <summary>
        /// 難易度（1-3の3段階）
        /// 1: 易しい, 2: 普通, 3: 難しい
        /// </summary>
        public int? Difficulty { get; set; }

        /// <summary>
        /// プレイ時間の分類
        /// 1: ～5分, 2: 5分～15分, 3: 15分以上
        /// </summary>
        public int? PlayTime { get; set; }

        /// <summary>
        /// コントローラーサポート
        /// </summary>
        public bool ControllerSupport { get; set; }
        
        /// <summary>
        /// 通信対戦の対応状況
        /// 0: なし (オフラインのみ)
        /// 1: ローカル通信 (LAN)
        /// 2: オンライン通信 (WAN)
        /// </summary>
        public int SupportedConnection { get; set; }

        /// <summary>
        /// サムネイル画像のパス
        /// </summary>
        public string ThumbnailPath { get; set; }

        /// <summary>
        /// 背景画像のパス
        /// </summary>
        public string BackgroundPath { get; set; }

        /// <summary>
        /// 実行ファイルのパス
        /// </summary>
        public string ExecutablePath { get; set; }

        /// <summary>
        /// 起動オプション（引数）
        /// </summary>
        public string Arguments { get; set; }

        /// <summary>
        /// 表示順序（数値が小さいほど先に表示）
        /// </summary>
        public int? DisplayOrder { get; set; }

        /// <summary>
        /// 表示/非表示
        /// </summary>
        public bool IsVisible { get; set; }

        /// <summary>
        /// 操作説明（JSON形式で保存）
        /// </summary>
        public string Controls { get; set; }

        /// <summary>
        /// キーマッピング設定（JSON形式で保存）
        /// </summary>
        public string KeyMapping { get; set; }

        /// <summary>
        /// 最新バージョン（表示用）
        /// </summary>
        public string Version { get; set; }

        /// <summary>
        /// 製作者リスト（データベースではdevelopersテーブルとして分離）
        /// </summary>
        public List<DeveloperInfo> Developers { get; set; }

        /// <summary>
        /// 製作者情報の表示用文字列（DataGridView用）
        /// 「姓 名 (期生)」形式で複数の製作者をカンマ区切りで表示
        /// </summary>
        public string DevelopersDisplay
        {
            get
            {
                if (Developers == null || Developers.Count == 0)
                {
                    return "";
                }

                var displayList = new List<string>();
                foreach (var dev in Developers)
                {
                    string display = dev.FullName;
                    if (!string.IsNullOrEmpty(dev.GradeDisplay))
                    {
                        display += " (" + dev.GradeDisplay + ")";
                    }
                    displayList.Add(display);
                }

                return string.Join(", ", displayList);
            }
        }

        /// <summary>
        /// コンストラクタ
        /// </summary>
        public GameInfo()
        {
            Genre = new List<string>();
            Developers = new List<DeveloperInfo>();
            ControllerSupport = false;
            IsVisible = true;
        }
    }
}

