# このスクリプトは、メインのブラウズ画面（menu.tscn）全体の動作を管理します。
extends Control

# --- ノードへの参照（オンレディ変数） ---
# シーンツリーの「真実」に基づいた、最終形態の参照
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
@onready var info_panel: HBoxContainer = %InfoPanel
@onready var play_button: Button = %PlayButton
@onready var background: TextureRect = %Background

# --- あなたの、新しい、革命的な、構造への、参照 ---
@onready var details_text: RichTextLabel = %DetailsText

# --- 変数定義 ---
var current_selection_index: int = 0
var controls_font: Font = load("res://assets/fonts/SourceHanSansJP/SourceHanSansJP-Regular.otf")

# --- Godotの標準関数 ---
func _ready() -> void:
	populate_game_list()
	await get_tree().process_frame
	
	# ゲームリストの、スクロールバーを、透明にする
	var v_scroll_bar = %GameListContainer.get_v_scroll_bar()
	v_scroll_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber_highlight", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber_pressed", StyleBoxEmpty.new())
	
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
	
	# --- ここからが、最後の、そして、真の、修正 ---
	# 読み込み失敗フラグをチェックし、失敗時は専用の表示を行う
	if selected_game_data.get("is_load_failed", false):
		title_label.text = selected_game_data.get("title", "読み込み失敗")
		meta_label.text = "ゲーム情報の読み込みに失敗しました。"
		details_text.text = "管理者にお知らせください。\n- launcher_info.jsonが存在しないか、\n- JSONの書式が間違っている可能性があります。"
		info_panel.hide()
		play_button.hide()
		background.texture = null
		# 古い、不要な、ノードも、隠しておく
		if has_node("%ControlsLayout"): get_node("%ControlsLayout").hide()
		if has_node("%GameDescriptionText"): get_node("%GameDescriptionText").hide()
		return
	else:
		# 成功した場合は、通常の表示を行う
		info_panel.show()
		play_button.show()

	# --- タイトルと、メタ情報の、表示 ---
	var title_text = selected_game_data.get("title", "")
	if title_text.is_empty():
		title_text = selected_game_data.get("game_id", "")
	if title_text.is_empty():
		title_text = selected_game_data.get("folder_name", "タイトル不明")
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

	# --- 概要情報パネル（InfoPanel）の、表示 ---
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
	
		# --- 詳細情報テキスト（DetailsText）の、組み立て ---
	details_text.clear()
	
	var description = selected_game_data.get("description", "")
	if not description.is_empty():
		# 説明文と「操作方法」の間の、スペースを、少しだけ、狭くする
		details_text.append_text(description + "\n\n")
	
	# 「操作方法」の、テキストサイズを、28に、設定する
	details_text.push_font_size(28)
	details_text.push_bold()
	details_text.append_text("操作方法\n")
	details_text.pop()
	details_text.pop() # font_size
	
	var controls: Dictionary = selected_game_data.get("controls", {})
	var keyboard_controls: Dictionary = controls.get("keyboard", {})
	var gamepad_controls: Dictionary = controls.get("gamepad", {})
	
	if not keyboard_controls.is_empty() and not gamepad_controls.is_empty():
		details_text.push_table(2)
		details_text.push_cell()
		# 「キーボード」の、テキストサイズを、24に、設定する
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("キーボード\n")
		details_text.pop()
		details_text.pop() # font_size
		for action in keyboard_controls:
			details_text.append_text("%s: %s\n" % [action, keyboard_controls[action]])
		details_text.pop()
		details_text.push_cell()
		# 「コントローラー」の、テキストサイズを、24に、設定する
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("コントローラー\n")
		details_text.pop()
		details_text.pop() # font_size
		for action in gamepad_controls:
			details_text.append_text("%s: %s\n" % [action, gamepad_controls[action]])
		details_text.pop()
		details_text.pop()
	elif not keyboard_controls.is_empty():
		# 「キーボード」の、テキストサイズを、24に、設定する
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("キーボード\n")
		details_text.pop()
		details_text.pop() # font_size
		for action in keyboard_controls:
			details_text.append_text("%s: %s\n" % [action, keyboard_controls[action]])
	elif not gamepad_controls.is_empty():
		# 「コントローラー」の、テキストサイズを、24に、設定する
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("コントローラー\n")
		details_text.pop()
		details_text.pop() # font_size
		for action in gamepad_controls:
			details_text.append_text("%s: %s\n" % [action, gamepad_controls[action]])
	else:
		details_text.append_text("(操作方法は、設定されていません)")

	# --- 背景画像の、表示 ---
	var background_path: String = selected_game_data.get("background_path", "")
	background.texture = null
	if not background_path.is_empty():
		var game_dir_path = selected_game_data.get("game_directory_path", "")
		if not game_dir_path.is_empty():
			var full_path = game_dir_path.path_join(background_path)
			if FileAccess.file_exists(full_path):
				if full_path.get_extension().to_lower() in ["png", "jpg", "jpeg", "svg", "webp"]:
					var image = Image.new()
					if image.load(full_path) == OK:
						var texture = ImageTexture.create_from_image(image)
						background.texture = texture
			else:
				Global.log_message("警告: 背景画像が見つかりません - %s" % full_path)
	
	# --- 古い、不要な、ノードを、非表示にする（安全装置） ---
	if has_node("%ControlsLayout"): get_node("%ControlsLayout").hide()
	if has_node("%GameDescriptionText"): get_node("%GameDescriptionText").hide()

func _on_play_button_pressed() -> void:
	if Global.all_games_data.is_empty():
		return

	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	var executable_path: String = selected_game_data.get("executable_path", "")
	
	if executable_path.is_empty():
		Global.log_message("【重大なエラー】: このゲームには、実行ファイルが設定されていません！")
		return

	var game_dir_path = selected_game_data.get("game_directory_path", "")
	if game_dir_path.is_empty():
		Global.log_message("【重大なエラー】: game_directory_pathがデータにありません！")
		return
		
	var full_executable_path = game_dir_path.path_join(executable_path)
	
	if not FileAccess.file_exists(full_executable_path):
		Global.log_message("【重大なエラー】: 実行ファイルが見つかりません！ パスを確認してください: %s" % full_executable_path)
		return

	# --- ここからが、最後の、そして、真の、修正 ---
	# DirAccessの、インスタンスを、作成する
	var dir_access = DirAccess.open(game_dir_path)
	if dir_access == null:
		Global.log_message("エラー: ワーキングディレクトリへのアクセスに失敗しました: %s" % game_dir_path)
		return

	# ゲームを、起動する
	var pid = OS.create_process(full_executable_path, [])

	if pid != -1:
		Global.log_message("ゲームを起動しました: %s (PID: %d)" % [full_executable_path, pid])
	else:
		Global.log_message("エラー: OSレベルでの、ゲームの起動に失敗しました。")
