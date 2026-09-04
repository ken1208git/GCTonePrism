extends Node
## スタッフ向けサービスモードの開閉を管理する。
## Ctrl+Alt+F12 で全画面の診断・管理画面を開閉する。60 秒間操作がないと自動的に閉じて通常画面へ戻る
## (開けっ放しで離れてしまう事故を防ぐため)。
##
## ランチャーが手前に表示されている状態での使用を想定している (ゲームが手前のときはキー入力がゲームに渡るので
## 反応しない。ゲームを終了してから使う)。このスクリプトは開閉の管理だけを行い、画面そのものは service_mode_overlay が持つ。

const IDLE_TIMEOUT_SEC := 60.0
const ServiceModeOverlay := preload("res://scripts/service_mode_overlay.gd")

var _overlay: CanvasLayer = null
var _open: bool = false
var _idle_sec: float = 0.0
var _prev_paused: bool = false  # 開く前の pause 状態 (閉じる時に復元)
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE  # 開く前のカーソル表示状態 (閉じる時に復元)


func _ready() -> void:
	# ダイアログ等で tree.paused でも開閉・自動復帰を効かせる。
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# Ctrl+Alt+F12 で開閉トグル (スタッフのみ知る隠しコンボ)。
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F12 and event.ctrl_pressed and event.alt_pressed:
		get_viewport().set_input_as_handled()
		toggle()
		return
	# 開いている間、意図的な操作があればアイドルタイマーをリセット (無操作 60 秒で自動復帰)。
	if _open:
		notify_activity(event)


func _process(delta: float) -> void:
	if not _open:
		return
	# (#311) 試遊テスト中 (GameSession 経由でゲームが走っている間) は無操作タイマーを進めない。
	# 試遊中の入力はゲーム側に行きランチャーには届かないため、そのまま数えると 60 秒を超える試遊を
	# 「無操作」と誤判定して自動クローズ → close_overlay の _pt_stop がプレイ中のゲームを強制終了してしまう。
	# サービスモード中に GameSession が走るのは試遊テストだけなので is_running() で一括ガードする。
	if GameSession.is_running():
		_idle_sec = 0.0
		return
	_idle_sec += delta
	if _idle_sec >= IDLE_TIMEOUT_SEC:
		_log("[ServiceMode] 60 秒無操作のため自動的に閉じる")
		close()


func is_open() -> bool:
	return _open


## 終了前クリーンアップ。起動/試遊テストで起動したゲーム (GameSession 非経由) を終了させる。
## quit 経路 (Alt+F4 等) で孤児プロセスを残さないため AppManager から quit 直前に呼ぶ。
func cleanup_for_quit() -> void:
	if _overlay and _overlay.has_method("cleanup_for_quit"):
		_overlay.cleanup_for_quit()


## INFO ログ出力。解決は LogBridge に集約した (同じ /root/Logger 参照を各所に書き写すと、
## 「Logger は呼べない」という誤解ごとコピーされて広がるため)。
func _log(message: String) -> void:
	LogBridge.info(message)


## 意図的な操作であればアイドルタイマーをリセットする。overlay 側が入力を消費 (set_input_as_handled)
## すると、_input フェーズで子の overlay が親の本 autoload より先に処理され本 _input がスキップされ得る
## (Esc/←/→ 等)。その経路でも overlay からこれを呼んでもらい無操作判定を確実にリセットする。
## ジョイパッドのスティックドリフト等のノイズ入力では自動復帰が永久に発火しなくなるので、
## 意図的入力 (キー/ボタン押下・マウス移動・デッドゾーン超えの軸) に限定する。
func notify_activity(event: InputEvent) -> void:
	if _is_intentional_input(event):
		_idle_sec = 0.0


## 操作者の意図的な入力か (スティックドリフト/微小ノイズを無視する)。
## 判定本体は InputIntent に移した — 無操作タイマーを持つ画面が増えるたびに書き写されると、
## 新しい画面がまた素朴に「何か来たらリセット」と書いてドリフトで固まる (アンケート画面で実際に起きた)。
##
## **純粋な抽出ではなく、挙動が 1 点変わっている**: 旧実装はマウス移動を無条件に意図的入力として
## 扱っていたが、共有後は 1px 超のみになった (`InputIntent.MOUSE_MOTION_THRESHOLD`)。したがって
## 机の振動程度の微小な移動ではサービスモードの 60 秒オートクローズがリセットされなくなり、
## **わずかに閉じやすくなる**。スタッフが操作していれば必ず 1px を超えるので実害は無いと判断したが、
## 「移した」だけでは挙動同一に読めるので明記しておく。
func _is_intentional_input(event: InputEvent) -> bool:
	return InputIntent.is_intentional(event)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	if _overlay == null:
		_overlay = ServiceModeOverlay.new()
		add_child(_overlay)
	_open = true
	_idle_sec = 0.0
	# 裏のシーン (ブラウズ/カルーセル等) を凍結して入力競合・背面の動作を止める。
	# 本 autoload と overlay は PROCESS_MODE_ALWAYS なので paused でも動き続ける。
	_prev_paused = get_tree().paused
	get_tree().paused = true
	# Ctrl+Alt+F12 (キーボード) で開くのでカーソルは隠して開始。以後 overlay 側がマウス移動で表示・
	# キー/パッドで非表示に切替 (ランチャー他画面と同じ挙動)。閉じる時に元の状態へ戻す。
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_overlay.open_overlay()
	_log("[ServiceMode] サービスモードを開いた")


func close() -> void:
	if not _open:
		return
	_open = false
	if _overlay:
		_overlay.close_overlay()
	get_tree().paused = _prev_paused  # pause 状態を復元 (開く前が paused でなければ解除)
	Input.mouse_mode = _prev_mouse_mode  # カーソル表示状態を復元
	_log("[ServiceMode] サービスモードを閉じた")
