# このスクリプトは、メインのブラウズ画面（menu.tscn）全体の動作を管理します。
extends Control

# --- ノードへの参照（オンレディ変数） ---

# ゲームのサムネイルを並べるための、縦長の棚（VBoxContainer）。
# `@onready`は、この変数が、実際にノードを使う直前に、安全に準備されることを保証するおまじない。
# `%`から始まる書き方は「シーンユニーク名」といい、Godot 4で推奨されている、安全で確実なノードの指定方法。
@onready var game_list: VBoxContainer = %GameList

# --- Godotの標準関数 ---

# このノード（Menuシーン）が、最初に画面に表示されたときに、一度だけ呼ばれる関数。
func _ready() -> void:
	# ゲームリストを生成する関数を呼び出す。
	populate_game_list()


# この関数は、毎フレーム呼び出される。'delta'は、前回この関数が呼ばれてから経過した時間（秒）。
# 今回は使わないので、引数名の先頭にアンダースコア `_` を付けて、意図的に使っていないことを示している。
func _process(_delta: float) -> void:
	pass

# --- 自作の関数 ---

# ゲームリストに、サムネイルを動的に生成して並べるための関数。
func populate_game_list() -> void:
	# まず、リストにすでに何か項目があれば、すべて削除して、まっさらな状態にする。
	for child in game_list.get_children():
		child.queue_free()

	# ゲームサムネイルの「設計図」（シーンファイル）を、あらかじめ読み込んでおく。
	var thumbnail_scene: PackedScene = load("res://scenes/components/game_thumbnail.tscn")

	# Globalに保存されている、すべてのゲーム情報の配列をループ処理する。
	for game_data in Global.all_games_data:
		# 設計図から、新しいサムネイルの「実体」（インスタンス）を作成する。
		var thumbnail_instance: Panel = thumbnail_scene.instantiate()
		
		# 作成したサムネイルインスタンスに、対応するゲームの情報を渡してあげる。
		# これにより、thumbnail_instanceの中にあるスクリプト(game_thumbnail.gd)の、
		# set_game_data関数が呼び出される。
		thumbnail_instance.set_game_data(game_data)
		
		# 完成したサムネイルを、リスト（VBoxContainer）の子として追加する。
		game_list.add_child(thumbnail_instance)


# この関数は、プレイボタンのpressedシグナルによって呼び出される（予定）。
func _on_play_button_pressed() -> void:
	# 起動したいゲームの実行ファイルへの相対パス（これは、後で動的に取得するように変更する）
	var game_exe_path = "../Games/LaunchTest/LaunchTest.exe"

	# 外部プロセスを非同期で作成・実行する
	# 第二引数は、コマンドライン引数。通常は空の配列 `[]` で良い。
	var pid = OS.create_process(game_exe_path, [])

	# 起動が成功したかどうかの簡単なチェック
	if pid != -1:
		# 成功した場合、プロセスIDをログに出力する。
		print("ゲームを起動しました。プロセスID:", pid)
	else:
		# 失敗した場合、エラーメッセージと、どのパスで失敗したかをログに出力する。
		print("エラー: ゲームの起動に失敗しました。パスを確認してください:", game_exe_path)
