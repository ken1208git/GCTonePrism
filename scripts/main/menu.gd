# このスクリプトは、メインのブラウズ画面（menu.tscn）全体の動作を管理します。
extends Control

# --- ノードへの参照（オンレディ変数） ---

# このスクリプトから、動的に内容を変更したいUI部品にだけ、「あだ名」を付けておく。
@onready var game_list: VBoxContainer = %GameList
@onready var title_label: Label = %TitleLabel
@onready var meta_label: RichTextLabel = %MetaLabel
@onready var players_value_label: Label = %PlayersValue
@onready var difficulty_gauge: TextureProgressBar = %DifficultyTextureProgressBar
@onready var difficulty_value_label: Label = %DifficultyValue
@onready var playtime_gauge: TextureProgressBar = %PlayTimeTextureProgressBar
@onready var playtime_value_label: Label = %PlayTimeValue
@onready var controller_value_label: Label = %ControllerValue
@onready var multiplayer_value_label: Label = %MultiplayerValue
@onready var description_text: RichTextLabel = %GameDescriptionText
@onready var keyboard_panel: PanelContainer = %KeyboardPanel
@onready var gamepad_panel: PanelContainer = %GamepadPanel
@onready var keyboard_controls_grid: GridContainer = %KeyboardControlsGrid
@onready var gamepad_controls_grid: GridContainer = %GamepadControlsGrid


# --- 変数定義 ---

# 現在、リストの何番目が選択されているかを記録しておくための変数。
var current_selection_index: int = 0

# 操作方法のテキストに適用するための、フォントファイルを、あらかじめ読み込んでおく。
var controls_font: Font = load("res://assets/fonts/SourceHanSansJP/SourceHanSansJP-Regular.otf")

# --- Godotの標準関数 ---

func _ready() -> void:
	populate_game_list()
	# すべてのレイアウト計算が終わった、完璧なタイミングで、最初の表示更新を行う。
	await get_tree().process_frame
	update_display()


