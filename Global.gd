# GCTonePrismプロジェクト全体で共有される設定やデータを管理する、ただ一つの特別な場所。
# Godotの「自動ロード」機能に登録することで、どこからでも `Global` という名前でアクセスできる。
extends Node

# --- アプリケーション情報 ---
const APP_VERSION = "0.1.0-dev.13"


# --- グローバル変数 ---
var current_game_pid: int = -1
var current_selected_game_data: Dictionary = {}
var is_debug_mode = false
var launcher_config: Dictionary = {}
var all_games_data: Array[Dictionary] = []


# --- ログ機能 ---
var log_history = []
const MAX_LOG_LINES = 20


# --- Godotの標準関数 ---
func _ready():
	load_launcher_config()
	load_all_games_info()
	log_message("GCTonePrism is Ready.")
	if not InputMap.has_action("toggle_debug"):
		log_message("警告: アクション 'toggle_debug' がインプットマップにありません。")

func _unhandled_input(_event):
	if Input.is_action_just_pressed("toggle_debug"):
		is_debug_mode = not is_debug_mode
		if is_debug_mode:
			log_message("Debug Mode: ON")
		else:
			log_message("Debug Mode: OFF")


# --- 自作のグローバル関数 ---

func load_launcher_config():
	var config_path = "res://launcher_config.json"
	if not FileAccess.file_exists(config_path):
		log_message("エラー: " + config_path + " が見つかりません。")
		return
	var file = FileAccess.open(config_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) != OK:
		log_message("エラー: launcher_config.json の解析に失敗しました。")
		return
	launcher_config = json.get_data()
	log_message("launcher_config.json の読み込みに成功しました。")
	log_message("  > ゲームディレクトリ: " + launcher_config.get("games_directory", "未設定"))
	log_message("  > ゲーム表示順: " + str(launcher_config.get("games_order", [])))


func load_all_games_info():
	if launcher_config.is_empty():
		log_message("エラー: ランチャー設定が読み込まれていないため、ゲーム情報をスキャンできません。")
		return

	var games_dir_path: String
	var relative_games_dir = launcher_config.get("games_directory", "")

	if OS.has_feature("editor"):
		games_dir_path = ProjectSettings.globalize_path(relative_games_dir)
	else:
		# --- ここからが、最後の、そして、真の、修正 ---
		# .exeとして、実行されている場合、"res://"という、神の、言葉は、理解できない。
		# もし、パスが、"res://"で、始まっていたら、その部分を、取り除いてあげる。
		if relative_games_dir.begins_with("res://"):
			relative_games_dir = relative_games_dir.trim_prefix("res://")
		
		var exe_dir = OS.get_executable_path().get_base_dir()
		games_dir_path = exe_dir.path_join(relative_games_dir).simplify_path()
		# --- ここまでが、最後の、そして、真の、修正 ---
	
	var games_order: Array = launcher_config.get("games_order", [])

	if games_dir_path.is_empty() or games_order.is_empty():
		log_message("警告: games_directory または games_order が未設定です。")
		return
	
	log_message("ゲーム情報のスキャンを開始します... 基準パス: " + games_dir_path)

	for game_folder_name in games_order:
		var game_folder_path = games_dir_path.path_join(game_folder_name)
		var game_data: Dictionary = {}

		if not DirAccess.dir_exists_absolute(game_folder_path):
			log_message("【重大な警告】: ゲームフォルダ '%s' が見つかりません！リストから除外します。" % game_folder_path)
			continue

		var info_file_path = game_folder_path.path_join("launcher_info.json")
		if not FileAccess.file_exists(info_file_path):
			log_message("警告: %s が見つかりません。スキップします。" % info_file_path)
			continue
		
		var file = FileAccess.open(info_file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(content) != OK:
			log_message("警告: %s の解析に失敗しました。スキップします。" % info_file_path)
			continue
		
		game_data = json.get_data()
		
		game_data["folder_name"] = game_folder_name
		game_data["game_directory_path"] = game_folder_path
		
		var required_keys = [
			"game_id", "title", "description", "developers", "release_year",
			"genre", "min_players", "max_players", "difficulty", "play_time",
			"thumbnail_path", "background_path", "executable_path",
			"controller_support", "lan_multiplayer_support", "controls"
		]
		
		for key in required_keys:
			if not game_data.has(key) or is_value_empty(game_data[key]):
				if key == "executable_path":
					log_message("【重大な警告】: '%s' の '%s' が未入力です！このゲームは起動できません。" % [game_folder_name, key])
				elif key == "title":
					log_message("情報: '%s' の 'title' が未入力です。UIには、代わりにフォルダ名('%s')が表示されます。" % [game_folder_name, game_folder_name])
				else:
					log_message("情報: '%s' の '%s' が未入力です。" % [game_folder_name, key])

		var game_id = game_data.get("game_id", "")
		if game_id != game_folder_name:
			log_message("【重大な警告】: '%s' の game_id ('%s') が未入力か、フォルダ名と一致しません！" % [game_folder_name, game_id])

		all_games_data.append(game_data)
		log_message("  > 「%s」の情報を読み込みました。" % game_data.get("title", game_folder_name))

	log_message("ゲーム情報のスキャンが完了しました。合計 %d 件のゲームを読み込みました。" % all_games_data.size())


func log_message(message):
	print(message)
	log_history.append(str(message))
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()


func add_log(message: String) -> void:
	log_history.append(message)
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()


func get_log_history() -> String:
	return "\n".join(log_history)



# 値が「空っぽ」かどうかを判定するための、補助的な関数。
func is_value_empty(value) -> bool:
	match typeof(value):
		TYPE_STRING:
			return value.is_empty()
		TYPE_ARRAY:
			if value.is_empty():
				return true
			if value.size() == 1 and typeof(value[0]) == TYPE_DICTIONARY and value[0].is_empty():
				return true
			return false
		TYPE_DICTIONARY:
			return value.is_empty()
		_:
			return false
