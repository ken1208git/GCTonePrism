extends CanvasLayer

@onready var log_display = $LogDisplay

func _ready():
    # get_node()を使って、Globalノードを直接、フルパスで取得する
    var global_node = get_node("/root/Global")
    
    # 取得できたか、念のため確認
    if global_node:
        # 取得したノードのメソッドを呼び出す
        Global.log_message("TestLog: _ready() called. Accessing Global via get_node().")
    else:
        # このエラーが出たら、オートロードの登録自体が失敗している
        print("FATAL ERROR: Could not find node at path /root/Global")

func _process(_delta):
    # get_node()を使って、Globalノードを再度取得する
    var global_node = get_node("/root/Global")
    
    # Globalノードが確かに存在する場合のみ、処理を続ける
    if global_node:
        # 取得したノードの変数を参照して、表示/非表示を決定
        if global_node.is_debug_mode:
            self.show()
            # ログ履歴も、取得したノードから持ってくる
            log_display.text = "\n".join(global_node.log_history)
        else:
            self.hide()
    else:
        # Globalが見つからない場合は、モニター自体を非表示にする
        self.hide()
