# GCTonePrismプロジェクト全体で共有される設定やデータを管理する、ただ一つの特別な場所。
# Godotの「自動ロード」機能に登録することで、どこからでも `Global` という名前でアクセスできる。
extends Node

# --- アプリケーション情報 ---
# この定数は、ランチャーの現在のバージョンを示す。
# dev版の開発が完了し、公式リリースする際には、"-dev.X"の部分を削除する。
const APP_VERSION = "0.1.0-dev.17"


# --- グローバル変数 ---
# 起動中の外部ゲームのプロセスIDを保持する。-1は何も起動していない状態を示す。
var current_game_pid: int = -1
# 現在メニュー画面で選択されているゲームの全データ（辞書型）を保持する。
var current_selected_game_data: Dictionary = {}
# デバッグモニターの表示/非表示を切り替えるためのフラグ。
var is_debug_mode = false
# launcher_config.jsonから読み込んだ、ランチャー全体の設定を保持する。
var launcher_config: Dictionary = {}
# スキャンして読み込んだ、すべてのゲームの情報を、配列として保持する。
var all_games_data: Array[Dictionary] = []


# --- ログ機能 ---
# ログの種類を定義する。これにより、ログの重要度を区別できる。
enum LogLevel { INFO, WARNING, ERROR, DEBUG }
# デバッグモニターに表示するための、ログの履歴を保持する配列。
var log_history: Array[String] = []
# デバッグモニターに表示するログの最大行数。これを超えると古いものから削除される。
const MAX_LOG_LINES = 20


# --- Godotの標準関数 ---

# このノード（と、それが属するシーン）がシーンツリーに追加された時に、一度だけ呼び出される。
# ランチャー起動時の初期化処理は、ここから開始する。
func _ready() -> void:
	# 最初に、ランチャー全体の設定ファイルを読み込む。
	load_launcher_config()
	# 次に、設定ファイルの情報をもとに、すべてのゲーム情報をスキャンする。
	load_all_games_info()
	# 準備が完了したことをログに出力する。
	log_message(LogLevel.INFO, "GCTonePrism is Ready.")
	# 念のため、デバッグモード切り替え用のキー設定が存在するか確認する。
	if not InputMap.has_action("toggle_debug"):
		log_message(LogLevel.WARNING, "アクション 'toggle_debug' がインプットマップにありません。")


# 毎フレーム、Godotが処理する入力イベントの中で、どのノードにも処理されなかったものが、最後にここに送られてくる。
# グローバルなキー入力（どこでも反応するキー）を処理するのに最適。
func _unhandled_input(_event: InputEvent) -> void:
	# "toggle_debug"アクション（例: Ctrl+Alt+F12）が、押された瞬間に反応する。
	if Input.is_action_just_pressed("toggle_debug"):
		# is_debug_modeフラグを、現在の状態の反対（trueならfalse、falseならtrue）にする。
		is_debug_mode = not is_debug_mode
		# 現在の状態をログに出力する。
		if is_debug_mode:
			log_message(LogLevel.INFO, "Debug Mode: ON")
		else:
			log_message(LogLevel.INFO, "Debug Mode: OFF")


# --- 自作のグローバル関数 ---

# ランチャー全体の設定ファイル `launcher_config.json` を読み込む関数。
func load_launcher_config() -> void:
	# 設定ファイルのパスを定義する。
	var config_path = "res://launcher_config.json"
	# ファイルが、実際に、その場所に、存在するかを、確認する。
	if not FileAccess.file_exists(config_path):
		# 存在しない場合は、エラーログを出力して、処理を中断する。
		log_message(LogLevel.ERROR, config_path + " が見つかりません。")
		return

	# ファイルを読み込みモードで開く。
	var file = FileAccess.open(config_path, FileAccess.READ)
	# ファイルの全内容を、一つの文字列として、読み込む。
	var content = file.get_as_text()
	# ファイルを閉じる（リソースの解放）。
	file.close()

	# JSONを解析するための、新しいインスタンスを作成する。
	var json = JSON.new()
	# 読み込んだ文字列を、JSONとして、解析する。
	if json.parse(content) != OK:
		# 解析に失敗した場合は、エラーログを出力して、処理を中断する。
		log_message(LogLevel.ERROR, "launcher_config.json の解析に失敗しました。")
		return

	# 解析したデータを、グローバル変数の `launcher_config` に格納する。
	launcher_config = json.get_data()
	log_message(LogLevel.INFO, "launcher_config.json の読み込みに成功しました。")
	# 読み込んだ内容の一部を、デバッグ用に、ログ出力する。
	log_message(LogLevel.DEBUG, "  > ゲームディレクトリ: " + launcher_config.get("games_directory", "未設定"))
	log_message(LogLevel.DEBUG, "  > ゲーム表示順: " + str(launcher_config.get("games_order", [])))


