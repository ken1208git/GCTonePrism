extends Control

## ストアブラウズ画面（メインオーケストレーター）
## Steam風の縦スクロールブラウズ画面
## セクションごとにスライドショー/タイルグリッド/通常行を表示

# --- コンポーネント ---
var _idle_mgr: IdleManager
var _db_manager: DatabaseManager
var _game_repo: GameRepository
var _section_repo: StoreSectionRepository
var _sections: Array[StoreSectionInfo] = []

# --- ナビゲーション状態 ---
var _current_section: int = 0
var _current_tile: int = 0
var _on_view_all: bool = false   # type=0で「すべて見る」にフォーカス中か
var _on_exit_button: bool = false  # 退出ボタンにフォーカス中か
var _on_all_games: bool = false    # 「すべてのゲーム」ボタンにフォーカス中か
var _using_mouse: bool = false

# --- スライドショー ---
var _slideshow_timers: Dictionary = {}  # section_index -> float
const SLIDESHOW_INTERVAL := 4.0
var _slideshow_indices: Dictionary = {}  # section_index -> int (現在表示中のスライド)

# --- グローアニメーション ---
var _glow_time: float = 0.0

# --- セクションUIデータ ---
# 各要素: {section: StoreSectionInfo, container: Control, tiles: Array[Control], type: int}
var _section_ui: Array = []

# --- ノード参照 ---
@onready var _scroll_container: ScrollContainer = $ScrollArea
@onready var _content_container: VBoxContainer = $ScrollArea/MarginContainer/ContentContainer
@onready var _focus_border: Panel = $FocusLayer/FocusBorder
@onready var _top_bar: CanvasLayer = $TopBar
@onready var _bottom_bar: CanvasLayer = $BottomBar

# --- 段階的UI構築 ---
var _build_queue: Array = []
var _build_complete: bool = false
var _viewport_width: float = 0.0
var _progress_bar: Control = null       # カスタムプログレスバー（背景+フィル）
var _progress_fill: Panel = null        # フィル部分（シェーダー適用対象）
var _progress_label: Label = null
var _total_sections: int = 0

# --- 「すべてのゲーム」ボタン ---
var _all_games_button: Button = null

# --- フォーカス対象 ---
var _focus_target: Control = null

# --- フォーカスモーフ用 ---
var _focus_target_rect: Rect2 = Rect2()
var _focus_target_radius: float = 24.0
var _focus_current_radius: float = 24.0
var _focus_initialized: bool = false
var _focus_tweening: bool = false
var _focus_prev_target: Control = null
var _focus_prev_target_pos: Vector2 = Vector2.ZERO
var _was_transitioning: bool = false
var _exit_button: Button

# --- スクロールTween ---
var _scroll_tween: Tween = null

# --- マウスクロール用 ---
var _target_scroll_y: float = 0.0
var _is_smooth_scrolling: bool = false

# --- 遅延画像読み込み（バックグラウンドスレッド） ---
var _image_load_queue: Array = []   # スレッドに渡すキュー [{path: String, node_id: int, target: String}]
var _loaded_images: Array = []      # スレッドが読み込んだ結果 [{image: Image, node_id: int, target: String}]
var _load_thread: Thread = null
var _load_mutex: Mutex = Mutex.new()
var _node_registry: Dictionary = {} # node_id -> Control（スレッドからノード参照できないため）
var _cancel_requested: bool = false

func _ready():
	_idle_mgr = IdleManager.new()
	_db_manager = DatabaseManager.new()

	process_mode = Node.PROCESS_MODE_ALWAYS

	if not _db_manager.open():
		print("[StoreBrowse] データベースのオープンに失敗しました")
		ErrorManager.show_error(ErrorCode.DATABASE_NOT_FOUND)
		return

	_game_repo = GameRepository.new(_db_manager)
	_section_repo = StoreSectionRepository.new(_db_manager, _game_repo)
	_sections = _section_repo.get_store_sections()

	# セクション0件 → フォールバック: 全ゲームでカルーセル直接表示
	if _sections.is_empty():
		print("[StoreBrowse] セクション0件 → カルーセルにフォールバック")
		_fallback_to_carousel()
		return

	print("[StoreBrowse] %d 件のセクションを読み込みました" % _sections.size())

	# (#278 ②) 必要なデータ (_sections と各 section.games) は get_store_sections で eager ロード済で、
	# 以降の段階的 build はメモリ上のデータだけを使い DB を引かない。そこでここで接続を閉じ、store_browse
	# 表示中に DB ファイルハンドルを握り続けないようにする → Manager の Restore / DB 初期化が表示中でも
	# 衝突しなくなる (#278 ① の Restore 例外を緩める defense in depth、screensaver/カルーセルと同じ open→close)。
	# 「すべて見る」「すべてのゲーム」ナビは repo が is_open()→open() で自動再接続する。
	_db_manager.close()

	# ExitButton設定（TopBarコンポーネントから取得）
	_exit_button = _top_bar.get_exit_button()
	_top_bar.exit_pressed.connect(_on_exit_button_pressed)

	# ContentContainerを非表示にしておく（構築完了後にフェードイン）
	_content_container.modulate = Color(1, 1, 1, 0)

	# 段階的UI構築のキューを準備
	_viewport_width = get_viewport_rect().size.x
	_total_sections = _sections.size()
	for i in range(_total_sections):
		_build_queue.append(i)

	# プログレスバーを画面中央に表示
	_create_progress_ui()

	set_process(true)
	set_process_input(true)

