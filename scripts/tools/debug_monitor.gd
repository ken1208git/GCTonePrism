# デバッグ情報を画面にオーバーレイ表示するためのレイヤー
# 自身の表示/非表示の状態を自分で管理する
extends CanvasLayer

# --- ノードへの参照（オンレディ変数） ---
# このシーンの中にある情報を表示するための2つのラベルノードをあらかじめ変数に入れておく
# `@onready` はスクリプト実行前に右辺のノード検索を確実に行うためのおまじない
@onready var info_label: Label = $InfoLabel # FPSやバージョン情報を表示する上のラベル
@onready var log_label: RichTextLabel = $LogLabel   # ログ履歴を表示する下のラベル


# --- Godotの標準関数 ---

# このノードがシーンツリーに追加された時に一度だけ呼び出される
# 初期状態を設定するために使う
func _ready() -> void:
	# 起動直後はデバッグモードがオフなので非表示にしておく
	self.hide()


# 毎フレーム（1秒間に何度も）呼び出されるGodotの関数
# `_delta` は前回この関数が呼ばれてから経過した時間（秒） 今回は使わないので `_` を付けている
func _process(_delta: float) -> void:
	# "toggle_debug"アクション（例: Ctrl+Alt+F12）が押された瞬間をここで検知する
	# _input()ではなく_process()でInputシングルトンを使うのが最も安全で確実な方法
	if Input.is_action_just_pressed("toggle_debug"):
		# このレイヤーの表示/非表示を現在の状態の反対に切り替える
		self.visible = not self.visible

	# このデバッグモニターが表示されている時だけ中の処理を行う（パフォーマンス改善）
	if not self.visible:
		return

	# パフォーマンス情報から現在のFPS（フレームレート）を取得し整数に変換する
	var fps: int = int(Performance.get_monitor(Performance.TIME_FPS))
	# パフォーマンス情報から現在使用している静的メモリ量（MB単位）を取得する
	var mem: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	
	# バージョン情報とパフォーマンス情報を指定した書式で一つの文字列に組み立てる
	info_label.text = "GCTonePrism v%s\nFPS: %d\nMemory: %.2f MB" % [Global.APP_VERSION, fps, mem]
	
	# Globalから整形済みのログ履歴テキストを取得してラベルに設定する
	log_label.text = Global.get_log_history_text()
