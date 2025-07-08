extends Node

# --- アプリケーション情報 ---

# ランチャーのバージョン番号。セマンティックバージョニング（Major.Minor.Patch-Identifier.Build）に従う。
const APP_VERSION = "0.1.0-dev.3"


# --- グローバル変数 ---

# 起動中のゲームのプロセスID。ゲームが起動していない場合は-1。
var current_game_pid: int = -1
# 現在UIで選択されているゲームのデータ（game.jsonの内容）。何も選択されていない場合は空のDictionary。
var current_selected_game_data: Dictionary = {}

# デバッグモードの状態を管理する。初期値はオフ(false)。
var is_debug_mode = false


# --- ログ機能 ---

# ログの履歴を保存する配列
var log_history = []
# 画面に表示するログの最大行数
const MAX_LOG_LINES = 20


# --- Godotの標準関数 ---

# このノードが起動したときに、一度だけ呼ばれる
func _ready():
    # 最初のログメッセージを記録
    log_message("GCTonePrism is Ready.")
    # インプットマップに"toggle_debug"を登録するように促す
    if not InputMap.has_action("toggle_debug"):
        log_message("警告: アクション 'toggle_debug' がインプットマップにありません。")

# 毎フレーム呼ばれる、UIなどに邪魔されない入力処理
func _unhandled_input(_event):
    # デバッグモードのトグルショートカット
    if Input.is_action_just_pressed("toggle_debug"):
        is_debug_mode = not is_debug_mode
        if is_debug_mode:
            log_message("Debug Mode: ON")
        else:
            log_message("Debug Mode: OFF")
    
    # 他のデバッグ用ショートカットは、この下に追加していく


# --- 自作のグローバル関数 ---

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