# `launcher_config.json` の情報をもとに、すべてのゲームフォルダをスキャンし、
# `launcher_info.json` を読み込む関数。
func load_all_games_info() -> void:
	# 前提条件として、ランチャー設定が読み込まれているかを確認する。
	if launcher_config.is_empty():
		log_message(LogLevel.ERROR, "ランチャー設定が読み込まれていないため、ゲーム情報をスキャンできません。")
		return

	# ゲームが格納されている、親フォルダへの、相対パスを取得する。
	var relative_games_dir: String = launcher_config.get("games_directory", "")
	# OSが理解できる、絶対パスを、格納するための、変数。
	var games_dir_path: String

	# 現在の実行環境が、Godotエディタか、エクスポートされた.exeかを、判定する。
	if OS.has_feature("editor"):
		# エディタ実行時は、Godotの機能で、絶対パスに変換する。
		games_dir_path = ProjectSettings.globalize_path(relative_games_dir)
	else:
		# .exe実行時は、パスの "res://" 接頭辞を、手動で、取り除く。
		if relative_games_dir.begins_with("res://"):
			relative_games_dir = relative_games_dir.trim_prefix("res://")
		
		# .exeファイル自身の場所を基準に、ゲームフォルダへの、絶対パスを、組み立てる。
		var exe_dir = OS.get_executable_path().get_base_dir()
		games_dir_path = exe_dir.path_join(relative_games_dir).simplify_path()

	# ランチャーに表示するゲームの順番リストを取得する。
	var games_order: Array = launcher_config.get("games_order", [])

	# ゲームフォルダのパスや、表示順リストが、空っぽでないかを確認する。
	if games_dir_path.is_empty() or games_order.is_empty():
		log_message(LogLevel.WARNING, "games_directory または games_order が未設定です。")
		return
	
	log_message(LogLevel.INFO, "ゲーム情報のスキャンを開始します... 基準パス: " + games_dir_path)

	# 表示順リストをもとに、一つずつ、ゲームフォルダを、処理していく。
	for game_folder_name in games_order:
		# 個別のゲームフォルダへの、絶対パスを、組み立てる。
		var game_folder_path = games_dir_path.path_join(game_folder_name)
		# このゲームの情報を格納するための、空の辞書を用意する。
		var game_data: Dictionary = {}

		# そもそも、そのゲームフォルダが、物理的に、存在するかを確認する。
		if not DirAccess.dir_exists_absolute(game_folder_path):
			log_message(LogLevel.ERROR, "ゲームフォルダ '%s' が見つかりません！リストから除外します。" % game_folder_path)
			# 存在しない場合は、このゲームの処理をスキップし、次のゲームに進む。
			continue

		# ゲーム情報ファイルへの、絶対パスを、組み立てる。
		var info_file_path = game_folder_path.path_join("launcher_info.json")
		# ゲーム情報ファイルが、存在するかを確認する。
		if not FileAccess.file_exists(info_file_path):
			log_message(LogLevel.WARNING, "%s が見つかりません。スキップします。" % info_file_path)
			continue
		
		# ファイルを開き、内容を文字列として読み込み、閉じる。
		var file = FileAccess.open(info_file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		# JSONとして、解析を試みる。
		var json = JSON.new()
		if json.parse(content) != OK:
			log_message(LogLevel.WARNING, "%s の解析に失敗しました。スキップします。" % info_file_path)
			continue
		
		# 解析したデータを、`game_data`変数に格納する。
		game_data = json.get_data()
		
		# 後で使う可能性のある、追加情報を、データに、付与しておく。
		game_data["folder_name"] = game_folder_name
		game_data["game_directory_path"] = game_folder_path
		
		# 本来、`launcher_info.json` に、含まれているべき、必須キーのリスト。
		var required_keys = [
			"game_id", "title", "description", "developers", "release_year",
			"genre", "min_players", "max_players", "difficulty", "play_time",
			"thumbnail_path", "background_path", "executable_path",
			"controller_support", "lan_multiplayer_support", "controls"
		]
		
		# すべての必須キーが、存在し、かつ、中身が空でないかを、チェックする。
		for key in required_keys:
			if not game_data.has(key) or is_value_empty(game_data[key]):
				# もし、ゲームを起動するための実行ファイルパスが未入力なら、重大な警告を出す。
				if key == "executable_path":
					log_message(LogLevel.ERROR, "'%s' の '%s' が未入力です！このゲームは起動できません。" % [game_folder_name, key])
				# もし、タイトルが未入力なら、フォルダ名で代用することを、知らせる。
				elif key == "title":
					log_message(LogLevel.INFO, "'%s' の 'title' が未入力です。UIにはフォルダ名('%s')が表示されます。" % [game_folder_name, game_folder_name])
				# その他の項目は、情報として、未入力であることを、知らせる。
				else:
					log_message(LogLevel.INFO, "'%s' の '%s' が未入力です。" % [game_folder_name, key])

		# ゲームIDが、フォルダ名と、一致しているかを確認する（重要なルール）。
		var game_id = game_data.get("game_id", "")
		if game_id != game_folder_name:
			log_message(LogLevel.ERROR, "'%s' の game_id ('%s') が未入力か、フォルダ名と一致しません！" % [game_folder_name, game_id])

		# すべてのチェックを終えたゲームデータを、グローバルな配列に追加する。
		all_games_data.append(game_data)
		log_message(LogLevel.INFO, "  > 「%s」の情報を読み込みました。" % game_data.get("title", game_folder_name))

	log_message(LogLevel.INFO, "ゲーム情報のスキャンが完了しました。合計 %d 件のゲームを読み込みました。" % all_games_data.size())


# プロジェクト全体から利用する、新しい公式ログ関数。
func log_message(level: LogLevel, message: String) -> void:
	# ログレベルに応じて、コンソールに出力するメッセージの先頭に付ける文字列を決定する。
	var prefix = ""
	match level:
		LogLevel.INFO:
			prefix = "[INFO] "
		LogLevel.WARNING:
			prefix = "[WARNING] "
		LogLevel.ERROR:
			prefix = "[ERROR] "
		LogLevel.DEBUG:
			# デバッグレベルのログは、デバッグモードが有効な時だけ出力する。
			if not is_debug_mode:
				return
			prefix = "[DEBUG] "

	# 接頭辞とメッセージ本体を、結合して、完全なログメッセージを作成する。
	var full_message = prefix + message
	# Godotのコンソールに、出力する。
	print(full_message)

	# デバッグモニターに表示するための、履歴にも、追加する。
	log_history.append(full_message)
	# 履歴の行数が、最大値を超えていたら、一番古いログを、削除する。
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()


# デバッグモニターが、表示するべき、全ログ履歴を、一つの文字列として、取得するための関数。
func get_log_history_text() -> String:
	# 配列の各要素を、改行コード `\n` で、結合して、一つの、長い文字列を、返す。
	return "\n".join(log_history)


# 値が「空っぽ」かどうかを判定するための、補助的な関数。
# 文字列、配列、辞書など、型によって「空」の定義が違うため、ここで一元管理する。
func is_value_empty(value) -> bool:
	# `match`文を使って、渡された`value`の型に応じて、処理を分岐させる。
	match typeof(value):
		# 文字列の場合
		TYPE_STRING:
			return value.is_empty()
		# 配列の場合
		TYPE_ARRAY:
			# 配列自体が空なら、true。
			if value.is_empty():
				return true
			# 配列に要素が一つだけで、かつ、その要素が空の辞書の場合も、実質的に「空」とみなす（developers項目などで発生）。
			if value.size() == 1 and typeof(value[0]) == TYPE_DICTIONARY and value[0].is_empty():
				return true
			return false
		# 辞書の場合
		TYPE_DICTIONARY:
			return value.is_empty()
		# 上記以外の型（数値など）は、「空」とはみなさない。
		_:
			return false
