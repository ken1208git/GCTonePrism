## ゲーム情報を表すデータモデル
## データベースのgamesテーブルに対応

extends RefCounted
class_name GameInfo

## ゲームID（一意の識別子）
## スタッフが Manager で手入力する文字列。games/<game_id>/ のフォルダ名も兼ねる。改名しうる。
var game_id: String = ""

## (#297 PR2 / DB v24) ゲームに一度だけ振られる不変の内部番号。
## プレイ記録・アンケートの JSON はこの番号でゲームを指す（game_id は改名できてしまい、
## JSON には DB の FK のような改名追随の仕組みが無いため）。
## 来場者向け UI には出さない。ログに出すのは番号を実際に使う処理だけで、その場合も
## `game_id (no.12)` の形で人間が引き当てられるよう併記する。
## -1 = 未採番 / v24 前の DB（この場合プレイ記録は書き出さない）。
var game_no: int = -1

## ゲームタイトル
var title: String = ""

## 説明文
var description: String = ""

## リリース年
var release_year: int = -1

## ジャンルのリスト（データベースではJSON形式またはカンマ区切りで保存）
var genre: Array[String] = []

## 最小プレイヤー数
var min_players: int = -1

## 最大プレイヤー数
var max_players: int = -1

## 難易度（1-3の3段階）
## 1: 易しい, 2: 普通, 3: 難しい
var difficulty: int = -1

## プレイ時間の分類
## 1: ～5分, 2: 5分～15分, 3: 15分以上
var play_time: int = -1

## コントローラーサポート
var controller_support: bool = false

## 通信対戦の対応状況
## 0: なし (オフラインのみ)
## 1: ローカル通信 (LAN)
## 2: オンライン通信 (WAN)
var supported_connection: int = 0

## サムネイル画像のパス（相対パス：games/{game_id}/フォルダからの相対パス）
var thumbnail_path: String = ""

## 背景画像のパス（相対パス：games/{game_id}/フォルダからの相対パス）
var background_path: String = ""

## 実行ファイルのパス（相対パス：games/{game_id}/フォルダからの相対パス）
var executable_path: String = ""

## 表示順序（数値が小さいほど先に表示）
var display_order: int = -1

## 表示/非表示
var is_visible: bool = true

## 操作説明（JSON形式で保存）
var controls: String = ""

## キーマッピング設定（JSON形式で保存）
var key_mapping: String = ""

## 起動オプション（引数）
var arguments: String = ""

## 製作者リスト（データベースではdevelopersテーブルとして分離）
var developers: Array[DeveloperInfo] = []

## コンストラクタ
func _init():
	genre = []
	developers = []
	controller_support = false
	is_visible = true

