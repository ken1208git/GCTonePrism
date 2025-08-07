# このスクリプトは、メインのブラウズ画面（menu.tscn）全体の動作を管理します。
extends Control

# --- ノードへの参照（オンレディ変数） ---
# このスクリプトから、動的に内容を変更したいUI部品に、あらかじめ「あだ名」を付けておく。
# `%`を使った「シーンユニーク名」で指定することで、将来レイアウトを変更しても、コードを壊れにくくする。
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
# 現在、リストの何番目が選択されているかを記録しておくための変数。0は、一番最初の項目を意味する。
var current_selection_index: int = 0
# 操作方法のテキストに適用するための、フォントファイルを、あらかじめ読み込んでおく。
var controls_font: Font = load("res://assets/fonts/SourceHanSansJP/SourceHanSansJP-Regular.otf")

# --- Godotの標準関数 ---

# このノード（Menuシーン）が、最初に画面に表示されたときに、一度だけ呼ばれる関数。
func _ready() -> void:
	# ゲームリストのサムネイルを、JSONの情報を元に、自動で生成する。
	populate_game_list()
	# すべてのレイアウト計算が終わった、完璧なタイミングで、最初の表示更新を行う。
	await get_tree().process_frame
	update_display()

# この関数は、毎フレーム呼び出される。'delta'は、前回この関数が呼ばれてから経過した時間（秒）。
# 今回は使わないので、引数名の先頭にアンダースコア `_` を付けて、意図的に使っていないことを示している。
func _process(_delta: float) -> void:
	pass

# この関数は、キーボード入力など、まだ誰にも処理されていない入力を受け取る。
func _unhandled_input(event: InputEvent) -> void:
	# もし、リストにゲームが一つもなければ、キー操作を受け付けない。
	if game_list.get_child_count() == 0:
		return
	
	# "ui_down"（下キー）が押された瞬間を検知する。
	if event.is_action_pressed("ui_down"):
		# 選択番号を1つ増やし、リストの数で割った余りを求めることで、リストの範囲をループさせる。
		current_selection_index = (current_selection_index + 1) % game_list.get_child_count()
		# 選択が変わったので、画面の表示をすべて更新する。
		update_display()
		
	# "ui_up"（上キー）が押された瞬間を検知する。
	if event.is_action_pressed("ui_up"):
		# 選択番号を1つ減らす。リストの数を足してから余りを求めることで、マイナスになるのを防ぐ。
		current_selection_index = (current_selection_index - 1 + game_list.get_child_count()) % game_list.get_child_count()
		# 選択が変わったので、画面の表示をすべて更新する。
		update_display()

# --- 自作の関数 ---

# ゲームリストに、サムネイルを動的に生成して並べるための関数。
func populate_game_list() -> void:
	# まず、リストにすでに何か項目があれば、すべて削除して、まっさらな状態にする。
	for child in game_list.get_children():
		child.queue_free()
	
	# ゲームサムネイルの「設計図」（シーンファイル）を、あらかじめ読み込んでおく。
	var thumbnail_scene: PackedScene = load("res://scenes/components/game_thumbnail.tscn")

	# Globalに保存されている、すべてのゲーム情報の配列を、一つずつ処理するループ。
	for game_data in Global.all_games_data:
		# 設計図から、新しいサムネイルの「実体」（インスタンス）を作成する。
		var thumbnail_instance: Panel = thumbnail_scene.instantiate()
		# 作成したサムネイルインスタンスに、対応するゲームの情報を渡して、画像などを設定させる。
		thumbnail_instance.set_game_data(game_data)
		# 完成したサムネイルを、リスト（VBoxContainer）の子として追加する。
		game_list.add_child(thumbnail_instance)

