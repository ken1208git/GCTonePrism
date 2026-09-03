## 「操作者が意図して入力したか」の判定。**無操作タイマーを持つ画面はすべてこれを通すこと。**
##
## **なぜ共有するか**: ゲームパッドのアナログスティックには個体差でドリフト (触っていないのに
## 微小な軸入力を出し続ける) がある。素朴に「何か InputEvent が来たらタイマーをリセット」と
## 書くと、ドリフトのあるコントローラーが挿さった台では**無操作タイマーが永久に発火しない**。
## 展示は共用コントローラーを各席に挿して回す運用 (docs/operations/overview.md) なので、
## 1 本のドリフト品がその台を一日固める。
##
## この判定は `service_mode.gd` が先に持っていたが、アンケート画面 (#35) を新設した際に
## 同じ罠を踏んだ。判定を書き写すと片方だけ直る / 新しい画面がまた素朴に書く、が繰り返されるので
## 1 箇所に寄せる (AGENTS.md「UI 実装と分割方針」軸3)。
##
## **本編 3 画面 (カルーセル / ストア / 初回説明) はまだ移行していない (#430)。** それぞれ独自に
## 「何か来たらリセット」相当を書いており同じ穴が開いているが、あちらの実害はスクリーンセーバーへ
## 戻らなくなること (台は操作可能なまま) で、アンケート表示中に固まるのとは重さが違うため別 issue にした。
class_name InputIntent
extends RefCounted

## スティックのデッドゾーン。これ以下の軸入力はドリフト / ノイズとみなす。
const AXIS_DEADZONE: float = 0.5

## マウス移動として数える最小の移動量 (px)。これ以下は机の振動・センサーのノイズ・
## スクリーンショット時の誤検知とみなす。**リポジトリ既存の作法に合わせた値** —
## `input_handler.gd` / `overlay_menu.gd` / `service_mode_overlay.gd` が
## 「微小なマウス移動は無視」として同じ 1.0 を使っている。
const MOUSE_MOTION_THRESHOLD: float = 1.0


## 操作者の意図的な入力なら true。
##
## キーは**押下のみ**を見る (離すのは操作の裏返しなので数えない / オートリピートの echo も除く)。
##
## マウス移動は「そこに人がいる」証拠だが、**閾値を付ける**。「マウスは放置してもイベントを
## 出さない」は展示会場では成り立たない — 机がぶつかって揺れる、センサーが汚れて微小な動きを
## 拾い続ける、何かに寄りかかっている、のいずれでも移動イベントは出続ける。無条件に true にすると
## アンケート画面の放置タイマーが永久にリセットされ、スティックドリフトとまったく同じ壊れ方をする。
static func is_intentional(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventMouseMotion:
		return event.relative.length() > MOUSE_MOTION_THRESHOLD
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > AXIS_DEADZONE
	return false
