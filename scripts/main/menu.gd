# このスクリプトは、メインのブラウズ画面（menu.tscn）全体の動作を管理します。
extends Control

# --- ノードへの参照（オンレディ変数） ---
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
@onready var keyboard_controls_grid: GridContainer = %KeyboardControlsGrid
@onready var gamepad_controls_grid: GridContainer = %GamepadControlsGrid
@onready var keyboard_panel: PanelContainer = %KeyboardPanel
@onready var gamepad_panel: PanelContainer = %GamepadPanel

# --- 変数定義 ---
var current_selection_index: int = 0
var controls_font: Font = load("res://assets/fonts/SourceHanSansJP/SourceHanSansJP-Regular.otf")

# --- Godotの標準関数 ---
func _ready() -> void:
	populate_game_list()
	await get_tree().process_frame
	update_display()

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if game_list.get_child_count() == 0:
		return
	if event.is_action_pressed("ui_down"):
		current_selection_index = (current_selection_index + 1) % game_list.get_child_count()
		update_display()
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

func update_display() -> void:
	if game_list.get_child_count() == 0:
		return
	for i in range(game_list.get_child_count()):
		var thumbnail = game_list.get_child(i)
		if i == current_selection_index:
			thumbnail.scale = Vector2(1.3, 1.3)
		else:
			thumbnail.scale = Vector2(1.0, 1.0)
	
	var selected_thumbnail = game_list.get_child(current_selection_index)
	%GameListContainer.ensure_control_visible(selected_thumbnail)

	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	
	var title_text = selected_game_data.get("title", "")
	if title_text.is_empty():
		title_text = Global.launcher_config.get("games_order")[current_selection_index]
	title_label.text = title_text
	
	meta_label.clear()
	var developers: Array = selected_game_data.get("developers", [])
	if not developers.is_empty():
		var dev: Dictionary = developers[0]
		if not dev.is_empty():
			var last_name = dev.get("last_name", "")
			var first_name = dev.get("first_name", "")
			if not last_name.is_empty() or not first_name.is_empty():
				meta_label.append_text("%s %s " % [last_name, first_name])
				var grade = dev.get("grade")
				if grade != null and grade > 0:
					meta_label.append_text("(%s期生)  " % [grade])
				elif grade == 0:
					meta_label.append_text("(教員)  ")
			else:
				meta_label.append_text("制作者不明  ")
		else:
			meta_label.append_text("制作者不明  ")
	else:
		meta_label.append_text("制作者不明  ")
	
	var release_year = selected_game_data.get("release_year")
	if release_year != null and release_year > 0:
		meta_label.append_text("%s  " % [release_year])
	else:
		meta_label.append_text("公開年不明  ")

	var genre_list: Array = selected_game_data.get("genre", [])
	if not genre_list.is_empty():
		meta_label.append_text("ジャンル: %s" % [", ".join(genre_list)])

	var min_players: int = selected_game_data.get("min_players", 0)
	var max_players: int = selected_game_data.get("max_players", 0)
	if min_players > 0 and max_players > 0:
		if min_players == max_players:
			players_value_label.text = "%d人" % [min_players]
		else:
			players_value_label.text = "%d〜%d人" % [min_players, max_players]
	
	var difficulty: int = selected_game_data.get("difficulty", 0)
	if difficulty > 0:
		difficulty_gauge.show()
		difficulty_gauge.max_value = 3
		difficulty_gauge.value = difficulty
		difficulty_value_label.text = ["かんたん", "ふつう", "むずかしい"][difficulty - 1]
	else:
		difficulty_gauge.hide()
		difficulty_value_label.text = ""

	var playtime: int = selected_game_data.get("play_time", 0)
	if playtime > 0:
		playtime_gauge.show()
		playtime_gauge.max_value = 3
		playtime_gauge.value = playtime
		playtime_value_label.text = ["短い", "ふつう", "長い"][playtime - 1]
	else:
		playtime_gauge.hide()
		playtime_value_label.text = ""

	var controller_support: bool = selected_game_data.get("controller_support", false)
	controller_value_label.text = "対応" if controller_support else "非対応"

	var multiplayer_support: bool = selected_game_data.get("lan_multiplayer_support", false)
	multiplayer_value_label.text = "対応" if multiplayer_support else "非対応"
	
	description_text.text = selected_game_data.get("description", "")
	
	for child in keyboard_controls_grid.get_children():
		child.queue_free()
	for child in gamepad_controls_grid.get_children():
		child.queue_free()
		
	var controls: Dictionary = selected_game_data.get("controls", {})
	var keyboard_controls: Dictionary = controls.get("keyboard", {})
	if not keyboard_controls.is_empty():
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
		%KeyboardPanel.hide()

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
