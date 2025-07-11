extends CanvasLayer

# このシーンの中にあるLabelノードへの参照
@onready var info_label = $InfoLabel # FPSなどを表示するラベル
@onready var log_label = $LogPanel/LogLabel   # ログを表示するRichTextLabel


func _process(_delta):
    # Globalスクリプトのis_debug_mode変数を参照する
    if Global.is_debug_mode:
        # もしデバッグモードがオンなら、自身を表示する
        self.show()
        
        # FPSやメモリ情報を取得して、Labelのテキストを更新する
        var fps = Performance.get_monitor(Performance.TIME_FPS)
        var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
        
        # バージョン情報とパフォーマンス情報を結合して表示
        info_label.text = "GCTonePrism v%s\nFPS: %d\nMemory: %.2f MB" % [Global.APP_VERSION, fps, mem]
        # Globalのログ履歴を、改行(\n)で連結して一つの文字列にする
        log_label.text = "\n".join(Global.log_history)
        
    else:
        # もしオフなら、自身を非表示にする
        self.hide()
