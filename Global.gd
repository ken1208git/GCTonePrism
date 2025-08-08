# GCTonePrismプロジェクト全体で共有される設定やデータを管理するシングルトン
# Godotの「自動ロード」機能に登録することでどこからでも `Global` という名前でアクセスできる
extends Node

# --- アプリケーション情報 ---
# この定数はランチャーの現在のバージョンを示す
# 公式リリースする際には "-dev.X" の部分を削除する
const APP_VERSION = "0.1.0"


# --- グローバル変数 ---
# デバッグモニターの表示/非表示を切り替えるフラグ
var is_debug_mode = false
# launcher_config.jsonから読み込んだランチャー全体の設定を保持する
var launcher_config: Dictionary = {}
# スキャンして読み込んだ全てのゲーム情報を配列として保持する
var all_games_data: Array[Dictionary] = []


# --- ログ機能 ---
# ログの種類を定義して重要度を区別できるようにする
enum LogLevel { INFO, WARNING, ERROR, DEBUG }
# デバッグモニターに表示するためのログ履歴を保持する配列
var log_history: Array[String] = []
# デバッグモニターに表示するログの最大行数 これを超えると古いものから削除される
const MAX_LOG_LINES = 20


# --- Godotの標準関数 ---

# このノードがシーンツリーに追加された時に一度だけ呼び出される
# ランチャー起動時の初期化処理はここから開始する
func _ready() -> void:
	# 最初にランチャー全体の設定ファイルを読み込む
	load_launcher_config()
	# 次に設定ファイルの情報をもとに全てのゲーム情報をスキャンする
	load_all_games_info()
	# 準備が完了したことをログに出力する
	log_message(LogLevel.INFO, "GCTonePrism is Ready.")
	# 念のためデバッグモード切り替え用のキー設定が存在するか確認する
	if not InputMap.has_action("toggle_debug"):
		log_message(LogLevel.WARNING, "アクション 'toggle_debug' がインプットマップにありません。")


# --- 自作のグローバル関数 ---

# ランチャー全体の設定ファイル `launcher_config.json` を読み込む関数
func load_launcher_config() -> void:
	# 設定ファイルのパスを実行環境に応じて動的に決定する
	var config_path: String

	# もし現在の実行環境がGodotエディタなら
	if OS.has_feature("editor"):
		# "res://" はエディタが理解できるプロジェクトルートへの特別なパス
		config_path = "res://launcher_config.json"
	# もし現在の実行環境がエクスポートされた.exeなら
	else:
		# .exe自身の場所を基準に隣にあるはずの設定ファイルへの絶対パスを組み立てる
		var exe_dir = OS.get_executable_path().get_base_dir()
		config_path = exe_dir.path_join("launcher_config.json").simplify_path()

	# ファイルが実際にその場所に存在するかを確認する
	if not FileAccess.file_exists(config_path):
		# 存在しない場合はエラーログを出力して処理を中断する
		log_message(LogLevel.ERROR, config_path + " が見つかりません。")
		return

	# ファイルを読み込みモードで開く
	var file = FileAccess.open(config_path, FileAccess.READ)
	# ファイルの全内容を一つの文字列として読み込む
	var content = file.get_as_text()
	# ファイルを閉じる（リソースの解放）
	file.close()

	# JSONを解析するための新しいインスタンスを作成する
	var json = JSON.new()
	# 読み込んだ文字列をJSONとして解析する
	if json.parse(content) != OK:
		# 解析に失敗した場合はエラーログを出力して処理を中断する
		log_message(LogLevel.ERROR, "launcher_config.json の解析に失敗しました。")
		return

	# 解析したデータをグローバル変数の `launcher_config` に格納する
	launcher_config = json.get_data()
	log_message(LogLevel.INFO, "launcher_config.json の読み込みに成功しました。")
	# 読み込んだ内容の一部をデバッグ用にログ出力する
	log_message(LogLevel.DEBUG, "  > ゲームディレクトリ: " + launcher_config.get("games_directory", "未設定"))
	log_message(LogLevel.DEBUG, "  > ゲーム表示順: " + str(launcher_config.get("games_order", [])))


