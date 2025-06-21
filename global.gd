extends Node

# デバッグモードの状態を保持するメンバー変数。運営時はfalse、デバッグ時はtrue。
var is_debug_mode = false
var log_history = []
# 画面に表示するログの最大行数
const MAX_LOG_LINES = 20

# 新しいカスタムログ関数
func log_massage(message):
    # 1. 今まで通り、Godotの出力タブにメッセージを表示
    print(message)
    
    # 2. ログ履歴の配列の末尾に、新しいメッセージを追加
    log_history.append(str(message)) # str()で、どんなデータも文字列に変換
    
    # 3. ログが最大行数を超えたら、一番古いもの（先頭）を削除
    if log_history.size() > MAX_LOG_LINES:
        log_history.pop_front()
        
# Global.gd の _unhandled_input 関数の中身
func _unhandled_input(_event):
    # インプットマップで設定した"toggle_debug"アクションが押された瞬間かをチェック
    if Input.is_action_just_pressed("toggle_debug"):
        
        # is_debug_mode変数のtrue/falseを反転させる
        is_debug_mode = not is_debug_mode
        
        # 現在の状態を出力ウィンドウに表示して、切り替わったことを確認
        if is_debug_mode:
            print("デバッグモード: オン")
        else:
            print("デバッグモード: オフ")

    # 他のデバッグ用ショートカットの処理...