func _process(delta):
	# 段階的UI構築
	if not _build_complete:
		if _build_queue.is_empty():
			_on_build_complete()
		else:
			var count = mini(2, _build_queue.size())
			for j in range(count):
				_build_one_section(_build_queue.pop_front())
			_set_progress(float(_total_sections - _build_queue.size()) / _total_sections * 100.0)
		return

	# スレッドで読み込み済みの画像をメインスレッドで適用
	_apply_loaded_images()

	# アイドルタイマー
	if _idle_mgr.update(delta, get_tree().paused):
		IdleManager.transition_to_screensaver(get_tree())
		return

	# シーン遷移中のガード
	if not is_inside_tree() or get_tree() == null:
		return
	if get_tree().paused:
		return

	# スライドショー自動切替 + ゲージバー更新
	for sec_idx in _slideshow_timers.keys():
		_slideshow_timers[sec_idx] += delta
		if _slideshow_timers[sec_idx] >= SLIDESHOW_INTERVAL:
			_slideshow_timers[sec_idx] = 0.0
			_switch_slide(sec_idx, 1)
		else:
			_update_slideshow_bar(sec_idx)

	# グローアニメーション
	_glow_time += delta
	_update_glow()

	# シーン遷移中はフォーカス枠を非表示
	if TransitionManager._transitioning:
		if _focus_border:
			_focus_border.visible = false
			_focus_initialized = false
		_was_transitioning = true
		return

	# 遷移完了直後にフォーカスを再設定
	if _was_transitioning:
		_was_transitioning = false
		_update_focus_visual()

	# マウススムーズスクロール
	if _is_smooth_scrolling:
		_scroll_container.scroll_vertical = lerpf(_scroll_container.scroll_vertical, _target_scroll_y, 15.0 * delta)
		if abs(_scroll_container.scroll_vertical - _target_scroll_y) < 1.0:
			_scroll_container.scroll_vertical = roundi(_target_scroll_y)
			_is_smooth_scrolling = false

	# フォーカスボーダーをlerp追従（スクロール分は即座反映）
	_sync_focus_position()
	if _focus_border and _focus_border.visible and _focus_initialized:
		# Tween中は位置/サイズの更新をスキップ
		if _focus_tweening:
			_focus_prev_target = _focus_target
			_focus_prev_target_pos = _focus_target_rect.position
		else:
			# 同じターゲットの位置変化（=スクロール）は即座に反映
			if _focus_target == _focus_prev_target:
				var target_delta = _focus_target_rect.position - _focus_prev_target_pos
				_focus_border.global_position += target_delta
			# フォーカス移動分はlerpで補間
			var speed = delta * 25.0
			_focus_border.global_position = _focus_border.global_position.lerp(
				_focus_target_rect.position, speed)
			_focus_border.size = _focus_border.size.lerp(
				_focus_target_rect.size, speed)
			_focus_current_radius = lerpf(_focus_current_radius, _focus_target_radius, speed)
			var morph_style = _focus_border.get_theme_stylebox("panel") as StyleBoxFlat
			if morph_style:
				morph_style.set_corner_radius_all(int(_focus_current_radius))
			_focus_prev_target = _focus_target
			_focus_prev_target_pos = _focus_target_rect.position

	# BottomBar表示切替
	if _bottom_bar:
		_bottom_bar.get_panel().visible = not _using_mouse

## ホイール/トラックパッドの 1 イベントあたりのスクロール量(px)。
## マウスホイールは離散的に少数イベント (factor=1.0) だが、トラックパッドの高精度スクロールは 1 イベント
## あたり factor が小さい値 (≈0.1) で高頻度に飛んでくる。固定量を足すとイベント数ぶん爆速になるため
## factor で正規化する (ホイール=150 / トラックパッド≈15)。factor 未設定 (<=0) のデバイスは 1.0 に
## フォールバック。1 イベントの上限を 150 に張り、稀に大きい factor が来ても暴れないようにする
## (= 通常ホイールは従来どおり 150/イベントのまま)。
func _wheel_scroll_step(event: InputEventMouseButton) -> float:
	var f: float = event.factor if event.factor > 0.0 else 1.0
	return minf(150.0 * f, 150.0)


