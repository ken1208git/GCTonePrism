extends CanvasLayer

# このシーンの中にあるLabelノードへの参照
@onready var info_label = $InfoLabel # FPSなどを表示するラベル
@onready var log_label = $LogLabel   # ログを表示するRichTextLabel
@onready var version_label = $VersionLabel # バージョン情報を表示するラベル

# このノードが準備できたときに一度だけ呼ばれる
func _ready():
    # バージョンラベルのテキストを設定する
    # Global.APP_VERSIONはシングルトンで定義した定数
    version_label.text = "v" + Global.APP_VERSION

func _process(_delta):
    # Globalスクリプトのis_debug_mode変数を参照する
    if Global.is_debug_mode:
        # もしデバッグモードがオンなら、自身を表示する
        self.show()
        
        # FPSやメモリ情報を取得して、Labelのテキストを更新する
        var fps = Performance.get_monitor(Performance.TIME_FPS)
        var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
        info_label.text = "FPS: %d\nMemory: %.2f MB" % [fps, mem]
       # Globalのログ履歴を、改行(\n)で連結して一つの文字列にする
        log_label.text = "\n".join(Global.log_history)
        print("デバッグモニター更新中。ログの行数:", Global.log_history.size())
    else:
        # もしオフなら、自身を非表示にする
        self.hide()