# `launcher_config.json` の情報をもとに全ゲームフォルダをスキャンし `launcher_info.json` を読み込む関数
func load_all_games_info() -> void:
	# 前提条件としてランチャー設定が読み込まれているかを確認する
	if launcher_config.is_empty():
		log_message(LogLevel.ERROR, "ランチャー設定が読み込まれていないため、ゲーム情報をスキャンできません。")
		return

	# ゲームが格納されている親フォルダへの相対パスを取得する
	var relative_games_dir: String = launcher_config.get("games_directory", "")
	# OSが理解できる絶対パスを格納するための変数
	var games_dir_path: String

	# 現在の実行環境がGodotエディタかエクスポートされた.exeかを判定する
	if OS.has_feature("editor"):
		# エディタ実行時はGodotの機能で絶対パスに変換する
		games_dir_path = ProjectSettings.globalize_path(relative_games_dir)
	else:
		# .exe実行時はパスの "res://" 接頭辞を手動で取り除く
		if relative_games_dir.begins_with("res://"):
			relative_games_dir = relative_games_dir.trim_prefix("res://")
		
		# .exeファイル自身の場所を基準にゲームフォルダへの絶対パスを組み立てる
		var exe_dir = OS.get_executable_path().get_base_dir()
		games_dir_path = exe_dir.path_join(relative_games_dir).simplify_path()

	# ランチャーに表示するゲームの順番リストを取得する
	var games_order: Array = launcher_config.get("games_order", [])

	# ゲームフォルダのパスや表示順リストが空っぽでないかを確認する
	if games_dir_path.is_empty() or games_order.is_empty():
		log_message(LogLevel.WARNING, "games_directory または games_order が未設定です。")
		return
	
	log_message(LogLevel.INFO, "ゲーム情報のスキャンを開始します... 基準パス: " + games_dir_path)

	# 表示順リストをもとに一つずつゲームフォルダを処理していく
	for game_folder_name in games_order:
		# 個別のゲームフォルダへの絶対パスを組み立てる
		var game_folder_path = games_dir_path.path_join(game_folder_name)
		# このゲームの情報を格納するための空の辞書を用意する
		var game_data: Dictionary = {}

		# そもそもそのゲームフォルダが物理的に存在するかを確認する
		if not DirAccess.dir_exists_absolute(game_folder_path):
			log_message(LogLevel.ERROR, "ゲームフォルダ '%s' が見つかりません！リストから除外します。" % game_folder_path)
			# 存在しない場合はこのゲームの処理をスキップし次のゲームに進む
			continue

		# ゲーム情報ファイルへの絶対パスを組み立てる
		var info_file_path = game_folder_path.path_join("launcher_info.json")
		# ゲーム情報ファイルが存在するかを確認する
		if not FileAccess.file_exists(info_file_path):
			log_message(LogLevel.WARNING, "%s が見つかりません。スキップします。" % info_file_path)
			continue
		
		# ファイルを開き内容を文字列として読み込み閉じる
		var file = FileAccess.open(info_file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		# JSONとして解析を試みる
		var json = JSON.new()
		if json.parse(content) != OK:
			log_message(LogLevel.WARNING, "%s の解析に失敗しました。スキップします。" % info_file_path)
			continue
		
		# 解析したデータを `game_data` 変数に格納する
		game_data = json.get_data()
		
		# 後で使う可能性のある追加情報をデータに付与しておく
		game_data["folder_name"] = game_folder_name
		game_data["game_directory_path"] = game_folder_path
		
		# 本来 `launcher_info.json` に含まれているべき必須キーのリスト
		var required_keys = [
			"game_id", "title", "description", "developers", "release_year",
			"genre", "min_players", "max_players", "difficulty", "play_time",
			"thumbnail_path", "background_path", "executable_path",
			"controller_support", "lan_multiplayer_support", "controls"
		]
		
		# 全ての必須キーが存在し中身が空でないかをチェックする
		for key in required_keys:
			if not game_data.has(key) or is_value_empty(game_data[key]):
				# もしゲームを起動するための実行ファイルパスが未入力なら重大な警告を出す
				if key == "executable_path":
					log_message(LogLevel.ERROR, "'%s' の '%s' が未入力です！このゲームは起動できません。" % [game_folder_name, key])
				# もしタイトルが未入力ならフォルダ名で代用することを知らせる
				elif key == "title":
					log_message(LogLevel.INFO, "'%s' の 'title' が未入力です。UIにはフォルダ名('%s')が表示されます。" % [game_folder_name, game_folder_name])
				# その他の項目は情報として未入力であることを知らせる
				else:
					log_message(LogLevel.INFO, "'%s' の '%s' が未入力です。" % [game_folder_name, key])

		# ゲームIDがフォルダ名と一致しているかを確認する（重要なルール）
		var game_id = game_data.get("game_id", "")
		if game_id != game_folder_name:
			log_message(LogLevel.ERROR, "'%s' の game_id ('%s') が未入力か、フォルダ名と一致しません！" % [game_folder_name, game_id])

		# 全てのチェックを終えたゲームデータをグローバルな配列に追加する
		all_games_data.append(game_data)
		log_message(LogLevel.INFO, "  > 「%s」の情報を読み込みました。" % game_data.get("title", game_folder_name))

	log_message(LogLevel.INFO, "ゲーム情報のスキャンが完了しました。合計 %d 件のゲームを読み込みました。" % all_games_data.size())


# プロジェクト全体で利用する新しい公式ログ関数
func log_message(level: LogLevel, message: String) -> void:
	# ログレベルに応じてコンソールに出力するメッセージの先頭に付ける文字列を決定する
	var prefix = ""
	match level:
		LogLevel.INFO:
			prefix = "[INFO] "
		LogLevel.WARNING:
			prefix = "[WARNING] "
		LogLevel.ERROR:
			prefix = "[ERROR] "
		LogLevel.DEBUG:
			# デバッグレベルのログはデバッグモードが有効な時だけ出力する
			if not is_debug_mode:
				return
			prefix = "[DEBUG] "

	# 接頭辞とメッセージ本体を結合して完全なログメッセージを作成する
	var full_message = prefix + message
	# Godotのコンソールに出力する
	print(full_message)

	# デバッグモニターに表示するための履歴にも追加する
	log_history.append(full_message)
	# 履歴の行数が最大値を超えていたら一番古いログを削除する
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()


# デバッグモニターが表示すべき全ログ履歴を一つの文字列として取得するための関数
func get_log_history_text() -> String:
	# 配列の各要素を改行コード `\n` で結合して一つの長い文字列を返す
	return "\n".join(log_history)


# 値が「空っぽ」かどうかを判定するための補助的な関数
# 文字列、配列、辞書など型によって「空」の定義が違うためここで一元管理する
func is_value_empty(value) -> bool:
	# `match`文を使って渡された`value`の型に応じて処理を分岐させる
	match typeof(value):
		# 文字列の場合
		TYPE_STRING:
			return value.is_empty()
		# 配列の場合
		TYPE_ARRAY:
			# 配列自体が空ならtrue
			if value.is_empty():
				return true
			# 配列に要素が一つだけでその要素が空の辞書の場合も実質的に「空」とみなす（developers項目などで発生）
			if value.size() == 1 and typeof(value[0]) == TYPE_DICTIONARY and value[0].is_empty():
				return true
			return false
		# 辞書の場合
		TYPE_DICTIONARY:
			return value.is_empty()
		# 上記以外の型（数値など）は「空」とはみなさない
		_:
			return false
