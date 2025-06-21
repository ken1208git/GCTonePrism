extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

# この関数は、ボタンのpressedシグナルによって呼び出される
func _on_button_pressed():
    # 起動したいゲームの実行ファイルへの相対パス
    # この書き方で、ランチャーの場所を基準に正しくパスを解決してくれます
    var game_exe_path = "../Games/LaunchTest/LaunchTest.exe"

    # 外部プロセスを非同期で作成・実行する
    # 第三引数は、通常は不要なので省略します
    var pid = OS.create_process(game_exe_path, [])

    # 起動が成功したかどうかの簡単なチェック
    if pid != -1:
        print("ゲームを起動しました。プロセスID:", pid)
    else:
        print("エラー: ゲームの起動に失敗しました。パスを確認してください:", game_exe_path)
