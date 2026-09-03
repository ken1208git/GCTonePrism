extends Control

## ゲーム選択画面（オーケストレーター）
## 各コンポーネントの連携を担当する

# --- コンポーネント ---
var _carousel: CarouselController
var _game_launcher: GameLauncher
var _idle_mgr: IdleManager
var _glow_animator: GlowAnimator
var _info_display: GameInfoDisplay
var _input_handler: InputHandler

# --- ノード参照 ---
@onready var _carousel_container: Control = $CarouselContainer
@onready var _card_template: Panel = $CarouselContainer/CardTemplate
@onready var _static_focus_border: Panel = $CarouselContainer/FocusLayer/StaticFocusBorder
@onready var _info_panel: Panel = $InfoPanel

@onready var _title_label: Label = $InfoPanel/MarginContainer/VBoxContainer/TitleContainer/TitleScrollWrapper/TitleLabel
@onready var _creator_tags_container: HBoxContainer = $InfoPanel/MarginContainer/VBoxContainer/CreatorScrollWrapper/CreatorTagsContainer

@onready var _players_label: Label = $InfoPanel/MarginContainer/VBoxContainer/SpecsContainer/PlayersContainer/PlayersValueLabel
@onready var _difficulty_val_label: Label = $InfoPanel/MarginContainer/VBoxContainer/SpecsContainer/DifficultyContainer/DifficultyValueLabel
@onready var _playtime_val_label: Label = $InfoPanel/MarginContainer/VBoxContainer/SpecsContainer/PlayTimeContainer/PlayTimeValueLabel
@onready var _controller_label: Label = $InfoPanel/MarginContainer/VBoxContainer/SpecsContainer/ControllerContainer/ControllerValueLabel
@onready var _online_label: Label = $InfoPanel/MarginContainer/VBoxContainer/SpecsContainer/OnlineContainer/OnlineValueLabel

@onready var _desc_scroll: ScrollContainer = $InfoPanel/MarginContainer/VBoxContainer/DescriptionScroll
@onready var _desc_label: Label = $InfoPanel/MarginContainer/VBoxContainer/DescriptionScroll/DescLabel

@onready var _play_button: Button = $InfoPanel/MarginContainer/VBoxContainer/TitleContainer/PlayButton
@onready var _top_bar: CanvasLayer = $TopBar
@onready var _bottom_bar: CanvasLayer = $BottomBar
@onready var _background_texture: TextureRect = $BackgroundLayer/BackgroundTexture
@onready var _background_old: TextureRect = $BackgroundLayer/BackgroundTextureOld
@onready var _launching_overlay: LaunchingOverlay = $LaunchingOverlay

# --- 状態 ---
var _db_manager: DatabaseManager
var _game_repo: GameRepository
var _games: Array[GameInfo] = []
var _selected_index: int = 0
var _active_index: int = 0

# --- トラックパッド・フリースクロール ---
const TRACKPAD_SNAP_DELAY := 0.18       # 最後のトラックパッド入力からこの秒数経過したらスナップ
const TRACKPAD_OFFSET_LIMIT := 6.0      # 視覚オフセットの最大絶対値（暴走防止）
var _trackpad_offset: float = 0.0
var _last_trackpad_time: float = 0.0

# --- 背景連続クロスフェード ---
# 2枚の bg TextureRect (BackgroundTexture / BackgroundTextureOld) を使い、
# scroll_index の整数部の前後ゲームの背景を交互に表示してクロスフェードする
const BG_SLIDE_AMOUNT := 50.0  # クロスフェード時に bg がスライドする最大距離(px)
var _bg_a_index: int = -1  # BackgroundTexture が現在保持しているゲームの index
var _bg_b_index: int = -1  # BackgroundTextureOld が現在保持しているゲームの index

# --- 背景の非同期ロード + 上限付きキャッシュ (#214 / スクロールのカクつき対策) ---
# 旧実装はスクロールで index が変わるたび _process でフルHD画像を同期デコードしていて、
# メインスレッドが数〜数十ms 止まり frame落ち していた。サムネと同様にワーカースレッドで
# デコードし、上限付き LRU キャッシュに ImageTexture を保持する。
const BG_CACHE_MAX := 9  # キャッシュ上限 (フルHD ~8MB/枚、メモリと滑らかさのバランス)
var _bg_cache: Dictionary = {}        # index -> Texture2D (null = 背景なし、として記録)
var _bg_cache_lru: Array = []         # アクセス順 (先頭=最新, 末尾=退避候補)
var _bg_load_thread: Thread = null
var _bg_load_mutex: Mutex = Mutex.new()
var _bg_load_sem: Semaphore = Semaphore.new()
var _bg_load_queue: Array = []        # [{index, path}] (ワーカーへの要求)
var _bg_loaded: Array = []            # [{index, image}] (ワーカーからの結果)
var _bg_requested: Dictionary = {}    # index -> true (キュー投入済みで重複要求を防ぐ)
var _bg_thread_exit: bool = false

# --- フォーカスモーフ用 ---
var _focus_target_rect: Rect2 = Rect2()
var _focus_target_radius: float = 24.0
var _focus_current_radius: float = 24.0
var _focus_initialized: bool = false
var _focus_tweening: bool = false
var _focus_prev_target: Control = null
var _focus_prev_target_pos: Vector2 = Vector2.ZERO
var _exit_button: Button
var _desc_hint_active: bool = false

# --- サムネイル非同期読み込み ---
var _thumb_load_thread: Thread = null
var _thumb_load_mutex: Mutex = Mutex.new()
var _thumb_load_queue: Array = []
var _thumb_loaded_images: Array = []
var _thumb_cancel_requested: bool = false
var _thumb_node_registry: Dictionary = {}  # node_id -> Panel(card)

