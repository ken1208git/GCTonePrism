# メインのブラウズ画面（menu.tscn）全体の動作を管理する
# ユーザーの入力（キーボード、マウス）を検知し画面の表示を更新しゲームを起動する
# このランチャーの「心臓部」にあたるスクリプト
extends Control

# --- ノードへの参照（オンレディ変数） ---
# `@onready` を使うとGodotはスクリプト実行前にシーンツリーから指定されたノードを
# 安全かつ確実に見つけ出し変数に格納してくれる
# `%` はシーンツリー上でユニークな名前を持つノードへのショートカット記法
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
@onready var details_text: RichTextLabel = %DetailsText


# --- 変数定義 ---
# 現在リストの何番目のゲームが選択されているかを記憶するための変数
var current_selection_index: int = 0


# --- Godotの標準関数 ---

# このノードがシーンツリーに追加された時に一度だけ呼び出される
# メニュー画面の初期設定はここで行う
func _ready() -> void:
	# まずGlobalに保存されているゲーム情報をもとに左側のリストを動的に生成する
	populate_game_list()
	# Godotが次のフレームを処理するまで待機する
	# これにより `populate_game_list` で生成されたノードが確実にシーンツリーに追加された状態になる
	await get_tree().process_frame
	
	# ゲームリストのスクロールバーを見えなくするおまじない
	# スクロール機能は維持したまま見た目だけを透明にする
	var v_scroll_bar = %GameListContainer.get_v_scroll_bar()
	v_scroll_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber_highlight", StyleBoxEmpty.new())
	v_scroll_bar.add_theme_stylebox_override("grabber_pressed", StyleBoxEmpty.new())
	
	# 画面の表示を最初の状態（0番目のゲームが選択された状態）に更新する
	update_display()


# どのノードにも処理されなかった入力イベントが最後にここに送られてくる
# この画面全体で常に反応してほしい入力を処理する
func _unhandled_input(event: InputEvent) -> void:
	# もしゲームリストに一つもゲームがなければ何もせず処理を中断する
	if game_list.get_child_count() == 0:
		return
	
	# 入力イベントがマウスボタンのイベントかどうかを判定する
	if event is InputEventMouseButton:
		# もしマウスホイールが下に回されたら
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			# "ui_down"（下キー）が押された時と全く同じ処理を行う
			current_selection_index = (current_selection_index + 1) % game_list.get_child_count()
			update_display()
			
		# もしマウスホイールが上に回されたら
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			# "ui_up"（上キー）が押された時と全く同じ処理を行う
			current_selection_index = (current_selection_index - 1 + game_list.get_child_count()) % game_list.get_child_count()
			update_display()
	
	# "ui_down"アクション（下キー）が押された瞬間に反応する
	if event.is_action_pressed("ui_down"):
		# 選択インデックスを一つ増やす `%` はリストの最後に到達したら先頭に戻るための計算
		current_selection_index = (current_selection_index + 1) % game_list.get_child_count()
		update_display()
		
	# "ui_up"アクション（上キー）が押された瞬間に反応する
	if event.is_action_pressed("ui_up"):
		# 選択インデックスを一つ減らす `+ game_list.get_child_count()` は0から-1になった時にリストの最後に移動するためのテクニック
		current_selection_index = (current_selection_index - 1 + game_list.get_child_count()) % game_list.get_child_count()
		update_display()


# --- 自作の関数 ---

# `Global.all_games_data` の情報をもとに左側のゲームリストを動的に生成する関数
func populate_game_list() -> void:
	# もしリストに既に何かが表示されていたら一度全て削除して綺麗にする
	for child in game_list.get_children():
		child.queue_free()
	
	# サムネイルの「設計図」であるシーンファイルを読み込む
	var thumbnail_scene: PackedScene = load("res://scenes/components/game_thumbnail.tscn")

	# グローバルに保存されている全てのゲームデータに対してループ処理を行う
	for game_data in Global.all_games_data:
		# 設計図からサムネイルの新しい「実体（インスタンス）」を作成する
		var thumbnail_instance: Panel = thumbnail_scene.instantiate()
		# サムネイル自身に自分のゲームデータを渡して表示を設定させる
		thumbnail_instance.set_game_data(game_data)
		# 完成したサムネイルを `VBoxContainer`（`game_list`）の子として追加する
		game_list.add_child(thumbnail_instance)


