# GCTonePrismプロジェクト全体で共有される設定やデータを管理する、ただ一つの特別な場所。
# Godotの「自動ロード」機能に登録することで、どこからでも `Global` という名前でアクセスできる。
extends Node

# --- アプリケーション情報 ---

# ランチャーのバージョン番号。セマンティックバージョニング（Major.Minor.Patch-Identifier.Build）に従う。
# 新しい機能の開発や修正作業の区切りごとに、最後のdevナンバーを1つずつ上げていく。
const APP_VERSION = "0.1.0-dev.8"


# --- グローバル変数 ---

# 起動中のゲームのプロセスID。ゲームが起動していない場合は-1。
var current_game_pid: int = -1
# 現在UIで選択されているゲームのデータ（launcher_info.jsonの内容）。何も選択されていない場合は空のDictionary。
var current_selected_game_data: Dictionary = {}

# デバッグモードの状態を管理する。初期値はオフ(false)。
var is_debug_mode = false

# launcher_config.json から読み込んだ設定データを保持するための変数。
var launcher_config: Dictionary = {}
# スキャンして読み込んだ、すべてのゲームの情報を格納するための配列。
var all_games_data: Array[Dictionary] = []


# --- ログ機能 ---

# ログの履歴を保存する配列
var log_history = []
# 画面に表示するログの最大行数
const MAX_LOG_LINES = 20


# --- Godotの標準関数 ---

# このノードが起動したときに、一度だけ呼ばれる
func _ready():
	# 最初にランチャー設定ファイルを読み込む
	load_launcher_config()
	# 次に、読み込んだ設定を元に、すべてのゲーム情報をスキャンする
	load_all_games_info()
	
	# 最初のログメッセージを記録
	log_message("GCTonePrism is Ready.")
	# インプットマップに"toggle_debug"を登録するように促す
	if not InputMap.has_action("toggle_debug"):
		log_message("警告: アクション 'toggle_debug' がインプットマップにありません。")

# 毎フレーム呼ばれる、UIなどに邪魔されない入力処理。
# 使わない引数には、名前の先頭にアンダースコア `_` を付けるのがGodotのお作法。
func _unhandled_input(_event):
	# デバッグモードのトグルショートカット
	if Input.is_action_just_pressed("toggle_debug"):
		is_debug_mode = not is_debug_mode
		if is_debug_mode:
			log_message("Debug Mode: ON")
		else:
			log_message("Debug Mode: OFF")


# --- 自作のグローバル関数 ---

# ランチャー全体の設定ファイル (launcher_config.json) を読み込むための関数
func load_launcher_config():
	# 設定ファイルのパスを定義する。"res://" は、このプロジェクトのルートフォルダを指す。
	var config_path = "res://launcher_config.json"
	
	# ファイルが存在するかどうかを確認する
	if not FileAccess.file_exists(config_path):
		# もしファイルが見つからなければ、エラーログを残して処理を中断する
		log_message("エラー: " + config_path + " が見つかりません。")
		return

	# ファイルを開いて、その内容を文字列としてすべて読み込む
	var file = FileAccess.open(config_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# 読み込んだJSON文字列を、Godotが理解できるデータ形式（Dictionary）に変換する準備
	var json = JSON.new()
	# 実際に変換を実行し、もしエラーがあればその情報を取得する
	var error = json.parse(content)
	
	# 変換（パース）に失敗した場合
	if error != OK:
		log_message("エラー: launcher_config.json の解析に失敗しました。JSONの書式を確認してください。")
		return
	
	# 変換に成功したら、その結果をグローバル変数の launcher_config に保存する
	launcher_config = json.get_data()
	
	# ちゃんと読み込めたか、デバッグ用にコンソールに出力して確認する
	log_message("launcher_config.json の読み込みに成功しました。")
	log_message("  > ゲームディレクトリ: " + launcher_config.get("games_directory", "未設定"))
	log_message("  > ゲーム表示順: " + str(launcher_config.get("games_order", [])))


# すべてのゲーム情報をスキャンして読み込むための関数
func load_all_games_info():
	# まず、前提となるランチャー設定が読み込めているかを確認する
	if launcher_config.is_empty():
		log_message("エラー: ランチャー設定が読み込まれていないため、ゲーム情報をスキャンできません。")
		return

	# 設定から、ゲームが格納されているディレクトリのパスと、表示順の配列を取得する
	var games_dir_path: String = launcher_config.get("games_directory", "")
	var games_order: Array = launcher_config.get("games_order", [])

	# もし、どちらかの設定が空っぽだったら、処理を中断する
	if games_dir_path.is_empty() or games_order.is_empty():
		log_message("警告: games_directory または games_order が未設定です。")
		return
	
	log_message("ゲーム情報のスキャンを開始します...")

	# games_order 配列の中身を、一つずつ順番に処理していくループ
	for game_folder_name in games_order:
		# 個別のゲーム情報ファイルのフルパスを組み立てる
		var info_file_path = "%s/%s/launcher_info.json" % [games_dir_path, game_folder_name]
		
		# そのパスに、本当にファイルが存在するか確認する
		if not FileAccess.file_exists(info_file_path):
			log_message("警告: %s が見つかりません。スキップします。" % info_file_path)
			continue

		# ファイルを開き、中身を文字列として読み込む
		var file = FileAccess.open(info_file_path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		# JSON文字列を解析する
		var json = JSON.new()
		if json.parse(content) != OK:
			log_message("警告: %s の解析に失敗しました。スキップします。" % info_file_path)
			continue
		
		# 解析に成功したら、そのデータを一時的な変数に格納する
		var game_data: Dictionary = json.get_data()
		
		# データを all_games_data 配列の末尾に追加する
		all_games_data.append(game_data)

		# --- ここからデバッグログ出力処理 ---
		# .get()を使い、もしキーが存在しなくてもエラーにならないように安全に値を取得する
		var title = game_data.get("title", "名称未設定")
		var game_id = game_data.get("game_id", "ID不明")
		var executable = game_data.get("executable_path", "実行ファイル不明")
		
		# 取得した情報を元に、整形されたログメッセージを出力する
		log_message("  > [%s] の情報を読み込みました。" % title)
		log_message("    - ID: %s" % game_id)
		log_message("    - 実行ファイル: %s" % executable)
		# --- デバッグログ出力ここまで ---

	# すべての処理が終わった後、最終的に何件のゲーム情報を読み込めたか報告する
	log_message("ゲーム情報のスキャンが完了しました。合計 %d 件のゲームを読み込みました。" % all_games_data.size())


# カスタムログ関数
func log_message(message):
	# Godotの出力タブに表示
	print(message)
	# ログ履歴の配列に追加
	log_history.append(str(message))
	# 古いログを削除
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()

# 新しいログメッセージを追加する関数
func add_log(message: String) -> void:
	log_history.append(message)
	
	# もし、ログの行数が最大値を超えたら、一番古いログ（配列の先頭）を削除する
	if log_history.size() > MAX_LOG_LINES:
		log_history.pop_front()

# ログ履歴を文字列として取得する関数
func get_log_history() -> String:
	# 配列の要素を、改行文字(\n)で連結して、一つの文字列にして返す
	return "\n".join(log_history)
