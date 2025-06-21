extends CanvasLayer

# このシーンの中にあるLabelノードへの参照
@onready var info_label = $InfoLabel

func _process(delta):
    # Globalスクリプトのis_debug_mode変数を参照する
    if Global.is_debug_mode:
        # もしデバッグモードがオンなら、自身を表示する
        self.show()
        
        # FPSやメモリ情報を取得して、Labelのテキストを更新する
        var fps = Performance.get_monitor(Performance.TIME_FPS)
        var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
        info_label.text = "FPS: %d\nMemory: %.2f MB" % [fps, mem]
    else:
        # もしオフなら、自身を非表示にする
        self.hide()
