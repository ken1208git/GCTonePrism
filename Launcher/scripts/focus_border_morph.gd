## フォーカス枠の morph アニメーション。共有フォーカス枠 1 枚が、フォーカス中のボタンへ
## 滑らかに移動・拡縮しながら追従し、常時ブリージング発光する。
##
## **なぜ切り出したか**: この動きは `common_dialog.gd` の `_process` に直書きされていて再利用できず、
## アンケート画面 (#35) を新設した際に Godot 既定の白い矩形枠が出て、既存ダイアログと見た目が
## 揃わなかった。本クラスは**将来この動きを一本化するための受け皿**。
##
## **現状は意図的な一時重複**: `common_dialog.gd` にも同じ logic が残っており、動きの調整を
## するなら 2 箇所を直す必要がある (= 本来なくしたい状態)。移行しなかったのは、全ダイアログが
## 通る最頻経路であるうえ headless では見た目を検証できず、文化祭直前に触るリスクが見合わないため。
## **移行は #426**。それまでは「2 箇所ある」ことを承知で扱うこと。
##
## 使い方:
##   var _morph := FocusBorderMorph.new(focus_border_panel)
##   _morph.set_targets(buttons)        # 追従対象 (これ以外にフォーカスがあると枠を隠す)
##   func _process(d): _morph.update(d, viewport, panel_for_fade_gate, mouse_mode)

extends RefCounted
class_name FocusBorderMorph

## 追従の速さ (delta 倍率)。common_dialog.gd と同値。
const FOLLOW_SPEED: float = 25.0
## 初回出現の拡大率とアニメーション時間。
const APPEAR_SCALE: float = 1.15
const APPEAR_DURATION: float = 0.25

var _border: Panel = null
var _targets: Array[Control] = []

var _target_radius: float = 16.0
var _current_radius: float = 16.0
var _initialized: bool = false
var _tweening: bool = false
var _prev_target: Control = null
var _prev_target_pos: Vector2 = Vector2.ZERO
var _glow_timer: float = 0.0


func _init(border: Panel) -> void:
	_border = border


## 追従対象を設定する。ここに無いノードにフォーカスがあるときは枠を隠す
## (= ダイアログ外や非対象コントロールに枠が飛ばないようにする)。
func set_targets(targets: Array) -> void:
	_targets.clear()
	for t in targets:
		if t is Control:
			_targets.append(t)
	# 対象が入れ替わったら次の update で出現アニメからやり直す。
	_initialized = false


## 毎フレーム呼ぶ。
## fade_gate: 登場アニメ中のノード (modulate.a < 0.99 の間は枠を出さない)。null 可。
## mouse_mode: マウス操作中なら true (枠を隠す。マウスはカーソルが位置を示すため)。
func update(delta: float, viewport: Viewport, fade_gate: CanvasItem, mouse_mode: bool) -> void:
	if _border == null or not is_instance_valid(_border):
		return

	# ダイアログの登場アニメーション中は枠を出さない (パネルが拡大中に枠だけ確定位置に
	# 出ると、枠が浮いて見える)。
	if fade_gate != null and is_instance_valid(fade_gate) and fade_gate.modulate.a < 0.99:
		_border.visible = false
		_initialized = false
		return

	if mouse_mode:
		_border.visible = false
		return

	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if focus_owner == null or not (focus_owner in _targets):
		_border.visible = false
		return

	_border.visible = true
	var target_rect: Rect2 = focus_owner.get_global_rect()

	if not _initialized:
		# 初回: 位置を合わせてから、ズームイン + フェードインで出す。
		_border.global_position = target_rect.position
		_border.size = target_rect.size
		_current_radius = _target_radius
		_prev_target = focus_owner
		_prev_target_pos = target_rect.position
		_initialized = true
		_tweening = true
		_border.pivot_offset = target_rect.size / 2.0
		_border.scale = Vector2(APPEAR_SCALE, APPEAR_SCALE)
		_border.modulate.a = 0.0
		var tween := _border.create_tween()
		tween.set_parallel(true)
		tween.tween_property(_border, "scale", Vector2.ONE, APPEAR_DURATION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_border, "modulate:a", 1.0, APPEAR_DURATION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): _tweening = false)
	elif _tweening:
		# 出現アニメ中は位置/サイズを触らない (tween と競合して動きが濁る)。
		_prev_target = focus_owner
		_prev_target_pos = target_rect.position
	else:
		# 同じ対象がレイアウト変化で動いた分は即座に追随させてから lerp する
		# (スクロール等で対象が動いたときに枠が遅れて置いていかれるのを防ぐ)。
		if focus_owner == _prev_target:
			_border.global_position += target_rect.position - _prev_target_pos
		var speed := delta * FOLLOW_SPEED
		_border.global_position = _border.global_position.lerp(target_rect.position, speed)
		_border.size = _border.size.lerp(target_rect.size, speed)
		_current_radius = lerpf(_current_radius, _target_radius, speed)

	_prev_target = focus_owner
	_prev_target_pos = target_rect.position

	# ブリージング発光 (common_dialog.gd / GlowAnimator と同じ式)。
	_glow_timer += delta
	var glow_alpha := 0.5 + 0.3 * sin(_glow_timer * 3.0)
	var style := _border.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.set_corner_radius_all(int(_current_radius))
		var c := Color(1, 1, 1, glow_alpha)
		style.shadow_color = c
		style.border_color = c
