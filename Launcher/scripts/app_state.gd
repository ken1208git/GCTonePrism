## シーン間データ受け渡し用シングルトン
## ストアブラウズ → カルーセル間のゲームリスト共有に使用

extends Node

## カルーセルに渡すフィルタ済みゲームリスト（空ならDB全件取得）
var filtered_games: Array[GameInfo] = []

## カルーセルで最初にフォーカスするゲームID
var initial_game_id: String = ""

## カルーセルからの戻り先シーンパス
var return_scene: String = ""

## カルーセル画面に表示するセクション名
var section_title: String = ""

## (#315) カルーセルが「最上位画面」か。空ストア (0 セクション) から StoreEntryRouter で store_browse を
## 挟まず直接カルーセルに来た場合に true。戻る先のストアが無いので、game_selection は (1) 戻るボタンを
## 出さず (2) ESC を「戻る」ではなく「退出ダイアログ」にして、store_browse と同じ最上位の退出挙動に揃える。
var carousel_top_level: bool = false

## プレイ中シーン (playing) からゲーム終了で game_selection へ復帰中か (#214)。
## true の場合 game_selection は起動直後に running-view 静止状態を再現し、
## switch_to_normal_view (起動モーションの逆再生) でカルーセルへ戻る。
var returning_from_game: bool = false

## 上記復帰が「中断メニューからの終了 (= 終了中画面を見せた)」由来か。
## true なら running-view 再現も「ゲーム終了中…」で出して連続させる (false=自然終了は「プレイ中」)。
var returning_from_quit: bool = false

## (#344) この来場者に中断メニューの案内を出したか。ゲームを 1 本目に起動する直前だけ出す。
##
## **リセットは `screensaver.gd::_ready()` が行う** (`clear()` ではない)。スクリーンセーバーに
## 着いた = 来場者が入れ替わった、が経路を問わず成立するため。`clear()` に紐づけてはいけない —
## `IdleManager.transition_to_screensaver` の呼び出し 13 箇所のうち `clear()` を通るのは 2 箇所だけで、
## **「遊び終えて退出」「放置して帰る」という最も多い 2 つの帰り方が通らない**。そこに紐づけると
## 次の来場者に案内が出ず、しかも「前の人の帰り方次第で出たり出なかったり」する = 当日その場で
## 再現できない壊れ方になる (issue #344 のコメントに調査結果あり)。
##
## `clear()` でも畳んでいるのは、明示的な退出で状態を残さないという `clear()` の趣旨に沿うため
## (こちらは補助で、正本は screensaver 側)。
var pause_hint_shown: bool = false

## (#315) 空ストア時の「最上位カルーセル」用に AppState を準備する。StoreEntryRouter (入口直行) と
## store_browse._fallback_to_carousel (すり抜け defense) の両方から呼び、最上位カルーセルの作り方を
## 1 箇所に集約する (戻り先ストア無し・全ゲーム表示・top-level フラグ)。
func prepare_top_level_carousel(games: Array[GameInfo]) -> void:
	filtered_games = games
	initial_game_id = games[0].game_id if not games.is_empty() else ""
	return_scene = "res://scenes/screensaver.tscn"
	section_title = ""
	carousel_top_level = true

## データをクリアする
func clear() -> void:
	filtered_games = []
	initial_game_id = ""
	return_scene = ""
	section_title = ""
	carousel_top_level = false
	returning_from_game = false
	returning_from_quit = false
	pause_hint_shown = false
