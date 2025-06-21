extends Node

# デバッグモードの状態を保持するメンバー変数。運営時はfalse、デバッグ時はtrue。
var is_debug_mode = false

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

# Global.gd の _unhandled_input 関数の中身
func _unhandled_input(event):
    # "toggle_debug" アクションが実行された瞬間かどうかをチェック
    if event.is_action_just_pressed("toggle_debug"):
        is_debug_mode = not is_debug_mode
        print("デバッグモードが切り替わりました:", is_debug_mode)

    # 他のデバッグ用ショートカットの処理...