func _process(_delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	# もし、リストに項目がなければ、キー操作を受け付けない。
	if game_list.get_child_count() == 0:
		return

	# "ui_down"（下キー）が押された瞬間
	if event.is_action_pressed("ui_down"):
		current_selection_index = (current_selection_index + 1) % game_list.get_child_count()
		update_display()

	# "ui_up"（上キー）が押された瞬間
	if event.is_action_pressed("ui_up"):
		current_selection_index = (current_selection_index - 1 + game_list.get_child_count()) % game_list.get_child_count()
		update_display()


# --- 自作の関数 ---

func populate_game_list() -> void:
	for child in game_list.get_children():
		child.queue_free()

	var thumbnail_scene: PackedScene = load("res://scenes/components/game_thumbnail.tscn")

	for game_data in Global.all_games_data:
		var thumbnail_instance: Panel = thumbnail_scene.instantiate()
		thumbnail_instance.set_game_data(game_data)
		game_list.add_child(thumbnail_instance)


# 選択が変更されたときに、リストの見た目と、詳細情報パネルの両方を更新する、最強の関数。
func update_display() -> void:
	# --- 1. リストの見た目を更新する ---
	if game_list.get_child_count() == 0:
		return
	for i in range(game_list.get_child_count()):
		var thumbnail = game_list.get_child(i)
		if i == current_selection_index:
			thumbnail.scale = Vector2(1.05, 1.05)
		else:
			thumbnail.scale = Vector2(1.0, 1.0)

	# --- 2. 詳細情報パネルを更新する ---
	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	
	# --- Title (フォールバック対応) ---
	# まず、JSONからtitleを取得してみる。
	var title_text = selected_game_data.get("title", "")
	
	# もし、titleが空っぽだったら、最後の手段として、100%信頼できるフォルダ名を使う。
	if title_text.is_empty():
		# Global.all_games_dataの順番は、games_orderの順番と同じなので、
		# current_selection_indexを使って、対応するフォルダ名を取得できる。
		title_text = Global.launcher_config.get("games_order")[current_selection_index]
			
	title_label.text = title_text
	
	# --- Meta (RichTextLabelで、動的に組み立てる) ---
	meta_label.clear() # まず、内容を空にする
	var developers: Array = selected_game_data.get("developers", [])
	# まず、配列自体が空っぽでないかを確認する。
	if not developers.is_empty():
		# 次に、配列の最初の要素（dev）を取得する。
		var dev: Dictionary = developers[0]
		# そして、その中身も、本当に空っぽでないかを確認する。
		if not dev.is_empty():
			var last_name = dev.get("last_name", "")
			var first_name = dev.get("first_name", "")
			# 姓と名の、両方が空っぽでない場合のみ、名前を表示する。
			if not last_name.is_empty() or not first_name.is_empty():
				meta_label.append_text("%s %s " % [last_name, first_name])
				var grade = dev.get("grade")
				if grade != null:
					meta_label.append_text("(%s期生)  " % [grade])
			else:
				# 配列に`{}`だけが入っている場合は、こちらが実行される。
				meta_label.append_text("制作者不明  ")
		else:
			# 配列に`{}`だけが入っている場合も、こちらが実行される。
			meta_label.append_text("制作者不明  ")
	else:
		# 配列が`[]`の場合は、こちらが実行される。
		meta_label.append_text("制作者不明  ")
	
	var release_year = selected_game_data.get("release_year")
	if release_year != null:
		meta_label.append_text("%s  " % [release_year])
	else:
		meta_label.append_text("公開年不明  ")

	var genre_list: Array = selected_game_data.get("genre", [])
	if not genre_list.is_empty():
		meta_label.append_text("ジャンル: %s" % [", ".join(genre_list)])

	# --- InfoPanel: Players ---
	var min_players: int = selected_game_data.get("min_players", 1) # デフォルト値を1に
	var max_players: int = selected_game_data.get("max_players", 1) # デフォルト値を1に
	if min_players == max_players:
		players_value_label.text = "%d人" % [min_players]
	else:
		players_value_label.text = "%d〜%d人" % [min_players, max_players]
		
	# --- InfoPanel: Difficulty ---
	var difficulty: int = selected_game_data.get("difficulty", 1) # デフォルト値を1に
	difficulty_gauge.show() # 常に表示
	difficulty_gauge.max_value = 3
	difficulty_gauge.value = difficulty
	var difficulty_texts = ["かんたん", "ふつう", "むずかしい"]
	difficulty_value_label.text = difficulty_texts[difficulty - 1]
	
	# --- InfoPanel: PlayTime ---
	var playtime: int = selected_game_data.get("play_time", 1) # デフォルト値を1に
	playtime_gauge.show() # 常に表示
	playtime_gauge.max_value = 3
	playtime_gauge.value = playtime
	var playtime_texts = ["～10", "10～30", "30～"]
	playtime_value_label.text = playtime_texts[playtime - 1]
	
	# --- InfoPanel: Controller ---
	var controller_support: bool = selected_game_data.get("controller_support", false) # デフォルト値をfalseに
	controller_value_label.text = "対応" if controller_support else "非対応"

	# --- InfoPanel: Multiplayer ---
	var multiplayer_support: bool = selected_game_data.get("lan_multiplayer_support", false) # デフォルト値をfalseに
	multiplayer_value_label.text = "対応" if multiplayer_support else "非対応"
	
	# --- Description ---
	description_text.text = selected_game_data.get("description", "") # 空の場合は、空で表示
	
	# --- Background (ファイル存在チェック機能付き) ---
	var background_path: String = selected_game_data.get("background_path", "")
	# まず、背景用のTextureRectを、あらかじめ空にしておく。
	%Background.texture = null
	
	if not background_path.is_empty():
		var games_dir_path = Global.launcher_config.get("games_directory", "")
		var game_id = selected_game_data.get("game_id", "")
		var full_path = games_dir_path.path_join(game_id).path_join(background_path)
		
		# 画像を読み込む前に、そのパスに、本当にファイルが存在するかを確認する。
		if FileAccess.file_exists(full_path):
			# もし、ファイルが画像なら... (動画対応は、後で追加)
			if full_path.get_extension() in ["png", "jpg", "jpeg", "svg", "webp"]:
				var image = Image.new()
				if image.load(full_path) == OK:
					var texture = ImageTexture.create_from_image(image)
					%Background.texture = texture
		else:
			# もし、ファイルが見つからなければ、警告を出す。
			Global.log_message("警告: 背景画像が見つかりません - %s" % full_path)
	
	# --- Controls (操作方法の表を、動的に生成する) ---
	
	# まず、両方のグリッド（表）の中身を、一度、すべて削除して、まっさらにする。
	for child in keyboard_controls_grid.get_children():
		child.queue_free()
	for child in gamepad_controls_grid.get_children():
		child.queue_free()
		
	# ゲームデータから、controlsオブジェクトを取得する。
	var controls: Dictionary = selected_game_data.get("controls", {})
	
	# --- キーボード操作の表を生成 ---
	var keyboard_controls: Dictionary = controls.get("keyboard", {})
	if not keyboard_controls.is_empty():
		# 親であるKeyboardPanelを表示する。
		%KeyboardPanel.show()
		
		for action in keyboard_controls:
			var key = keyboard_controls[action]
			
			var action_label = Label.new()
			action_label.text = action
			action_label.add_theme_font_override("font", controls_font)
			
			var key_label = Label.new()
			key_label.text = key
			key_label.add_theme_font_override("font", controls_font)
			
			keyboard_controls_grid.add_child(action_label)
			keyboard_controls_grid.add_child(key_label)
	else:
		# もし、キーボード操作が一つもなければ、パネルごと非表示にする。
		%KeyboardPanel.hide()

	# --- ゲームパッド操作の表を生成 ---
	var gamepad_controls: Dictionary = controls.get("gamepad", {})
	if not gamepad_controls.is_empty():
		%GamepadPanel.show()

		for action in gamepad_controls:
			var button = gamepad_controls[action]
			
			var action_label = Label.new()
			action_label.text = action
			action_label.add_theme_font_override("font", controls_font)
			
			var button_label = Label.new()
			button_label.text = button
			button_label.add_theme_font_override("font", controls_font)
			
			gamepad_controls_grid.add_child(action_label)
			gamepad_controls_grid.add_child(button_label)
	else:
		# もし、ゲームパッド操作が一つもなければ、パネルごと非表示にする。
		%GamepadPanel.hide()
	

# プレイボタンが押されたときに、呼び出される関数。
func _on_play_button_pressed() -> void:
	if Global.all_games_data.is_empty():
		return

	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	var executable_path: String = selected_game_data.get("executable_path", "")
	
	if executable_path.is_empty():
		Global.log_message("【重大なエラー】: このゲームには、実行ファイルが設定されていません！")
		return

	# ★★★ ここからが、最後の魔法 ★★★
	# "res://../Games" のようなGodotの内部パスを、OSが理解できる絶対パスに変換する。
	var games_dir_path_internal = Global.launcher_config.get("games_directory", "")
	var games_dir_path_global = ProjectSettings.globalize_path(games_dir_path_internal)
	
	var game_id = selected_game_data.get("game_id", "")
	
	# 絶対パスを元に、実行ファイルへの完全なパスを組み立てる。
	var full_path = games_dir_path_global.path_join(game_id).path_join(executable_path)
	
	if not FileAccess.file_exists(full_path):
		Global.log_message("【重大なエラー】: 実行ファイルが見つかりません！ パスを確認してください: %s" % full_path)
		return

	# OS.create_processには、OSが理解できる「絶対パス」を渡す必要がある。
	var pid = OS.create_process(full_path, [])

	if pid != -1:
		Global.log_message("ゲームを起動しました。プロセスID: %d" % pid)
	else:
		Global.log_message("エラー: OSレベルでの、ゲームの起動に失敗しました。")