# ユーザーの選択に応じて画面全体の表示を更新する最も重要な関数
func update_display() -> void:
	# もしゲームリストが空っぽなら何もせず処理を中断する
	if game_list.get_child_count() == 0:
		return
		
	# 全てのサムネイルを一度チェックする
	for i in range(game_list.get_child_count()):
		var thumbnail = game_list.get_child(i)
		# もし現在選択されているサムネイルなら
		if i == current_selection_index:
			# 少し大きくして目立たせる
			thumbnail.scale = Vector2(1.3, 1.3)
		else:
			# それ以外のサムネイルは元の大きさに戻す
			thumbnail.scale = Vector2(1.0, 1.0)
	
	# 選択されているサムネイルが必ず画面内に表示されるように自動でスクロールさせる
	var selected_thumbnail = game_list.get_child(current_selection_index)
	%GameListContainer.ensure_control_visible(selected_thumbnail)

	# 現在選択されているゲームの完全なデータをGlobalから取得する
	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	
	# --- タイトルとメタ情報の表示 ---
	# `title` -> `game_id` -> `folder_name` の優先順位で表示するタイトルを決定する
	var title_text = selected_game_data.get("title", "")
	if title_text.is_empty():
		title_text = selected_game_data.get("game_id", "")
	if title_text.is_empty():
		title_text = selected_game_data.get("folder_name", "タイトル不明")
	title_label.text = title_text
	
	# メタ情報（制作者、年、ジャンル）を一度クリアしてから組み立てる
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

	# --- 概要情報パネル（InfoPanel）の表示 ---
	var min_players: int = selected_game_data.get("min_players", 0)
	var max_players: int = selected_game_data.get("max_players", 0)
	if min_players > 0 and max_players > 0:
		if min_players == max_players:
			players_value_label.text = "%d" % [min_players]
		else:
			players_value_label.text = "%d〜%d" % [min_players, max_players]
	
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
		playtime_value_label.text = ["～10", "10～30", "30～"][playtime - 1]
	else:
		playtime_gauge.hide()
		playtime_value_label.text = ""

	var controller_support: bool = selected_game_data.get("controller_support", false)
	controller_value_label.text = "対応" if controller_support else "非対応"

	var multiplayer_support: bool = selected_game_data.get("lan_multiplayer_support", false)
	multiplayer_value_label.text = "対応" if multiplayer_support else "非対応"
	
	# --- 詳細情報テキスト（DetailsText）の組み立て ---
	details_text.clear()
	
	var description = selected_game_data.get("description", "")
	if not description.is_empty():
		details_text.append_text(description + "\n\n")
	
	details_text.push_font_size(28)
	details_text.push_bold()
	details_text.append_text("操作方法\n")
	details_text.pop()
	details_text.pop()
	
	var controls: Dictionary = selected_game_data.get("controls", {})
	var keyboard_controls: Dictionary = controls.get("keyboard", {})
	var gamepad_controls: Dictionary = controls.get("gamepad", {})
	
	if not keyboard_controls.is_empty() and not gamepad_controls.is_empty():
		details_text.push_table(2)
		details_text.push_cell()
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("キーボード・マウス\n")
		details_text.pop()
		details_text.pop()
		for action in keyboard_controls:
			details_text.append_text("%s: %s\n" % [action, keyboard_controls[action]])
		details_text.pop()
		details_text.push_cell()
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("コントローラー\n")
		details_text.pop()
		details_text.pop()
		for action in gamepad_controls:
			details_text.append_text("%s: %s\n" % [action, gamepad_controls[action]])
		details_text.pop()
		details_text.pop()
	elif not keyboard_controls.is_empty():
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("キーボード・マウス\n")
		details_text.pop()
		details_text.pop()
		for action in keyboard_controls:
			details_text.append_text("%s: %s\n" % [action, keyboard_controls[action]])
	elif not gamepad_controls.is_empty():
		details_text.push_font_size(24)
		details_text.push_bold()
		details_text.append_text("コントローラー\n")
		details_text.pop()
		details_text.pop()
		for action in gamepad_controls:
			details_text.append_text("%s: %s\n" % [action, gamepad_controls[action]])
	else:
		details_text.append_text("(操作方法は、設定されていません)")

	# --- 背景画像の表示 ---
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
				Global.log_message(Global.LogLevel.WARNING, "背景画像が見つかりません - %s" % full_path)


# 「プレイ」ボタンが押された時にGodotのシグナルによって呼び出される関数
func _on_play_button_pressed() -> void:
	if Global.all_games_data.is_empty():
		return

	var selected_game_data: Dictionary = Global.all_games_data[current_selection_index]
	var executable_path: String = selected_game_data.get("executable_path", "")
	
	if executable_path.is_empty():
		Global.log_message(Global.LogLevel.ERROR, "このゲームには、実行ファイルが設定されていません！")
		return

	var game_dir_path = selected_game_data.get("game_directory_path", "")
	if game_dir_path.is_empty():
		Global.log_message(Global.LogLevel.ERROR, "game_directory_pathがデータにありません！")
		return
		
	var full_executable_path = game_dir_path.path_join(executable_path)
	
	if not FileAccess.file_exists(full_executable_path):
		Global.log_message(Global.LogLevel.ERROR, "実行ファイルが見つかりません！ パスを確認してください: %s" % full_executable_path)
		return

	# ゲームを起動する直前にワーキングディレクトリをそのゲームのフォルダに変更する
	var dir_access = DirAccess.open(".")
	if dir_access:
		var error_code = dir_access.change_dir(game_dir_path)
		if error_code != OK:
			Global.log_message(Global.LogLevel.ERROR, "ワーキングディレクトリの変更に失敗しました: %s" % game_dir_path)
			return
	else:
		Global.log_message(Global.LogLevel.ERROR, "DirAccessインスタンスの作成に失敗しました。")
		return

	# OSの機能を使って外部の.exeファイルを実行する
	var pid = OS.create_process(full_executable_path, [])

	if pid != -1:
		Global.log_message(Global.LogLevel.INFO, "ゲームを起動しました: %s (PID: %d)" % [full_executable_path, pid])
	else:
		Global.log_message(Global.LogLevel.ERROR, "OSレベルでの、ゲームの起動に失敗しました。")
