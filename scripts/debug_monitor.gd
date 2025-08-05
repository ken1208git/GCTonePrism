# デバッグ情報を画面にオーバーレイ表示するためのレイヤー。
# is_debug_mode の状態に応じて、表示されたり非表示になったりする。
extends CanvasLayer

# このシーンの中にある、情報を表示するための2つのラベルノードを、あらかじめ変数に入れておく。
# `@onready` は、このスクリプトが完全に準備OKになったタイミングで、右辺（= の右側）を実行させるおまじない。
# これにより、ノードが見つからないというエラーを確実に防ぐことができる。
@onready var info_label: Label = $InfoLabel # FPSやバージョン情報などを表示する、上のラベル。
@onready var log_label: RichTextLabel = $LogLabel   # ログ履歴を表示する、下のラベル。


# 毎フレーム（1秒間に何度も）呼び出されるGodotの関数。
# `_delta` は、前回この関数が呼ばれてから経過した時間（秒）。今回は使わないので `_` を付けている。
func _process(_delta: float) -> void:
    # プロジェクト全体で共有されている is_debug_mode の状態を確認する。
    if Global.is_debug_mode:
        # もしデバッグモードがオンなら、このレイヤー全体を表示する。
        self.show()
        
        # パフォーマンス情報から、現在のFPS（フレームレート）を取得する。
        var fps: int = Performance.get_monitor(Performance.TIME_FPS)
        # パフォーマンス情報から、現在使用している静的メモリ量（MB単位）を取得する。
        var mem: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
        
        # バージョン情報とパフォーマンス情報を、指定した書式で一つの文字列に組み立てる。
        info_label.text = "GCTonePrism v%s\nFPS: %d\nMemory: %.2f MB" % [Global.APP_VERSION, fps, mem]
        
        # ログ履歴の配列を、改行文字 `\n` で連結して、一つの長い文字列にする。
        log_label.text = "\n".join(Global.log_history)
        
    else:
        # もしデバッグモードがオフなら、このレイヤー全体を非表示にする。
        self.hide()
