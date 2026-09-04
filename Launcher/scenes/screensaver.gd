extends Control

## スクリーンセーバー画面
## マイルストーン3: 基本画面・画面遷移

## 画面状態
enum ScreenState {
	LOGO_DISPLAY,  # ロゴ表示画面（初期状態）
	SLIDESHOW      # ゲームプレビュースライドショー（将来実装）
}

var current_state: ScreenState = ScreenState.LOGO_DISPLAY
var idle_timer: float = 0.0
var idle_timeout: float = 30.0  # 30秒でスライドショーに遷移

var _db_manager: DatabaseManager

@onready var _start_message: Label = $CenterContainer/VBoxContainer/StartMessage
@onready var _mosaic: Control = $BrickMosaicBackground
@onready var _logo: TextureRect = $CenterContainer/VBoxContainer/LogoClip/Logo

var _logo_base_y: float = 0.0

func _ready():
	# (#344) ここに着いた = 来場者が入れ替わった。中断メニューの案内を次の人にも出す。
	# **リセットをここに置くのが要点** — `AppState.clear()` は退出経路の一部でしか呼ばれず、
	# 「遊び終えて退出」「放置して帰る」という最も多い帰り方が通らない。この画面は経路を問わず
	# 必ず通るので、1 箇所で全経路をカバーできる (初回説明 #253 と同じ「毎回が初回」の考え方)。
	AppState.pause_hint_shown = false

	# キー入力とコントローラー入力を有効化
	set_process_input(true)
	set_process(true)

	if _start_message:
		_start_message.text = "PRESS ANY KEY"

	if _logo:
		_logo_base_y = _logo.position.y

	_load_mosaic_backgrounds()

func _process(delta):
	# アイドルタイマーの更新
	if current_state == ScreenState.LOGO_DISPLAY:
		idle_timer += delta
		
		# システム時刻ベース（複数PC間で同期）
		var t := Time.get_unix_time_from_system()

		# PRESS ANY KEY のブリージングアニメーション（周期2秒）
		if _start_message:
			_start_message.modulate.a = 0.6 + 0.4 * sin(t * 3.0)

		# ロゴのふわふわアニメーション（周期3秒、振幅10px）
		if _logo:
			_logo.position.y = _logo_base_y + sin(t * TAU / 3.0) * 10.0

		if idle_timer >= idle_timeout:
			# スライドショーに遷移（将来実装）
			pass

func _input(event):
	var viewport = get_viewport()
	if not viewport:
		return
	
	# キー入力、マウスボタン、コントローラーボタンでゲーム選択画面に遷移
	# マウス移動（Motion）は除外する（誤作動防止）
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			_transition_to_game_selection()
			viewport.set_input_as_handled()
			return
	
	# 任意のキー/ボタンでロゴ表示画面に戻る（スライドショー表示時）
	if current_state == ScreenState.SLIDESHOW:
		if event is InputEventKey or event is InputEventJoypadButton:
			_transition_to_logo_display()
			viewport.set_input_as_handled()
			return

## ゲーム選択画面に遷移
## 表示対象の初回説明スライドがあれば intro_guide を挟み、無ければ直接ストアへ。
## 空スライドのときに intro_guide を挟むと、TransitionManager の遷移中再入ガードにより
## intro_guide → store_browse の再遷移が無視され画面が固まりうるため、ここで事前分岐する (#253)。
func _transition_to_game_selection():
	var target: String
	if _has_visible_intro_slides():
		target = "res://scenes/intro_guide.tscn"
	else:
		# (#315) スライド無し → ストア入口を解決。空ストア (0 セクション) なら store_browse を挟まず
		# カルーセル直行にして「一瞬空の store_browse がちらつく」のを防ぐ (StoreEntryRouter)。
		target = StoreEntryRouter.resolve_and_prepare()
	TransitionManager.change_scene(target)

## 表示対象スライドが1件以上あるか（遷移先ルーティング用の軽量チェック）
func _has_visible_intro_slides() -> bool:
	var db := DatabaseManager.new()
	if not db.open():
		return false
	var repo := IntroSlideRepository.new(db)
	var has_slides := repo.has_visible_slides()
	db.close()
	return has_slides

## ロゴ表示画面に遷移
func _transition_to_logo_display():
	current_state = ScreenState.LOGO_DISPLAY
	idle_timer = 0.0

## スライドショーに遷移（将来実装）
func _transition_to_slideshow():
	current_state = ScreenState.SLIDESHOW

## DBからゲーム背景画像パスを収集してモザイク背景を構築
func _load_mosaic_backgrounds() -> void:
	_db_manager = DatabaseManager.new()
	if not _db_manager.open():
		return
	var game_repo := GameRepository.new(_db_manager)
	var games := game_repo.get_all_games()
	_db_manager.close()

	var bg_paths: Array[String] = []
	for game in games:
		if game.background_path.is_empty():
			continue
		var path := GamePathResolver.resolve_path(game.background_path, game.game_id)
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var ext := path.get_extension().to_lower()
		if ext not in ["png", "jpg", "jpeg", "bmp", "webp", "tga"]:
			continue
		bg_paths.append(path)

	if not bg_paths.is_empty():
		_mosaic.setup(bg_paths)