# 選択が変更されたときに、リストの見た目と、詳細情報パネルの両方を更新する、最強の関数。
func update_display() -> void:
	# もし、リストにゲームが一つもなければ、何もせずに処理を終了する。
	if game_list.get_child_count() == 0:
		return
		
	# --- 1. リストの見た目を更新し、自動スクロールさせる ---
	# リストの中の、すべてのサムネイルをチェックする。
	for i in range(game_list.get_child_count()):
		var thumbnail = game_list.get_child(i)
		# もし、このサムネイルが、現在選択されているものなら
		if i == current_selection_index:
			# 少しだけ大きくして、目立たせる。
			thumbnail.scale = Vector2(1.3, 1.3)
		else:
			# それ以外は、元の大きさに戻す。
			thumbnail.scale = Vector2(1.0, 1.0)
	
	# 現在選択されているサムネイルが、常に画面の中央に来るように、スクロールを自動調整する。
	var selected_thumbnail = game_list.get_child(current_selection_index)
	%GameListContainer.ensure_control_visible(selected_thumbnail)

	# --- 2. 詳細情報パネルを更新する ---
	# 現在選択されているゲームの、完全なデータを、Globalから取得する。
	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	
	# --- Title (未入力の場合は、フォルダ名で代替表示) ---
	var title_text = selected_game_data.get("title", "")
	if title_text.is_empty():
		title_text = Global.launcher_config.get("games_order")[current_selection_index]
	title_label.text = title_text
	
	# --- Meta (情報がなければ、その部分ごと表示しない、賢い組み立て) ---
	meta_label.clear() # まず、内容をリセットする。
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

	# --- InfoPanel: Players ---
	var min_players: int = selected_game_data.get("min_players", 0)
	var max_players: int = selected_game_data.get("max_players", 0)
	if min_players > 0 and max_players > 0:
		if min_players == max_players:
			players_value_label.text = "%d人" % [min_players]
		else:
			players_value_label.text = "%d〜%d人" % [min_players, max_players]
	
	# --- InfoPanel: Difficulty (未入力の場合は、ゲージごと非表示) ---
	var difficulty: int = selected_game_data.get("difficulty", 0)
	if difficulty > 0:
		difficulty_gauge.show()
		difficulty_gauge.max_value = 3
		difficulty_gauge.value = difficulty
		difficulty_value_label.text = ["かんたん", "ふつう", "むずかしい"][difficulty - 1]
	else:
		difficulty_gauge.hide()
		difficulty_value_label.text = ""

	# --- InfoPanel: PlayTime (未入力の場合は、ゲージごと非表示) ---
	var playtime: int = selected_game_data.get("play_time", 0)
	if playtime > 0:
		playtime_gauge.show()
		playtime_gauge.max_value = 3
		playtime_gauge.value = playtime
		playtime_value_label.text = ["短い", "ふつう", "長い"][playtime - 1]
	else:
		playtime_gauge.hide()
		playtime_value_label.text = ""

	# --- InfoPanel: Controller & Multiplayer ---
	var controller_support: bool = selected_game_data.get("controller_support", false)
	controller_value_label.text = "対応" if controller_support else "非対応"

	var multiplayer_support: bool = selected_game_data.get("lan_multiplayer_support", false)
	multiplayer_value_label.text = "対応" if multiplayer_support else "非対応"
	
	# --- Description ---
	description_text.text = selected_game_data.get("description", "")
	
	# --- Background ---
	var background_path: String = selected_game_data.get("background_path", "")
	%Background.texture = null
	if not background_path.is_empty():
		var games_dir_path = Global.launcher_config.get("games_directory", "")
		var game_id = selected_game_data.get("game_id", "")
		var full_path = games_dir_path.path_join(game_id).path_join(background_path)
		if FileAccess.file_exists(full_path):
			if full_path.get_extension().to_lower() in ["png", "jpg", "jpeg", "svg", "webp"]:
				var image = Image.new()
				if image.load(full_path) == OK:
					var texture = ImageTexture.create_from_image(image)
					%Background.texture = texture
		else:
			Global.log_message("警告: 背景画像が見つかりません - %s" % full_path)
	
	# --- Controls (操作方法の表を、動的に生成する) ---
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

	var games_dir_path_internal = Global.launcher_config.get("games_directory", "")
	var games_dir_path_global = ProjectSettings.globalize_path(games_dir_path_internal)
	var game_id = selected_game_data.get("game_id", "")
	var full_path = games_dir_path_global.path_join(game_id).path_join(executable_path)
	
	if not FileAccess.file_exists(full_path):
		Global.log_message("【重大なエラー】: 実行ファイルが見つかりません！ パスを確認してください: %s" % full_path)
		return

	var pid = OS.create_process(full_path, [])

	if pid != -1:
		Global.log_message("ゲームを起動しました。プロセスID: %d" % pid)
	else:
		Global.log_message("エラー: OSレベルでの、ゲームの起動に失敗しました。")