func _ready():
	# コンポーネント初期化（_process()で参照されるため、早期returnより先に生成）
	_carousel = CarouselController.new()
	_game_launcher = GameLauncher.new()
	_idle_mgr = IdleManager.new()
	_glow_animator = GlowAnimator.new()
	_info_display = GameInfoDisplay.new()
	_input_handler = InputHandler.new()

	if not _load_games_from_db() or _games.is_empty():
		# 復帰フラグが立っていても running-view を再現できないので、ここで消費して
		# 次回の正常な entry に持ち越さない (持ち越すと終了中/プレイ中の morph を誤再生する)。
		AppState.returning_from_game = false
		AppState.returning_from_quit = false
		return

	# ダイアログ表示中もアイドルタイマーを動かすため
	process_mode = Node.PROCESS_MODE_ALWAYS

	# カルーセル生成
	_carousel.create_cards(_games, _card_template, _carousel_container)

	# サムネイルのバックグラウンド読み込みを開始
	_start_thumbnail_loading()

	# 背景の非同期ローダースレッドを起動 (スクロール中の同期デコードを排除)
	_start_bg_loader()

	# フォーカス枠は FocusLayer(CanvasLayer layer=11) で TopBar より前面に表示

	# ボタンスタイル設定
	_glow_animator.register_focus_border(_static_focus_border)
	_exit_button = _top_bar.get_exit_button()
	_top_bar.exit_pressed.connect(_on_exit_button_pressed)

	# 戻るボタン（ブラウズから来たときのみ表示）。(#315) 空ストアから直行した最上位カルーセルは
	# 戻り先のストアが無いので出さない（ESC は退出ダイアログに回す。下の exit_requested 接続参照）。
	if not AppState.return_scene.is_empty() and not AppState.carousel_top_level and _exit_button:
		var back_button = preload("res://scenes/components/back_button.tscn").instantiate()
		_top_bar.get_panel().add_child(back_button)
		back_button.position = Vector2(40, 80)
		# 黒アイコンを白に反転
		var shader = load("res://resources/shaders/invert_color.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		back_button.material = mat
		back_button.pressed.connect(func(): _go_back())
		back_button.mouse_entered.connect(func(): back_button.grab_focus())
		_input_handler.back_button = back_button
		# セクション名ラベル（戻るボタンの横）
		if not AppState.section_title.is_empty():
			var section_label = Label.new()
			section_label.text = AppState.section_title
			section_label.add_theme_font_override("font", preload("res://fonts/NotoSansJP-Bold.ttf"))
			section_label.add_theme_font_size_override("font_size", 56)
			section_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			section_label.custom_minimum_size = Vector2(0, 90)
			section_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_top_bar.get_panel().add_child(section_label)
			section_label.position = Vector2(160, 80)

	# ボタンシグナル
	if _exit_button:
		_exit_button.mouse_entered.connect(func(): _exit_button.grab_focus())
	if _play_button:
		_play_button.pressed.connect(func(): _launch_game())

	# InfoPanelの背景スタイルは .tscn で適用済み
	if _info_panel:
		var guide_label = _info_panel.get_node_or_null("MarginContainer/VBoxContainer/GuideLabel")
		if guide_label:
			guide_label.visible = false

	# 説明文スクロール参照
	_input_handler.desc_scroll = _desc_scroll
	_input_handler.desc_label = _desc_label

	# 入力ハンドラのシグナル接続
	_input_handler.selection_moved.connect(_on_selection_moved)
	_input_handler.free_scroll.connect(_on_free_scroll)
	_input_handler.play_requested.connect(func(): if _play_button: _play_button.grab_focus())
	_input_handler.exit_requested.connect(func(): _on_exit_requested())
	_input_handler.focus_to_card_requested.connect(_update_focus_to_current_card)
	_input_handler.idle_reset_requested.connect(func(): _idle_mgr.reset())

	# ゲームセッション (autoload GameSession) のシグナル接続。監視・状態は GameSession が保持。
	# PLAYING 確定 → 軽量プレイ中シーンへ切替。起動中のままゲームが落ちた場合 (PLAYING 前) は復帰。
	# (中断オーバーレイの resume/quit/退出 は OverlayManager が GameSession を直接呼ぶ。)
	GameSession.playing_confirmed.connect(_on_session_playing)
	GameSession.game_exited.connect(_on_session_exited)

	# カルーセルの上下矢印ボタンを追加
	_add_carousel_arrow_buttons()
	_update_arrow_visibility()

	# 初期表示
	_carousel.current_scroll_index = float(_selected_index)
	_update_info_display(_selected_index)

	# 初期背景は非同期で要求する。同期デコードだと TransitionManager の add_child 時 (=遷移の瞬間)
	# にメインスレッドがフルHDデコードで止まり、ブラウズ→カルーセル遷移がカクつくため。
	# change_scene は新シーンを 0.15s 透明保持 + 0.3s フェードするので、その間にワーカーが
	# デコードを終え _update_continuous_background が拾う (透明保持中なので黒落ちは見えない)。
	_request_bg(_selected_index)

	# フォーカスの初期化（ノードが確定してから）
	call_deferred("_update_focus_state")

	# フォーカスナビゲーション設定
	if _play_button and _exit_button:
		_exit_button.focus_neighbor_bottom = _play_button.get_path()
		_play_button.focus_neighbor_top = _exit_button.get_path()
		_play_button.focus_neighbor_left = _play_button.get_path()
		_play_button.focus_neighbor_right = _play_button.get_path()

	# カルーセル画面の操作ヒント
	_bottom_bar.set_hints([["Esc", _esc_hint_label()], ["Enter", "決定"]])

	set_process(true)
	set_process_input(true)

	# プレイ中シーンからゲーム終了で戻ってきた場合: 起動中画面と同じ running-view 静止状態を
	# 瞬時に再現し、起動モーションの逆再生 (switch_to_normal_view) でカルーセルへ戻す (#214)。
	if AppState.returning_from_game:
		_enter_from_game_exit()

func _process(delta):
	# サムネイル非同期読み込み適用
	_apply_thumb_loaded_images()
	# 背景の非同期ロード結果をキャッシュへ適用
	_apply_bg_loaded()

	# グローアニメーション
	_glow_animator.update(delta)

	# ゲーム実行中の監視は autoload GameSession が _process で行う (シーンをまたいで継続)。

	# アイドルタイマー
	if _session_busy():
		_idle_mgr.reset()
	elif _idle_mgr.update(delta, get_tree().paused):
		IdleManager.transition_to_screensaver(get_tree())
		return

	# シーン遷移中のガード
	if not is_inside_tree() or get_tree() == null:
		return
	if get_tree().paused:
		return

	# ドラムロール入力
	_input_handler.process_drum_roll(delta, _play_button, _exit_button, _session_busy())
	_input_handler.update_desc_scroll(delta)

	if _games.is_empty():
		return

	# 起動中・プレイ中はトラックパッドの残留オフセットも処理しない
	if _session_busy():
		_trackpad_offset = 0.0

	# トラックパッド・フリースクロール: 視覚位置がゲーム1つ分進む度に _selected_index を更新
	# こうすることで背景アニメーション・InfoPanel・フォーカスがリアルタイムに追従する
	# 視覚位置の連続性は selected_index += step / _trackpad_offset -= step で保たれる
	if absf(_trackpad_offset) >= 1.0:
		var total_steps := int(_trackpad_offset)  # truncation: 1.5→1, -1.5→-1
		var prev_index := _selected_index
		_on_selection_moved(total_steps)
		var actual_steps := _selected_index - prev_index
		if actual_steps == total_steps:
			_trackpad_offset -= float(actual_steps)
		else:
			# 端で動けなかった: 残オフセットをクリアして暴走を防ぐ
			_trackpad_offset = 0.0

	# 入力が止まって SNAP_DELAY 経過したら残りの分数オフセットをスナップ
	if absf(_trackpad_offset) > 0.001:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_trackpad_time > TRACKPAD_SNAP_DELAY:
			var snap_delta := roundi(_trackpad_offset)
			if snap_delta != 0:
				_on_selection_moved(snap_delta)
			_trackpad_offset = 0.0

	# カルーセル更新
	var container_center_x = _carousel_container.size.x / 2
	var new_active = _carousel.update_cards(delta, _selected_index, _trackpad_offset,
		get_viewport_rect().size, container_center_x,
		_input_handler.using_mouse, _static_focus_border, _session_busy())

	if new_active != _active_index:
		_active_index = new_active
		_update_focus_state()

	# 背景画像をカルーセルの scroll_index に応じて連続クロスフェード
	# scroll_index = N (整数) → 完全に game[N] の背景
	# scroll_index = N + 0.5 → game[N] と game[N+1] が 50/50 で混ざる
	# scroll_index = N + 1 → 完全に game[N+1] の背景
	if not _session_busy():
		_update_continuous_background()

	# フォーカスモーフ更新
	_update_focus_morph(delta)

	# ボトムバーの表示切替・ヒント更新
	if _bottom_bar:
		_bottom_bar.get_panel().visible = not _input_handler.using_mouse
		var desc_focused := _desc_scroll and _desc_scroll.has_focus()
		if desc_focused and not _desc_hint_active:
			_bottom_bar.set_hints([["Esc", _esc_hint_label()]])
			_desc_hint_active = true
		elif not desc_focused and _desc_hint_active:
			_bottom_bar.set_hints([["Esc", _esc_hint_label()], ["Enter", "決定"]])
			_desc_hint_active = false

func _input(event):
	if get_tree().paused:
		return
	# 説明文エリア上のホイールを横取り → lerp補間で滑らかスクロール
	if event is InputEventMouseButton and event.is_pressed():
		if _desc_scroll and _desc_scroll.get_global_rect().has_point(event.global_position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_input_handler.handle_desc_wheel(event, get_viewport())
				return
	_input_handler.handle_input(event, get_viewport(),
		_play_button, _exit_button,
		_session_busy(), _games.is_empty())

func _unhandled_input(event):
	if get_tree().paused:
		return
	# 起動中・プレイ中はカルーセルへの入力を完全にブロック
	if _session_busy():
		return
	_input_handler.handle_unhandled_input(event, get_viewport())

func _exit_tree():
	# サムネイル読み込みスレッドをキャンセル
	if _thumb_load_thread and _thumb_load_thread.is_started():
		_thumb_load_mutex.lock()
		_thumb_cancel_requested = true
		_thumb_load_queue.clear()
		_thumb_load_mutex.unlock()
		_thumb_load_thread.wait_to_finish()
	# 背景ローダースレッドを停止 (semaphore を起こして exit させる)。
	# 未処理要求を捨ててから起こすことで、join 待ちを「in-flight の 1 枚デコード完了」までに抑える
	# (PLAYING 確定でこのシーンを破棄する瞬間のヒッチを最小化。worker は pop 前に exit を見るので
	#  キュー残があっても本来 1 枚で抜けるが、意図を明示し将来の改変にも頑健にする)。
	if _bg_load_thread and _bg_load_thread.is_started():
		_bg_thread_exit = true
		_bg_load_mutex.lock()
		_bg_load_queue.clear()
		_bg_load_mutex.unlock()
		_bg_load_sem.post()
		_bg_load_thread.wait_to_finish()
	if DialogManager and DialogManager.has_method("close_current_dialog"):
		DialogManager.close_current_dialog()
	# 注: ここで companion の監視停止 (unwatch) はしない。プレイ中シーンへの切替で game_selection は
	# 破棄されるが、ゲームは実行中で監視 (HOME/Guide 検知) を継続する必要があるため。監視停止はゲーム終了時
	# (GameSession._on_exited の unwatch)、アプリ終了時の companion 停止は LauncherAgent の PREDELETE が担う。

# --- サムネイル非同期読み込み ---

func _start_thumbnail_loading() -> void:
	var queue = _carousel.get_image_load_queue()
	if queue.is_empty():
		return
	for item in queue:
		_thumb_node_registry[item["node_id"]] = item["card"]
		_thumb_load_queue.append({"node_id": item["node_id"], "path": item["path"]})
	# LOADINGラベルにシマーエフェクト + 暗い背景（Clipper直下に配置）
	for card in _carousel.card_nodes:
		var clipper = card.get_node_or_null("Clipper")
		if not clipper:
			continue
		var label = clipper.get_node_or_null("NoImageLabel")
		if label and label.visible and label.text == "LOADING":
			# 既存の DimBackground があれば重複追加しない
			if not clipper.get_node_or_null("DimBackground"):
				var dim = ColorRect.new()
				dim.name = "DimBackground"
				dim.color = Color(0.08, 0.08, 0.08, 1.0)
				dim.set_anchors_preset(Control.PRESET_FULL_RECT)
				dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
				clipper.add_child(dim)
				# NoImageLabelの前に配置（テキストが前面に来るよう）
				clipper.move_child(dim, label.get_index())
			ShimmerHelper.apply_to_label(label)
	_thumb_load_thread = Thread.new()
	_thumb_load_thread.start(_thumb_load_images_in_thread)

func _thumb_load_images_in_thread() -> void:
	while true:
		_thumb_load_mutex.lock()
		if _thumb_cancel_requested or _thumb_load_queue.is_empty():
			_thumb_load_mutex.unlock()
			break
		var item = _thumb_load_queue.pop_front()
		_thumb_load_mutex.unlock()

		var image = Image.load_from_file(item["path"])
		if image:
			_thumb_load_mutex.lock()
			if _thumb_cancel_requested:
				_thumb_load_mutex.unlock()
				break
			_thumb_loaded_images.append({
				"image": image,
				"node_id": item["node_id"]
			})
			_thumb_load_mutex.unlock()

func _apply_thumb_loaded_images() -> void:
	_thumb_load_mutex.lock()
	if _thumb_loaded_images.is_empty():
		_thumb_load_mutex.unlock()
		return

	var apply_count = mini(2, _thumb_loaded_images.size())
	var to_apply: Array = []
	for i in range(apply_count):
		to_apply.append(_thumb_loaded_images.pop_front())
	_thumb_load_mutex.unlock()

	for item in to_apply:
		var card = _thumb_node_registry.get(item["node_id"]) as Panel
		if not card or not is_instance_valid(card):
			continue
		var tex = ImageTexture.create_from_image(item["image"])
		var icon_rect = card.get_node_or_null("Clipper/Icon") as TextureRect
		if icon_rect:
			icon_rect.texture = tex
			icon_rect.visible = true
			icon_rect.modulate = Color(1, 1, 1, 0)
			var tween = card.create_tween()
			tween.tween_property(icon_rect, "modulate:a", 1.0, 0.2)
		var no_image_label = card.get_node_or_null("Clipper/NoImageLabel")
		if no_image_label:
			no_image_label.queue_free()
		var dim_bg = card.get_node_or_null("Clipper/DimBackground")
		if dim_bg:
			dim_bg.queue_free()

# --- 内部メソッド ---

func _on_selection_moved(dir: int) -> void:
	var new_index = clampi(_selected_index + dir, 0, _games.size() - 1)
	if new_index != _selected_index:
		_selected_index = new_index
		_update_info_display(_selected_index)
		_update_arrow_visibility()
		_input_handler.reset_desc_scroll()
	elif dir < 0 and _selected_index == 0 and _input_handler.back_button:
		# カルーセル最上端で上入力 → 戻るボタンにフォーカス
		_input_handler.back_button.grab_focus()

## トラックパッドのフリースクロール: 視覚オフセットに蓄積するだけ。
## スナップは _process 側で TRACKPAD_SNAP_DELAY 経過後にまとめて行う。
func _on_free_scroll(delta_amount: float) -> void:
	_trackpad_offset = clampf(_trackpad_offset + delta_amount,
		-TRACKPAD_OFFSET_LIMIT, TRACKPAD_OFFSET_LIMIT)
	_last_trackpad_time = Time.get_ticks_msec() / 1000.0
	_idle_mgr.reset()

func _update_info_display(index: int) -> void:
	_info_display.update_display(_games[index],
		_title_label, _creator_tags_container, _desc_label,
		_players_label, _difficulty_val_label,
		_playtime_val_label,
		_controller_label, _online_label)

## カルーセルの scroll_index に応じて2枚の bg をクロスフェードする。
## 整数の前後ゲームの背景を BackgroundTexture / BackgroundTextureOld に割り当て、
## fract で alpha を補間する。
func _update_continuous_background() -> void:
	if _games.is_empty() or not _background_texture or not _background_old:
		return

	var scroll: float = _carousel.current_scroll_index
	var max_idx: int = _games.size() - 1
	var lower_idx: int = clampi(int(floor(scroll)), 0, max_idx)
	var upper_idx: int = clampi(int(ceil(scroll)), 0, max_idx)
	var fract: float = clampf(scroll - float(lower_idx), 0.0, 1.0)

	# 必要な背景を非同期要求 (隣接もプリフェッチして flick スクロールに追従)。
	_request_bg(lower_idx - 1)
	_request_bg(lower_idx)
	_request_bg(upper_idx)
	_request_bg(upper_idx + 1)

	# キャッシュに用意できたら差し替える。未ロードなら前の絵を保持 (黒落ち・カクつき回避)。
	# ロード完了は次フレーム以降に _apply_bg_loaded がキャッシュへ載せ、ここで拾われる。
	if _bg_a_index != lower_idx and _bg_cache.has(lower_idx):
		_background_texture.texture = _bg_cache[lower_idx]
		_bg_a_index = lower_idx
		_touch_lru(lower_idx)
	if _bg_b_index != upper_idx and _bg_cache.has(upper_idx):
		_background_old.texture = _bg_cache[upper_idx]
		_bg_b_index = upper_idx
		_touch_lru(upper_idx)

	# scene tree 順で bg_old (BackgroundTextureOld) が先 = 背面、bg_a (BackgroundTexture) が前面。
	# 背景なしゲーム（texture == null）と切り替わる場合に "突然現れる" のを防ぐため、
	# 各 bg の有無に応じて alpha を計算する:
	#   - 両方ある: bg_a=1-fract, bg_b=1 (標準クロスフェード)
	#   - lower のみ: bg_a=1-fract, bg_b は不可視 (lower がフェードアウトして暗くなる)
	#   - upper のみ: bg_a 不可視, bg_b=fract (upper がフェードイン)
	var has_a: bool = _background_texture.texture != null
	var has_b: bool = _background_old.texture != null

	if has_a:
		_background_texture.modulate = Color(1, 1, 1, 1.0 - fract)
		_background_old.modulate = Color(1, 1, 1, 1.0)
	else:
		_background_texture.modulate = Color(1, 1, 1, 0.0)
		_background_old.modulate = Color(1, 1, 1, fract if has_b else 0.0)

	# 位置スライド: 前のゲーム (lower) は上にスライドして消え、次のゲーム (upper) は下から上がってくる
	# fract = 0 (lower 全表示): bg_a y=0、bg_b y=+50 (下)
	# fract = 1 (upper 全表示): bg_a y=-50 (上)、bg_b y=0
	_background_texture.position.y = -BG_SLIDE_AMOUNT * fract
	_background_old.position.y = BG_SLIDE_AMOUNT * (1.0 - fract)

# --- 背景の非同期ロード + LRU キャッシュ ---

## 背景ローダースレッドを起動する。Semaphore で要求待ちし、来たらデコードして結果を積む。
func _start_bg_loader() -> void:
	_bg_load_thread = Thread.new()
	_bg_load_thread.start(_bg_loader_worker)


func _bg_loader_worker() -> void:
	while true:
		_bg_load_sem.wait()
		if _bg_thread_exit:
			return
		_bg_load_mutex.lock()
		if _bg_load_queue.is_empty():
			_bg_load_mutex.unlock()
			continue
		var item: Dictionary = _bg_load_queue.pop_front()
		_bg_load_mutex.unlock()
		# 重い処理 (ディスク読み + デコード) はスレッド側で。
		var img := Image.load_from_file(item["path"])
		_bg_load_mutex.lock()
		if not _bg_thread_exit:
			_bg_loaded.append({"index": item["index"], "image": img})
		_bg_load_mutex.unlock()


## 指定 index の背景を非同期要求する。キャッシュ済み / 要求済みなら何もしない。
## パスが無効なら即「背景なし(null)」としてキャッシュ (再要求を防ぐ)。
func _request_bg(index: int) -> void:
	if index < 0 or index >= _games.size():
		return
	if _bg_cache.has(index) or _bg_requested.has(index):
		return
	var game: GameInfo = _games[index]
	var path: String = GamePathResolver.resolve_path(game.background_path, game.game_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		# 設定されているのにファイルが無い場合はアセット欠落のミスコンフィグなので警告 (旧 GameInfoDisplay の
		# 診断ログを復活)。_bg_cache に null を入れるので以降 _request_bg は早期 return し、1 ゲーム 1 回のみ。
		if not path.is_empty():
			push_warning("[GameSelection] 背景画像が見つかりません (game_id=%s): %s" % [game.game_id, path])
		_bg_cache[index] = null
		_touch_lru(index)
		_evict_lru()
		return
	_bg_requested[index] = true
	_bg_load_mutex.lock()
	_bg_load_queue.append({"index": index, "path": path})
	_bg_load_mutex.unlock()
	_bg_load_sem.post()


## ワーカーがデコードした結果を ImageTexture 化してキャッシュへ。GPU アップロードはメインスレッド
## 必須だが軽いので 1フレーム最大2件に絞って山を作らない (サムネ適用と同方針)。
func _apply_bg_loaded() -> void:
	_bg_load_mutex.lock()
	if _bg_loaded.is_empty():
		_bg_load_mutex.unlock()
		return
	var batch: Array = []
	var n: int = mini(2, _bg_loaded.size())
	for i in range(n):
		batch.append(_bg_loaded.pop_front())
	_bg_load_mutex.unlock()

	for item in batch:
		var idx: int = item["index"]
		var img: Image = item["image"]
		var tex: Texture2D = null
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
		_bg_cache[idx] = tex
		_bg_requested.erase(idx)
		_touch_lru(idx)
	_evict_lru()


## 起動直後・復帰直後に「今すぐ必要な1枚」を同期で得る (キャッシュ優先)。スクロール中は使わない。
func _get_bg_texture_sync(index: int) -> Texture2D:
	if index < 0 or index >= _games.size():
		return null
	if _bg_cache.has(index):
		_touch_lru(index)
		return _bg_cache[index]
	var game: GameInfo = _games[index]
	var path: String = GamePathResolver.resolve_path(game.background_path, game.game_id)
	var tex: Texture2D = null
	if not path.is_empty() and FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_bg_cache[index] = tex
	_bg_requested.erase(index)
	_touch_lru(index)
	_evict_lru()
	return tex


## LRU: アクセスした index を先頭へ。
func _touch_lru(index: int) -> void:
	_bg_cache_lru.erase(index)
	_bg_cache_lru.push_front(index)


## LRU: 上限超過分を末尾から退避。表示中 (bg_a/bg_b) は退避しない。
func _evict_lru() -> void:
	while _bg_cache_lru.size() > BG_CACHE_MAX:
		var victim: int = -1
		for i in range(_bg_cache_lru.size() - 1, -1, -1):
			var cand: int = _bg_cache_lru[i]
			if cand != _bg_a_index and cand != _bg_b_index:
				victim = cand
				break
		if victim == -1:
			break  # 全部が表示中 (実質起きないが安全弁)
		_bg_cache_lru.erase(victim)
		_bg_cache.erase(victim)

func _update_focus_to_current_card() -> void:
	if _carousel.card_nodes.size() > _active_index:
		var card = _carousel.card_nodes[_active_index]
		if not card.has_focus():
			card.grab_focus()

func _update_focus_state() -> void:
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner and (focus_owner is Panel and focus_owner in _carousel.card_nodes):
		_update_focus_to_current_card()

## セッション (起動/プレイ中) または復帰演出中か。この間はカルーセル入力・アイドルを止める。
func _session_busy() -> bool:
	return GameSession.is_running() or (_game_launcher != null and _game_launcher.is_returning())


## GameSession: PLAYING 確定 → 軽量プレイ中シーンへ切替 (重いカルーセルを解放, #214)。
## 背景は両シーンとも 1.05 拡大なので、フェード無しの瞬時切替で継続させる (TransitionManager を使わない)。
func _on_session_playing() -> void:
	# (#311) サービスモードの試遊テストも GameSession 経由で起動する (本物の中断オーバーレイを確認するため)。
	# その間は browse シーンを paused のまま据え置き service overlay が前面なので、playing.tscn への切替は
	# しない (signal は paused でも届くためここで明示的に無視する)。
	if ServiceMode.is_open():
		return
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file("res://scenes/playing.tscn")


## GameSession: ゲーム終了。ここに来るのは「PLAYING 前 (起動中) にゲームが落ちた」場合のみ
## (PLAYING 後はプレイ中シーンが処理する)。退出先に応じてスクリーンセーバー or 通常表示復帰。
func _on_session_exited() -> void:
	# (#311) 試遊テストの GameSession 起動が終了したとき、browse シーンは何もしない (service overlay が
	# game_exited を受けて 〇× 記録 → 次へ進める)。ここでカルーセル復帰/スクリーンセーバー遷移をすると
	# サービスモードの裏で勝手に画面が動いて壊れる。退出フラグ (退出メニュー由来) もテスト中は無視。
	if ServiceMode.is_open():
		return
	# (#35 / レビュー M-2) **試遊かどうかはここで同期に読む**。`ServiceMode.is_open()` だけでは足りない —
	# 試遊中に 60 秒のオートクローズでサービスモードが先に閉じうるので (`play_record_writer.gd` が
	# 「終了時の is_open 判定は使ってはいけない」と規約化しているのと同じ理由)、閉じた後にスタッフが
	# 退出するとスタッフの回答が本物のアンケートとして保存されてしまう。
	# `game_session.gd` は `test_session = false` を emit の**後**に実行するので、同期購読者である
	# 本関数からはまだ読める (deferred にすると常に false になる)。
	var is_test := GameSession.test_session
	if GameSession.should_exit_to_screensaver():
		if is_test:
			# 試遊はプレイ記録と同じく集計に混ぜない (#311)。アンケートを挟まずそのまま戻す。
			IdleManager.transition_to_screensaver(get_tree())
			return
		# (#35) 退出は「席を離れる」意図なので全体アンケートを挟む。ここに来るのは PLAYING 前に
		# ゲームが落ちた場合なので、ゲーム個別アンケートは出さない (遊べていない人に感想を聞かない)。
		SurveyFlow.maybe_show_launcher_end(func(): IdleManager.transition_to_screensaver(get_tree()))
		return
	if _launching_overlay:
		_launching_overlay.hide_overlay()
	_game_launcher.switch_to_normal_view(_carousel.card_nodes, _info_panel,
		_top_bar.get_panel(), _static_focus_border, get_tree(),
		_carousel_container, _bottom_bar.get_panel(), _background_texture)
	_update_focus_to_current_card()
	_update_arrow_visibility()


## プレイ中シーンからの復帰: 起動中画面の running-view 静止状態 (カルーセルフェード済み・背景 1.05・
## 「プレイ中」表示) を瞬時に再現してから、起動モーションの逆再生でカルーセルへ戻る。
## 見た目: playing シーンの最終フレームと連続 → なめらかに通常表示へ。
func _enter_from_game_exit() -> void:
	AppState.returning_from_game = false
	# 中断メニュー終了 (終了中画面を見せた) 由来なら running-view 再現も「終了中」で連続させる。
	# 自然終了は「プレイ中」(起動モーションの素直な逆再生)。
	var overlay_state: LaunchingOverlay.State = (
		LaunchingOverlay.State.QUITTING if AppState.returning_from_quit
		else LaunchingOverlay.State.PLAYING)
	AppState.returning_from_quit = false
	if _games.is_empty():
		return
	# --- running-view 静止状態を瞬時にセット ---
	# 非選択カードは透明・選択カードのみ残す (起動演出のフェードアウト後と同じ)。
	for i in range(_carousel.card_nodes.size()):
		var card := _carousel.card_nodes[i]
		card.visible = true
		card.modulate.a = 0.0 if i != _selected_index else 1.0
	# パネル類・フォーカス枠は非表示 (alpha 0)。
	if _info_panel:
		_info_panel.modulate.a = 0.0
	if _top_bar and _top_bar.get_panel():
		_top_bar.get_panel().modulate.a = 0.0
	if _bottom_bar and _bottom_bar.get_panel():
		_bottom_bar.get_panel().modulate.a = 0.0
	if _static_focus_border:
		_static_focus_border.modulate.a = 0.0
	# 上下矢印も非表示。
	var up_btn := _carousel_container.get_node_or_null("ScrollUpButton")
	var down_btn := _carousel_container.get_node_or_null("ScrollDownButton")
	if up_btn:
		up_btn.modulate.a = 0.0
	if down_btn:
		down_btn.modulate.a = 0.0
	# 選択ゲームの背景を読み込む。通常は _update_continuous_background が load するが、
	# 復帰演出中は _session_busy()=true でそれが止まるため、ここで明示的に load しないと真っ黒になる。
	# (キャッシュ優先の同期取得。新規シーンなら 1枚ぶんブロックするが復帰直後の1回のみ。)
	_background_texture.texture = _get_bg_texture_sync(_selected_index)
	_background_texture.modulate = Color(1, 1, 1, 1)
	_background_texture.position.y = 0.0
	_bg_a_index = _selected_index
	# 裏面 (BackgroundTextureOld) は復帰中は不要なので隠す。演出後 _update_continuous_background が再構築。
	_background_old.modulate = Color(1, 1, 1, 0)
	_bg_b_index = -1
	# 背景を 1.05 拡大状態に (playing シーンと一致)。
	for bg in [_background_texture, _background_old]:
		if bg:
			var bg_size: Vector2 = bg.size
			if bg_size.x <= 0.0 or bg_size.y <= 0.0:
				bg_size = bg.get_viewport_rect().size
			bg.pivot_offset = bg_size / 2.0
			bg.scale = Vector2(GameLauncher.LAUNCH_BG_ZOOM_SCALE, GameLauncher.LAUNCH_BG_ZOOM_SCALE)
	# 直前の playing 画面と同じ状態 (プレイ中 / 終了中) を瞬時に出す (instant=true でフェードイン無し)。
	if _launching_overlay:
		var game := _games[_selected_index]
		_launching_overlay.show_for_game(game.title, overlay_state, true)

	# --- 起動モーションの逆再生でカルーセルへ ---
	if _launching_overlay:
		_launching_overlay.hide_overlay()
	_game_launcher.switch_to_normal_view(_carousel.card_nodes, _info_panel,
		_top_bar.get_panel(), _static_focus_border, get_tree(),
		_carousel_container, _bottom_bar.get_panel(), _background_texture)
	_update_focus_to_current_card()
	_update_arrow_visibility()


func _launch_game() -> void:
	if _games.is_empty() or _session_busy():
		return
	var game: GameInfo = _games[_selected_index]
	# 起動シーケンス開始を先に宣言 (演出中も is_running=true にして、カルーセル更新が
	# modulate を戻してフェードアウトを打ち消すのを防ぐ)。
	if not GameSession.begin_launch(game):
		return
	# 中断メニュー (#30) に表示する走行中ゲーム情報を登録。
	OverlayManager.set_current_game(game)
	# LAUNCHING 表示 + 起動演出 (本シーンのノード)。
	if _launching_overlay:
		_launching_overlay.show_for_game(game.title, LaunchingOverlay.State.LAUNCHING)
	_game_launcher.switch_to_running_view(_carousel.card_nodes, _selected_index,
		_info_panel, _top_bar.get_panel(), _static_focus_border, get_tree(),
		_carousel_container, _bottom_bar.get_panel(), _background_texture)
	# 演出を見せてからプロセス起動 (旧 launch_game の await 1.0s 相当)
	await get_tree().create_timer(1.0).timeout
	# 実プロセス起動 (autoload GameSession)。
	if not GameSession.start_process():
		# 起動失敗: 表示を戻す
		if _launching_overlay:
			_launching_overlay.hide_overlay()
		_game_launcher.switch_to_normal_view(_carousel.card_nodes, _info_panel,
			_top_bar.get_panel(), _static_focus_border, get_tree(),
			_carousel_container, _bottom_bar.get_panel(), _background_texture)

## (#315) ESC ヒントの文言。ESC の実挙動に合わせる: 最上位カルーセル (空ストアから直行) は ESC=退出
## ダイアログなので「退出」(store_browse と同じ)、通常 (ストアから来た) は ESC=ストアへ戻るので「戻る」。
func _esc_hint_label() -> String:
	return "退出" if AppState.carousel_top_level else "戻る"

## (#315) ESC / exit_requested の宛先。最上位カルーセル (空ストアから直行) は戻り先のストアが無いので、
## store_browse と同じく退出ダイアログ (退出しますか？) を出す。通常 (ストアから来た) は従来どおり戻る。
func _on_exit_requested() -> void:
	if AppState.carousel_top_level:
		_on_exit_button_pressed()
	else:
		_go_back()

func _go_back() -> void:
	if TransitionManager._transitioning:
		return
	if not AppState.return_scene.is_empty():
		var scene = AppState.return_scene
		TransitionManager.change_scene(scene)
		AppState.clear()
	else:
		# 戻り先が無い = ここが最上位で、この「戻る」は展示からの退出そのもの
		# (通常はストアへ戻る経路だが、戻り先を見失った場合の受け皿としてこの分岐がある)。
		# 退出はすべて全体アンケートを挟む — この 1 本だけ素通りだと、経路によって
		# 集まったり集まらなかったりして集計が偏る。
		# 状態の後始末も退出ボタン経由 (`_on_exit_button_pressed`) と揃える — 経路によって
		# フィルタ結果が次の来場者に残ったり残らなかったりするのは追いにくい (レビュー L-3)。
		AppState.clear()
		SurveyFlow.maybe_show_launcher_end(func(): IdleManager.transition_to_screensaver(get_tree()))

func _on_exit_button_pressed() -> void:
	var callback = func(idx):
		if idx == 1:
			AppState.clear()
			# (#35) 退出確認の後に全体アンケートを挟んでからスクリーンセーバーへ。
			SurveyFlow.maybe_show_launcher_end(func(): IdleManager.transition_to_screensaver(get_tree()))
	DialogManager.show_message("確認", "退出しますか？\nタイトル画面に戻ります。",
		["キャンセル", "退出する"], callback,
		[Color(0.3, 0.3, 0.3), Color(0.8, 0.2, 0.2)])

func _load_games_from_db() -> bool:
	# AppStateにフィルタ済みゲームがあればそちらを使用
	if not AppState.filtered_games.is_empty():
		_games = AppState.filtered_games
		# initial_game_id に合わせて _selected_index を設定
		if not AppState.initial_game_id.is_empty():
			for i in range(_games.size()):
				if _games[i].game_id == AppState.initial_game_id:
					_selected_index = i
					break
		print("[GameSelection] ✅ AppStateからゲーム読み込み: %d 件 (セクション: %s)" % [_games.size(), AppState.section_title])
		return true

	# 従来のDB読み込み（フォールバック）
	_db_manager = DatabaseManager.new()
	var db_path = PathManager.get_database_path()
	print("[GameSelection] データベース読み込み開始. ターゲットパス: ", db_path)

	if not _db_manager.open():
		print("[GameSelection] ❌ データベースのオープンに失敗しました (E-1001)")
		ErrorManager.show_error(ErrorCode.DATABASE_NOT_FOUND)
		set_process_input(false)
		return false

	_game_repo = GameRepository.new(_db_manager)
	_games = _game_repo.get_all_games()
	_db_manager.close()

	if _games.is_empty():
		print("[GameSelection] ⚠️ データベースは開けましたが、表示対象のゲームが0件です (E-1006)")
		ErrorManager.show_error(ErrorCode.DATABASE_NO_GAMES_REGISTERED)
		set_process_input(false)
		return true

	print("[GameSelection] ✅ DB読み込み完了: %d 件のゲームが見つかりました" % _games.size())
	return true

# --- フォーカスモーフ ---

func _update_focus_morph(delta: float) -> void:
	if not _static_focus_border:
		return

	# シーン遷移中は非表示（遷移完了後に正確な位置へ即座配置するためリセット）
	if TransitionManager._transitioning:
		_static_focus_border.visible = false
		_focus_initialized = false
		return

	# マウス操作中は非表示
	if _input_handler.using_mouse:
		_static_focus_border.visible = false
		_focus_initialized = false
		return

	# フォーカスオーナーを取得して目標を決定
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		_static_focus_border.visible = false
		return

	var target: Control = null
	var target_radius: float = 24.0

	if focus_owner is Panel and focus_owner in _carousel.card_nodes:
		# カード → アクティブサイズで画面中央に固定（scaleアニメの影響を受けない）
		target = focus_owner
		target_radius = CarouselController.CORNER_RADIUS * CarouselController.SCALE_ACTIVE + CarouselController.FOCUS_MARGIN
		var active_size = CarouselController.CARD_SIZE * CarouselController.SCALE_ACTIVE
		var viewport_center = get_viewport_rect().size / 2
		var container_center_x = _carousel_container.size.x / 2
		_static_focus_border.visible = true
		_focus_target_rect = Rect2(
			Vector2(container_center_x - active_size.x / 2, viewport_center.y - active_size.y / 2),
			active_size)
		_focus_target_radius = target_radius
	elif focus_owner is Button:
		# ボタン（退出/戻る/プレイ）
		target = focus_owner
		target_radius = 18
		_static_focus_border.visible = true
		_focus_target_rect = target.get_global_rect()
		_focus_target_radius = target_radius
	elif focus_owner == _desc_scroll:
		# 説明文スクロール
		target = focus_owner
		target_radius = 8
		_static_focus_border.visible = true
		_focus_target_rect = target.get_global_rect()
		_focus_target_radius = target_radius
	else:
		_static_focus_border.visible = false
		return

	# 初回はズームイン登場
	if not _focus_initialized:
		_static_focus_border.global_position = _focus_target_rect.position
		_static_focus_border.size = _focus_target_rect.size
		_focus_current_radius = _focus_target_radius
		_focus_prev_target = target
		_focus_prev_target_pos = _focus_target_rect.position
		_focus_initialized = true
		_focus_tweening = true
		var style = _static_focus_border.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.set_corner_radius_all(int(_focus_current_radius))
		# ズームイン + フェードイン（中心からスケール）
		_static_focus_border.pivot_offset = _focus_target_rect.size / 2.0
		_static_focus_border.scale = Vector2(1.15, 1.15)
		_static_focus_border.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_static_focus_border, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_static_focus_border, "modulate:a", 1.0, 0.25)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func(): _focus_tweening = false)
		return

	# Tween中は位置/サイズの更新をスキップ（干渉防止）
	if _focus_tweening:
		_focus_prev_target = target
		_focus_prev_target_pos = _focus_target_rect.position
		return

	# 同じターゲットの位置変化（カードアニメーション等）は即座反映
	if target == _focus_prev_target:
		var target_delta = _focus_target_rect.position - _focus_prev_target_pos
		_static_focus_border.global_position += target_delta

	# lerpで補間
	var speed = delta * 25.0
	_static_focus_border.global_position = _static_focus_border.global_position.lerp(
		_focus_target_rect.position, speed)
	_static_focus_border.size = _static_focus_border.size.lerp(
		_focus_target_rect.size, speed)
	_focus_current_radius = lerpf(_focus_current_radius, _focus_target_radius, speed)
	var style = _static_focus_border.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.set_corner_radius_all(int(_focus_current_radius))

	_focus_prev_target = target
	_focus_prev_target_pos = _focus_target_rect.position

func _add_carousel_arrow_buttons() -> void:
	var arrow_size := Vector2(80, 80)
	var pad = 12.0

	for i in range(2):
		var is_up = (i == 0)
		var btn = Button.new()
		btn.name = "ScrollUpButton" if is_up else "ScrollDownButton"
		btn.flat = true
		btn.custom_minimum_size = arrow_size
		btn.size = arrow_size
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 画面中央(選択中の大きなアイコン位置)を基準に配置
		btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		btn.offset_left = -arrow_size.x / 2.0
		btn.offset_right = arrow_size.x / 2.0
		
		# さっき（240）と今（200）の中間で220pxに設定
		var y_offset = 220.0
		if is_up:
			btn.offset_top = -y_offset - arrow_size.y / 2.0
			btn.offset_bottom = -y_offset + arrow_size.y / 2.0
		else:
			btn.offset_top = y_offset - arrow_size.y / 2.0
			btn.offset_bottom = y_offset + arrow_size.y / 2.0

		# アイコン
		var icon = TextureRect.new()
		icon.texture = preload("res://resources/icons/arrow.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# 白化シェーダー
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://resources/shaders/invert_color.gdshader")
		icon.material = mat
		
		# 向きの回転 (元が左向き◀前提)
		icon.pivot_offset = (arrow_size - Vector2(pad * 2, pad * 2)) / 2.0
		icon.rotation_degrees = 90 if is_up else -90
		
		icon.position = Vector2(pad, pad)
		icon.size = arrow_size - Vector2(pad * 2, pad * 2)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate.a = 0.5
		btn.add_child(icon)
		
		# ホバー/フォーカス時の見た目変化
		btn.mouse_entered.connect(func(): icon.modulate.a = 1.0)
		btn.mouse_exited.connect(func(): icon.modulate.a = 0.5)
		btn.button_down.connect(func(): icon.modulate.a = 0.3)
		btn.button_up.connect(func(): if btn.is_hovered(): icon.modulate.a = 1.0 else: icon.modulate.a = 0.5)
		
		# 押した時の処理
		if is_up:
			btn.pressed.connect(func(): _on_selection_moved(-1))
		else:
			btn.pressed.connect(func(): _on_selection_moved(1))
			
		for state_data in [
			{"state": "normal", "alpha": 0.2},
			{"state": "hover", "alpha": 0.5},
			{"state": "pressed", "alpha": 0.7}
		]:
			var s = StyleBoxFlat.new()
			s.bg_color = Color(0, 0, 0, state_data["alpha"])
			s.set_corner_radius_all(40) # 丸型
			btn.add_theme_stylebox_override(state_data["state"], s)
			
		btn.z_index = 100
		_carousel_container.add_child(btn)

func _update_arrow_visibility() -> void:
	if not is_instance_valid(_carousel_container): return
	var up_btn = _carousel_container.get_node_or_null("ScrollUpButton")
	var down_btn = _carousel_container.get_node_or_null("ScrollDownButton")
	
	if up_btn:
		up_btn.visible = (_selected_index > 0)
	if down_btn:
		down_btn.visible = (_selected_index < _games.size() - 1)