func _input(event):
	if get_tree().paused:
		return
	if not _build_complete:
		return

	# アイドルリセット
	_idle_mgr.reset()

	# マウス移動検知
	if event is InputEventMouseMotion:
		if not _using_mouse:
			_using_mouse = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton:
		if not _using_mouse:
			_using_mouse = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if _scroll_tween and _scroll_tween.is_valid(): _scroll_tween.kill()
			if not _is_smooth_scrolling: _target_scroll_y = _scroll_container.scroll_vertical
			_target_scroll_y -= _wheel_scroll_step(event)
			_target_scroll_y = max(0.0, _target_scroll_y)
			_is_smooth_scrolling = true
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if _scroll_tween and _scroll_tween.is_valid(): _scroll_tween.kill()
			if not _is_smooth_scrolling: _target_scroll_y = _scroll_container.scroll_vertical
			var v_scrollbar = _scroll_container.get_v_scroll_bar()
			var max_scroll = v_scrollbar.max_value - _scroll_container.size.y
			if max_scroll < 0: max_scroll = v_scrollbar.max_value

			_target_scroll_y += _wheel_scroll_step(event)
			_target_scroll_y = min(_target_scroll_y, max_scroll)
			_is_smooth_scrolling = true
			get_viewport().set_input_as_handled()
			return
		return

	# キーボード/ゲームパッド入力
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_using_mouse = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if not event.is_pressed():
		return

	var viewport = get_viewport()
	if not viewport:
		return

	if event.is_action_pressed("ui_up"):
		_move_section(-1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_section(1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move_tile(-1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_tile(1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_select()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_exit_button_pressed()
		viewport.set_input_as_handled()

# --- 段階的UI構築 ---

func _create_progress_ui() -> void:
	var center := CenterContainer.new()
	center.name = "LoadingOverlay"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	_progress_label = Label.new()
	_progress_label.text = "読み込み中..."
	_progress_label.add_theme_font_override("font", preload("res://fonts/NotoSansJP-Regular.ttf"))
	_progress_label.add_theme_font_size_override("font_size", 28)
	_progress_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_progress_label)

	# カスタムプログレスバー（背景 + フィル分離）
	_progress_bar = Control.new()
	_progress_bar.custom_minimum_size = Vector2(400, 8)

	# 背景（暗いバー）
	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(1, 1, 1, 0.1)
	bg_style.set_corner_radius_all(4)
	bg.add_theme_stylebox_override("panel", bg_style)
	_progress_bar.add_child(bg)

	# フィル（光る部分 — シェーダー適用）
	_progress_fill = Panel.new()
	_progress_fill.set_anchor(SIDE_TOP, 0.0)
	_progress_fill.set_anchor(SIDE_BOTTOM, 1.0)
	_progress_fill.offset_left = 0.0
	_progress_fill.offset_top = 0.0
	_progress_fill.offset_bottom = 0.0
	_progress_fill.offset_right = 0.0  # 初期幅0
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(1, 1, 1, 1.0)
	fill_style.set_corner_radius_all(4)
	_progress_fill.add_theme_stylebox_override("panel", fill_style)
	ShimmerHelper.apply(_progress_fill)
	_progress_bar.add_child(_progress_fill)

	vbox.add_child(_progress_bar)

	add_child(center)

func _set_progress(percent: float) -> void:
	if _progress_fill and _progress_bar:
		var bar_width = _progress_bar.size.x
		_progress_fill.offset_right = bar_width * (percent / 100.0)

func _build_one_section(i: int) -> void:
	var section = _sections[i]
	var container: Control
	match section.section_type:
		1:  # スライドショー
			container = StoreBannerBuilder.build_slideshow_section(section, _viewport_width)
			_slideshow_timers[i] = 0.0
			_slideshow_indices[i] = 0
		2:  # タイルグリッド
			container = StoreBannerBuilder.build_tile_grid_section(section, _viewport_width)
		_:  # 通常セクション行
			container = StoreBrowseBuilder.build_normal_section(section, _viewport_width)

	# (#345) スライドショー/タイルは元々セクション見出しを出さない設計だったが、ストア→カルーセル遷移時に
	# 「これは何の集まり？」が分かりにくい (カルーセル側の section_title ラベルだけでは連続性が弱い)。通常行と
	# 同じ見出し (store_section_header) を上に足し、店とカルーセルで同じセクション名が見える連続性を作る。
	# container 変数は内側バナーのまま据え置き、表示ツリーだけ VBox[header, container] で包む = 既存の
	# container.get_node("SlideshowPrev") 等のノード探索 / _section_ui / _switch_slide を一切壊さない。
	# ViewAllButton は既定 visible=false のまま (厳選枠の「すべて見る」相当は本体クリック→全件カルーセルで担保済み)。
	if section.section_type == 1 or section.section_type == 2:
		var wrap = VBoxContainer.new()
		wrap.name = "ShowcaseWrap_%d" % section.section_id
		wrap.add_theme_constant_override("separation", 12)
		var header = preload("res://scenes/components/store_section_header.tscn").instantiate()
		header.get_node("SectionTitle").text = section.title
		wrap.add_child(header)
		wrap.add_child(container)
		_content_container.add_child(wrap)
	else:
		_content_container.add_child(container)

	# タイル一覧を収集
	var tiles: Array[Control] = []
	_collect_focusable_tiles(container, section.section_type, tiles)

	# (#315) games があるのに type/source/max の組合せでタイルが0描画になるセクションを検出。
	# drop すると _section_ui の index が _sections とズレてナビ (クロージャが元の i を使う) が壊れるため
	# drop はしない。代わりに has_content を記録し、全セクションが0タイルなら _on_build_complete で
	# カルーセルへフォールバックする。原因 config 追跡のため警告ログに type/source/max/games を出す。
	var has_content := _section_has_content(container, section.section_type)
	if not has_content:
		push_warning("[StoreBrowse] ⚠️ セクション '%s' が0タイル描画 (id=%d, type=%d, source=%s, max=%d, games=%d)" %
			[section.title, section.section_id, section.section_type, section.section_source,
			section.max_display_count, section.games.size()])

	_section_ui.append({
		"section": section,
		"container": container,
		"tiles": tiles,
		"type": section.section_type,
		"has_content": has_content
	})

	# マウスクリック/ホバーのシグナル接続
	_connect_tile_signals(i, tiles)

	# スライドショーの左右ボタンにシグナル接続
	if section.section_type == 1:
		var prev_btn = container.get_node_or_null("SlideshowPrev")
		var next_btn = container.get_node_or_null("SlideshowNext")
		var sec_idx_ss = i
		if prev_btn:
			prev_btn.pressed.connect(func():
				_switch_slide(sec_idx_ss, -1)
				_slideshow_timers[sec_idx_ss] = 0.0
			)
		if next_btn:
			next_btn.pressed.connect(func():
				_switch_slide(sec_idx_ss, 1)
				_slideshow_timers[sec_idx_ss] = 0.0
			)

	# type=0の「すべて見る」ボタンにシグナル接続
	if section.section_type == 0:
		var view_all = container.get_node_or_null("ViewAllButton")
		if view_all == null:
			for child in container.get_children():
				if child is HBoxContainer:
					view_all = child.get_node_or_null("ViewAllButton")
					break
		if view_all:
			var sec_idx = i
			view_all.pressed.connect(func(): _on_view_all_pressed(sec_idx))
			view_all.mouse_entered.connect(func():
				if not _using_mouse:
					_using_mouse = true
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_current_section = sec_idx
				_on_view_all = true
				_update_focus_visual()
			)

func _on_build_complete() -> void:
	_build_complete = true

	# (#315) 全セクションが0タイル描画 (games はあるのに表示できる中身が無い) なら、空のストア
	# (「すべてのゲーム」ボタンだけ) にせずカルーセルへフォールバックする。
	var any_content := false
	for sec_data in _section_ui:
		if sec_data.get("has_content", false):
			any_content = true
			break
	if not any_content:
		print("[StoreBrowse] 表示可能なセクションが0 (全%d件が0タイル) → カルーセルにフォールバック" % _section_ui.size())
		_fallback_to_carousel()
		return

	# 「すべてのゲーム」ボタンをセクション末尾に追加
	_all_games_button = StoreBrowseBuilder.build_all_games_button(_viewport_width)
	_all_games_button.pressed.connect(_on_all_games_pressed)
	_all_games_button.mouse_entered.connect(func():
		if not _using_mouse:
			_using_mouse = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_on_all_games = true
		_on_view_all = false
		_on_exit_button = false
		_update_focus_visual()
	)
	_content_container.add_child(_all_games_button)

	# プログレスバーをフェードアウトして削除
	var overlay = get_node_or_null("LoadingOverlay")
	if overlay:
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		tween.tween_callback(overlay.queue_free)

	# ContentContainerをフェードインで表示
	var content_tween = create_tween()
	content_tween.tween_property(_content_container, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 初期フォーカス
	_current_section = 0
	_current_tile = 0
	_on_view_all = false
	call_deferred("_update_focus_visual")

	# 遅延画像読み込みキューを構築
	_build_image_load_queue()

	# BottomBarの操作ヒント。(#315) ESC は退出ダイアログ (_on_exit_button_pressed) を開く最上位画面なので
	# 表記も「退出」に揃える (旧「戻る」は挙動と不一致だった)。直カルーセルの最上位ヒントとも一致。
	if _bottom_bar:
		_bottom_bar.set_hints([["Esc", "退出"], ["Enter", "決定"]])

func _exit_tree():
	# バックグラウンドスレッドをキャンセルして終了を待つ
	if _load_thread and _load_thread.is_started():
		_load_mutex.lock()
		_cancel_requested = true
		_image_load_queue.clear()
		_load_mutex.unlock()
		_load_thread.wait_to_finish()
	if _db_manager:
		_db_manager.close()
	if DialogManager and DialogManager.has_method("close_current_dialog"):
		DialogManager.close_current_dialog()

# --- ナビゲーション ---

func _move_section(dir: int) -> void:
	if _section_ui.is_empty():
		return

	if _on_exit_button:
		# 退出ボタンから下でセクション0へ
		if dir > 0:
			var prev_x := _get_current_focus_center_x()
			_on_exit_button = false
			_on_all_games = false
			_current_section = 0
			_on_view_all = false
			var sec_data = _section_ui[_current_section]
			var sec_tiles = sec_data["tiles"] as Array
			_current_tile = _find_nearest_tile(sec_tiles, prev_x)
			_scroll_to_section(_current_section)
			_update_focus_visual()
		return

	if _on_all_games:
		# 「すべてのゲーム」ボタンから上で最後のセクションへ
		if dir < 0:
			var prev_x := _get_current_focus_center_x()
			_on_all_games = false
			_current_section = _section_ui.size() - 1
			_on_view_all = false
			var sec_data = _section_ui[_current_section]
			var sec_tiles = sec_data["tiles"] as Array
			_current_tile = _find_nearest_tile(sec_tiles, prev_x)
			_scroll_to_section(_current_section)
			_update_focus_visual()
		return

	if dir < 0 and _current_section == 0:
		# セクション0で上 → 退出ボタンへ
		_on_exit_button = true
		_on_view_all = false
		_on_all_games = false
		_scroll_container.scroll_vertical = 0
		_update_focus_visual()
		return

	var new_section = clampi(_current_section + dir, 0, _section_ui.size() - 1)
	if new_section == _current_section and dir > 0:
		# 最後のセクションで下 → 「すべてのゲーム」ボタンへ
		_on_all_games = true
		_on_view_all = false
		_scroll_to_all_games_button()
		_update_focus_visual()
		return
	if new_section == _current_section:
		return
	# 移動前のフォーカスX座標を記憶
	var prev_x := _get_current_focus_center_x()

	_current_section = new_section
	_on_view_all = false

	# 位置ベースで最も近いタイルを選択
	var data = _section_ui[_current_section]
	var new_tiles = data["tiles"] as Array
	_current_tile = _find_nearest_tile(new_tiles, prev_x)

	_scroll_to_section(_current_section)
	_update_focus_visual()

func _move_tile(dir: int) -> void:
	if _section_ui.is_empty():
		return
	var data = _section_ui[_current_section]
	var section_type = data["type"]
	var tile_list = data["tiles"] as Array

	match section_type:
		0:  # 通常セクション行
			if _on_view_all:
				if dir < 0:
					# 「すべて見る」から左に戻る
					_on_view_all = false
					_current_tile = tile_list.size() - 1
					_update_focus_visual()
				return

			var new_tile = _current_tile + dir
			if new_tile < 0:
				return  # 左端で止まる
			elif new_tile >= tile_list.size():
				# 「すべて見る」ボタンが存在する場合のみフォーカス移動
				var has_view_all = false
				var sec_container = _section_ui[_current_section]["container"] as Control
				for child in sec_container.get_children():
					if child is HBoxContainer and child.get_node_or_null("ViewAllButton") and child.get_node("ViewAllButton").visible:
						has_view_all = true
						break
				if has_view_all:
					_on_view_all = true
					_update_focus_visual()
				return
			_current_tile = new_tile
			_update_focus_visual()

		1:  # スライドショー
			_switch_slide(_current_section, dir)
			_slideshow_timers[_current_section] = 0.0  # タイマーリセット

		2:  # タイルグリッド
			var new_tile = clampi(_current_tile + dir, 0, tile_list.size() - 1)
			if new_tile != _current_tile:
				_current_tile = new_tile
				_update_focus_visual()

## 現在のフォーカス対象のX中心座標を取得
func _get_current_focus_center_x() -> float:
	if _focus_target and is_instance_valid(_focus_target):
		var rect = _focus_target.get_global_rect()
		return rect.position.x + rect.size.x / 2.0
	return 0.0

## 指定X座標に最も近いタイルのインデックスを返す
func _find_nearest_tile(tiles: Array, target_x: float) -> int:
	if tiles.is_empty():
		return 0
	var best_idx := 0
	var best_dist := INF
	for i in range(tiles.size()):
		var tile = tiles[i] as Control
		if tile and is_instance_valid(tile):
			var rect = tile.get_global_rect()
			var center_x = rect.position.x + rect.size.x / 2.0
			var dist = absf(center_x - target_x)
			if dist < best_dist:
				best_dist = dist
				best_idx = i
	return best_idx

func _on_select() -> void:
	if _on_all_games:
		_on_all_games_pressed()
		return
	if _on_exit_button:
		_on_exit_button_pressed()
		return
	if _section_ui.is_empty():
		return
	var data = _section_ui[_current_section]
	var section: StoreSectionInfo = data["section"]

	# 行を作ったときに repo が読み込んだ section.games をそのまま使う（再クエリしない）。random を再クエリすると
	# ORDER BY RANDOM() で別の組み合わせ・別件数になり、押したタイルがカルーセルに居ない / max_display_count で
	# 絞った件数と食い違う（= 「大量に表示される」）ため。section.games は developer 込みで読込済みで DB close 後も
	# 有効。filter 系 (genre 等) は元々 LIMIT 無しで全件なので挙動は変わらない (= 従来の「すべて見る＝全件」を維持)。
	var all_games = section.games
	# 再クエリは廃止したが、build 時に開いた DB がまだ開いていればここで解放しておく（次シーンの DB open と
	# 競合させない防御。section.games は materialized 済みなので close 後も有効）。
	_db_manager.close()
	if all_games.is_empty():
		return

	# フォーカスするゲームIDを決定
	var focus_game_id: String = ""
	match data["type"]:
		0:  # 通常行
			if _on_view_all:
				focus_game_id = all_games[0].game_id
			else:
				var tiles = data["tiles"] as Array
				if _current_tile < section.games.size():
					focus_game_id = section.games[_current_tile].game_id
				else:
					focus_game_id = all_games[0].game_id
		1:  # スライドショー
			var slide_idx = _slideshow_indices.get(_current_section, 0)
			if slide_idx < section.games.size():
				focus_game_id = section.games[slide_idx].game_id
			else:
				focus_game_id = all_games[0].game_id
		2:  # タイルグリッド
			if _current_tile < section.games.size():
				focus_game_id = section.games[_current_tile].game_id
			else:
				focus_game_id = all_games[0].game_id

	# AppState設定
	AppState.filtered_games = all_games
	AppState.initial_game_id = focus_game_id
	AppState.return_scene = "res://scenes/store_browse.tscn"
	AppState.section_title = section.title
	AppState.carousel_top_level = false  # (#315) ストア経由 = 通常カルーセル (戻るボタンあり・ESC=戻る)

	TransitionManager.change_scene("res://scenes/game_selection.tscn")

# --- スライドショー ---

var _slide_title_tweens: Dictionary = {}

func _switch_slide(section_index: int, dir: int) -> void:
	if section_index >= _section_ui.size():
		return
	var data = _section_ui[section_index]
	if data["type"] != 1:
		return
	var section: StoreSectionInfo = data["section"]
	var container: Control = data["container"]
	# (#212 改) 実際に生成したスライド枚数で wrap する。max_display_count で枚数を絞った場合 (ランダム等)、
	# section.games.size() で割ると存在しない Banner_* に飛んで空スライドになるため、builder が container に
	# set_meta した slide_count を使う (未設定の旧経路では games.size() にフォールバック)。
	var game_count = int(container.get_meta("slide_count", section.games.size()))
	if game_count <= 1:
		return

	var current_idx = _slideshow_indices.get(section_index, 0)
	var clip = container.get_node_or_null("BannerClip")
	if not clip:
		return
	var old_banner = clip.get_node_or_null("Banner_%d" % current_idx)

	# 新しいインデックス（ラップアラウンド）
	var new_idx = (current_idx + dir) % game_count
	if new_idx < 0:
		new_idx += game_count
	_slideshow_indices[section_index] = new_idx

	var new_banner = clip.get_node_or_null("Banner_%d" % new_idx)
	var banner_width = container.custom_minimum_size.x

	# スライドアニメーション
	var slide_tween = create_tween()
	slide_tween.set_parallel(true)

	if new_banner:
		new_banner.visible = true
		# 新バナーを進行方向から登場（連打時のために現在のXに関わらず初期化）
		new_banner.position.x = banner_width * dir
		slide_tween.tween_property(new_banner, "position:x", 0.0, 0.4)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if old_banner:
		# 旧バナーを現在位置から反対方向にスライドアウト
		slide_tween.tween_property(old_banner, "position:x", -banner_width * dir, 0.4)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	slide_tween.set_parallel(false)
	slide_tween.tween_callback(func():
		if old_banner:
			old_banner.visible = false
			old_banner.position.x = 0
	)

	# ゲージバー: 満タンバーをフェードアウト、新バーを0からスタート
	var bars = container.get_node_or_null("BarIndicator")
	if bars:
		var bar_tween = create_tween()
		bar_tween.set_parallel(true)
		for i in range(bars.get_child_count()):
			var bar = bars.get_child(i) as Panel
			if bar:
				var fill = bar.get_node_or_null("Fill") as ColorRect
				if fill:
					if i == current_idx:
						# 古いバーをフェードアウト
						bar_tween.tween_property(fill, "color:a", 0.0, 0.3)\
							.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
						bar_tween.tween_callback(func():
							fill.size.x = 0
							fill.color.a = 1.0
						).set_delay(0.3)
					elif i != new_idx:
						# 現在でも次でもないバーは即座に0
						fill.size.x = 0
						fill.color.a = 1.0

	# タイトルをバナーと連動してスライドアウト→スライドイン（BannerClip内）
	var title_scroll = clip.get_node_or_null("SlideshowTitleScroll")
	if title_scroll and new_idx < section.games.size():
		var title_label = title_scroll.get_node_or_null("SlideshowTitle")
		var game = section.games[new_idx]
		var new_text: String
		if section.game_display_texts.has(game.game_id) and not section.game_display_texts[game.game_id].is_empty():
			new_text = section.game_display_texts[game.game_id]
		else:
			new_text = game.title
			
		# 前回のタイトルのTweenがあればキャンセル
		if _slide_title_tweens.has(section_index) and _slide_title_tweens[section_index] and _slide_title_tweens[section_index].is_valid():
			_slide_title_tweens[section_index].kill()
			
		var title_base_x = 24.0
		var title_tween = create_tween()
		_slide_title_tweens[section_index] = title_tween
		
		# 旧テキストをスライド方向にフェードアウト（現在位置から目標まで移動）
		title_tween.set_parallel(true)
		title_tween.tween_property(title_scroll, "position:x", title_base_x - 80.0 * dir, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		title_tween.tween_property(title_scroll, "modulate:a", 0.0, 0.15)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			
		# 新テキスト: テキスト差し替え→スライドイン
		title_tween.set_parallel(false)
		title_tween.tween_callback(func():
			if title_label:
				title_label.text = new_text
			title_scroll.reset()
		)
		title_tween.set_parallel(true)
		title_tween.tween_property(title_scroll, "position:x", title_base_x, 0.25)\
			.from(title_base_x + 80.0 * dir)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		title_tween.tween_property(title_scroll, "modulate:a", 1.0, 0.25)\
			.from(0.0)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 現在セクションの場合、フォーカスも更新
	if section_index == _current_section:
		_update_focus_visual()

## ゲージバーのフィル幅を更新（毎フレーム呼び出し）
func _update_slideshow_bar(section_index: int) -> void:
	if section_index >= _section_ui.size():
		return
	var data = _section_ui[section_index]
	if data["type"] != 1:
		return
	var container: Control = data["container"]
	var bars = container.get_node_or_null("BarIndicator")
	if not bars:
		return
	var current_idx = _slideshow_indices.get(section_index, 0)
	var bar = bars.get_node_or_null("Bar_%d" % current_idx)
	if bar:
		var fill = bar.get_node_or_null("Fill")
		if fill:
			var progress = _slideshow_timers[section_index] / SLIDESHOW_INTERVAL
			fill.size.x = progress * StoreBrowseBuilder.BAR_WIDTH

# --- フォーカス表示 ---


func _update_focus_visual() -> void:
	if not _focus_border or _section_ui.is_empty():
		return

	# マウス操作中はフォーカスボーダー非表示
	if _using_mouse:
		_focus_border.visible = false
		_focus_initialized = false
		return

	# 退出ボタンにフォーカス中
	if _on_exit_button:
		if _exit_button:
			_focus_border.visible = true
			_focus_target = _exit_button
			_sync_focus_position()
		else:
			_focus_border.visible = false
			_focus_target = null
		return

	# 「すべてのゲーム」ボタンにフォーカス中
	if _on_all_games:
		if _all_games_button:
			_focus_border.visible = true
			_focus_target = _all_games_button
			_focus_target_radius = 20
			_sync_focus_position()
		else:
			_focus_border.visible = false
			_focus_target = null
		return

	var data = _section_ui[_current_section]
	var target: Control = null

	if data["type"] == 0 and _on_view_all:
		# 「すべて見る」ボタンにフォーカス
		var container = data["container"] as Control
		for child in container.get_children():
			if child is HBoxContainer:
				var btn = child.get_node_or_null("ViewAllButton")
				if btn:
					target = btn
					break
	elif data["type"] == 1:
		# スライドショー: クリップ領域（窓）にフォーカス固定
		var container = data["container"] as Control
		target = container.get_node_or_null("BannerClip")
	else:
		# タイルにフォーカス
		var tiles = data["tiles"] as Array
		if _current_tile < tiles.size():
			target = tiles[_current_tile]

	if target == null:
		_focus_border.visible = false
		_focus_target = null
		return

	_focus_border.visible = true
	_focus_target = target
	_focus_target_radius = 24
	_sync_focus_position()

func _sync_focus_position() -> void:
	if TransitionManager._transitioning:
		return
	if not _focus_border or not _focus_border.visible or _focus_target == null:
		return
	if not is_instance_valid(_focus_target):
		_focus_border.visible = false
		_focus_target = null
		return
	# 目標位置・サイズを更新（実際の移動はlerpで行う）
	_focus_target_rect = _focus_target.get_global_rect()
	# 初回はズームイン登場
	if not _focus_initialized:
		_focus_border.global_position = _focus_target_rect.position
		_focus_border.size = _focus_target_rect.size
		_focus_current_radius = _focus_target_radius
		_focus_prev_target = _focus_target
		_focus_prev_target_pos = _focus_target_rect.position
		_focus_initialized = true
		_focus_tweening = true
		var style = _focus_border.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.set_corner_radius_all(int(_focus_current_radius))
		_focus_border.pivot_offset = _focus_target_rect.size / 2.0
		_focus_border.scale = Vector2(1.15, 1.15)
		_focus_border.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_focus_border, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_focus_border, "modulate:a", 1.0, 0.25)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): _focus_tweening = false)

func _update_glow() -> void:
	if not _focus_border or not _focus_border.visible:
		return
	var style = _focus_border.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		# sin波でグロー強度を変化 (8〜16)
		var glow_intensity = 12.0 + 4.0 * sin(_glow_time * 3.0)
		style.shadow_size = int(glow_intensity)
		# 透明度もわずかに変化
		var alpha = 0.8 + 0.2 * sin(_glow_time * 3.0)
		style.shadow_color = Color(1, 1, 1, alpha)

# --- スクロール ---

func _scroll_to_section(index: int) -> void:
	if index >= _section_ui.size():
		return
	var container = _section_ui[index]["container"] as Control

	var viewport_height = get_viewport_rect().size.y
	var margin := 80.0  # 画面端からの余裕
	var top_bar_height := 120.0  # TopBarの高さ

	# セクションの画面上でのY位置（スクロール考慮済み）
	var section_top = container.global_position.y
	var section_bottom = section_top + container.size.y

	var current_scroll = _scroll_container.scroll_vertical
	var scroll_target = current_scroll

	if section_top < top_bar_height + margin:
		# 上にはみ出しそう → セクション上端が見えるまでスクロール
		var offset = (top_bar_height + margin) - section_top
		scroll_target = maxi(int(current_scroll - offset), 0)
	elif section_bottom > viewport_height - margin:
		# 下にはみ出しそう → セクション下端が見えるまでスクロール
		var offset = section_bottom - (viewport_height - margin)
		scroll_target = int(current_scroll + offset)

	if scroll_target != current_scroll:
		# Tweenでスムーズスクロール
		if _scroll_tween and _scroll_tween.is_running():
			_scroll_tween.kill()
		_scroll_tween = create_tween()
		_scroll_tween.tween_property(_scroll_container, "scroll_vertical", scroll_target, 0.3)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# --- タイル収集・シグナル接続 ---

## (#315) 表示できるセクションが無いとき (0件 / 全セクション0タイル) に全ゲームのカルーセルへフォールバックする。
## get_all_games() は repo が is_open()→open() で自動再接続するため、DB を閉じた後 (build 完了時) からでも呼べる。
## 入口 (StoreEntryRouter) で 0 セクションは事前分岐済なので、本経路は「可視セクションはあるが中身が空/0タイル」
## のすり抜けケース用 defense。incoming 遷移 (screensaver→store_browse) 中に呼ばれると change_scene が
## 再入ガードに弾かれるため、その完了を待ってから遷移する (intro_guide._go_to_store_when_free と同パターン)。
## これにより TransitionManager にキューを持たせず (= 通常の入力起点遷移の挙動を変えず) defense を成立させる。
func _fallback_to_carousel() -> void:
	var all_games = _game_repo.get_all_games()
	_db_manager.close()
	if all_games.is_empty():
		ErrorManager.show_error(ErrorCode.DATABASE_NO_GAMES_REGISTERED)
		return
	# (#315) 入口直行 (StoreEntryRouter) と共通の最上位カルーセル準備 (戻り先ストア無し・ESC=退出)。
	AppState.prepare_top_level_carousel(all_games)
	while TransitionManager._transitioning:
		await get_tree().process_frame
	TransitionManager.change_scene("res://scenes/game_selection.tscn")

## (#315) セクションのコンテナに実際の表示要素 (タイル/スライド) が1つでもあるか。games フィルタは通って
## いても type/source/max の組合せでタイル生成が0件になる経路があり (#211 類似)、その「中身の無い
## セクション」を build 結果そのものから検出する。
func _section_has_content(container: Control, section_type: int) -> bool:
	match section_type:
		1:  # スライドショー: builder が set_meta した生成スライド枚数
			return int(container.get_meta("slide_count", 0)) > 0
		2:  # タイルグリッド: GridTile_* の有無
			for child in container.get_children():
				if child is Panel and child.name.begins_with("GridTile_"):
					return true
			return false
		_:  # 通常セクション (type 0 含む): ThumbnailRow 内の Tile_* の有無
			var thumb_row = container.get_node_or_null("ThumbnailRow")
			if thumb_row:
				for child in thumb_row.get_children():
					if child.name.begins_with("Tile_"):
						return true
			return false

func _collect_focusable_tiles(container: Control, section_type: int, tiles: Array[Control]) -> void:
	match section_type:
		1:  # スライドショー: BannerClip（窓）が1つのフォーカス対象
			var clip = container.get_node_or_null("BannerClip")
			if clip:
				tiles.append(clip)
		2:  # タイルグリッド: GridTile_* パネル
			for child in container.get_children():
				if child is Panel and child.name.begins_with("GridTile_"):
					tiles.append(child)
		_:  # (#315) 通常行 (type 0 含む。_build_one_section の `_` と整合): ThumbnailRow 内の Tile_* → TilePanel
			var thumb_row = container.get_node_or_null("ThumbnailRow")
			if thumb_row:
				for child in thumb_row.get_children():
					if child.name.begins_with("Tile_"):
						var tile_panel = child.get_node_or_null("TilePanel")
						if tile_panel:
							tiles.append(tile_panel)
						else:
							tiles.append(child)

func _connect_tile_signals(section_index: int, tiles: Array[Control]) -> void:
	for tile_idx in range(tiles.size()):
		var tile = tiles[tile_idx]
		var sec_idx = section_index
		var t_idx = tile_idx
		tile.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_current_section = sec_idx
				_current_tile = t_idx
				_on_view_all = false
				_update_focus_visual()
				_on_select()
		)
		tile.mouse_entered.connect(func():
			if not _using_mouse:
				_using_mouse = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_current_section = sec_idx
			_current_tile = t_idx
			_on_view_all = false
			_update_focus_visual()
		)

# --- ボタンハンドラ ---

func _on_view_all_pressed(section_index: int) -> void:
	_current_section = section_index
	_on_view_all = true
	_on_select()

func _on_all_games_pressed() -> void:
	var all_games = _game_repo.get_all_games()
	_db_manager.close()   # (#278 ②) repo が一時再接続するので取得後すぐ閉じる
	if all_games.is_empty():
		return
	AppState.filtered_games = all_games
	AppState.initial_game_id = all_games[0].game_id
	AppState.return_scene = "res://scenes/store_browse.tscn"
	AppState.section_title = "すべてのゲーム"
	AppState.carousel_top_level = false  # (#315) ストア経由 = 通常カルーセル (戻るボタンあり・ESC=戻る)
	TransitionManager.change_scene("res://scenes/game_selection.tscn")

func _scroll_to_all_games_button() -> void:
	if not _all_games_button:
		return
	var viewport_height = get_viewport_rect().size.y
	var margin := 80.0
	var btn_bottom = _all_games_button.global_position.y + _all_games_button.size.y
	var current_scroll = _scroll_container.scroll_vertical
	if btn_bottom > viewport_height - margin:
		var offset = btn_bottom - (viewport_height - margin)
		var scroll_target = int(current_scroll + offset)
		if _scroll_tween and _scroll_tween.is_running():
			_scroll_tween.kill()
		_scroll_tween = create_tween()
		_scroll_tween.tween_property(_scroll_container, "scroll_vertical", scroll_target, 0.3)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_exit_button_pressed() -> void:
	var callback = func(idx):
		if idx == 1:
			# (#35) 退出確認の後に全体アンケートを挟んでからスクリーンセーバーへ。
			SurveyFlow.maybe_show_launcher_end(func(): IdleManager.transition_to_screensaver(get_tree()))
	DialogManager.show_message("確認", "退出しますか？\nタイトル画面に戻ります。",
		["キャンセル", "退出する"], callback,
		[Color(0.3, 0.3, 0.3), Color(0.8, 0.2, 0.2)])

# --- 遅延画像読み込み ---

## 全セクションのタイル/バナーから読み込みキューを構築し、バックグラウンドスレッドを開始
func _build_image_load_queue() -> void:
	for sec_data in _section_ui:
		var section_type = sec_data["type"] as int
		var container = sec_data["container"] as Control

		match section_type:
			1:  # スライドショー: BannerClip 内の Banner_*
				var clip = container.get_node_or_null("BannerClip")
				if clip:
					var idx = 0
					while true:
						var banner = clip.get_node_or_null("Banner_%d" % idx)
						if not banner:
							break
						if banner.has_meta("image_path"):
							var nid = banner.get_instance_id()
							_node_registry[nid] = banner
							_image_load_queue.append({
								"node_id": nid,
								"path": banner.get_meta("image_path"),
								"target": "BackgroundImage"
							})
							_start_label_breathing(banner.get_node_or_null("LoadingLabel"))
						idx += 1

			2:  # タイルグリッド: GridTile_*
				for child in container.get_children():
					if child is Panel and child.name.begins_with("GridTile_") and child.has_meta("image_path"):
						var nid = child.get_instance_id()
						_node_registry[nid] = child
						_image_load_queue.append({
							"node_id": nid,
							"path": child.get_meta("image_path"),
							"target": "BackgroundImage"
						})
						_start_label_breathing(child.get_node_or_null("LoadingLabel"))

			_:  # (#315) 通常行 (type 0 含む。_build_one_section / _collect_focusable_tiles の `_` と整合): ThumbnailRow 内の Tile_*
				var thumb_row = container.get_node_or_null("ThumbnailRow")
				if thumb_row:
					for child in thumb_row.get_children():
						if child.name.begins_with("Tile_") and child.has_meta("image_path"):
							var nid = child.get_instance_id()
							_node_registry[nid] = child
							_image_load_queue.append({
								"node_id": nid,
								"path": child.get_meta("image_path"),
								"target": "TilePanel/Thumbnail"
							})
							_start_label_breathing(child.get_node_or_null("TilePanel/LoadingLabel"))

	# キューが空でなければバックグラウンドスレッドで画像読み込みを開始
	if not _image_load_queue.is_empty():
		_load_thread = Thread.new()
		_load_thread.start(_load_images_in_thread)

## バックグラウンドスレッド: キューからパスを取り出して Image を連続で読み込む
func _load_images_in_thread() -> void:
	while true:
		_load_mutex.lock()
		if _cancel_requested or _image_load_queue.is_empty():
			_load_mutex.unlock()
			break
		var item = _image_load_queue.pop_front()
		_load_mutex.unlock()

		var image = Image.load_from_file(item["path"])
		if image:
			_load_mutex.lock()
			if _cancel_requested:
				_load_mutex.unlock()
				break
			_loaded_images.append({
				"image": image,
				"node_id": item["node_id"],
				"target": item["target"]
			})
			_load_mutex.unlock()

## メインスレッド（_process から呼ばれる）: 読み込み済み画像をテクスチャ化してノードに適用
func _apply_loaded_images() -> void:
	_load_mutex.lock()
	if _loaded_images.is_empty():
		_load_mutex.unlock()
		return

	# 1フレームあたり最大2枚適用（GPU テクスチャ作成の負荷を分散）
	var apply_count = mini(2, _loaded_images.size())
	var to_apply: Array = []
	for i in range(apply_count):
		to_apply.append(_loaded_images.pop_front())
	_load_mutex.unlock()

	for item in to_apply:
		var node = _node_registry.get(item["node_id"]) as Control
		if not node or not is_instance_valid(node):
			continue
		var tex = ImageTexture.create_from_image(item["image"])
		var target = node.get_node_or_null(item["target"]) as TextureRect
		if target:
			target.texture = tex
			target.modulate = Color(1, 1, 1, 0)
			var tween = node.create_tween()
			tween.tween_property(target, "modulate:a", 1.0, 0.2)
		# LOADINGラベルを削除
		var loading_label = node.get_node_or_null("LoadingLabel")
		if not loading_label:
			loading_label = node.get_node_or_null("TilePanel/LoadingLabel")
		if loading_label:
			loading_label.queue_free()

## LOADINGラベル（wrapper）にシマーエフェクトを設定
## wrapper は Control で、内部の "Text" Label にシマーを適用する
func _start_label_breathing(wrapper: Control) -> void:
	if not wrapper:
		return
	var text_label = wrapper.get_node_or_null("Text") as Label
	if text_label:
		ShimmerHelper.apply_to_label(text_label)
