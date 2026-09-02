## (#297 PR2 / #34) Autoload: ゲーム 1 回のプレイを 1 件の JSON として `responses/play_records/` に記録する。
##
## `GameSession` の signal を購読するだけの受動的な autoload で、こちらから何も駆動しない。ゲームの起動・
## 監視・終了はすべて GameSession が持ち、本 autoload は「起動したことと終わったこと」を記録するだけ。
##
## **なぜ signal 購読 2 点なのか (game_started で覚えて game_exited で書く)**:
## `GameSession._on_exited()` は `current_game = null` を **`game_exited` の emit より前**に実行するため、
## `game_exited` の購読者からは「どのゲームだったか」が読めない。よってゲームと開始時刻は起動時
## (`game_started`) に控えておき、終了時にそれを使って書き出す。
##
## **試遊テストの除外 (#311)**: サービスモードの試遊も本番と同じ `GameSession` 経由で起動するため、
## 素朴に記録すると開場前の全ゲーム試遊が本番プレイとしてカウントされ、母数の小さい直近 N 日ランキング
## (#36) が「試遊順」に汚染される。`GameSession.test_session` を見て弾く。終了時に `ServiceMode.is_open()`
## で判定する案は**使ってはいけない**: 試遊中はゲームが前面でランチャー無操作扱いになり、サービスモードの
## 60 秒オートクローズがプレイ中に発火しうるため、終了時点では既に閉じていて試遊が本番プレイに化ける。
##
## **接続は同期 (CONNECT_DEFERRED 不可)**: `test_session` は `game_exited` の emit **直後**にリセットされる。
## deferred で繋ぐとコールバックがリセット後に走り、常に false を読んで試遊を除外できなくなる
## (game_session.gd の `test_session` 宣言コメント参照)。
##
## **fail-soft**: 記録に失敗しても警告を残すだけでゲームプレイ・画面遷移は止めない (ResponsesWriter と同方針)。
##
## **log output 規約**: `LogBridge.info / warn` を使う (AGENTS.md「Cross-component Standards」)。
## 組み込み `Logger` クラスとの名前衝突で `Logger.info()` と直接は書けないが、**呼べないわけではない**
## (`LogBridge` が `/root/Logger` を解決する)。標準の出力関数はレベル指定ができない。
## autoload `Logger` は Godot 組み込みの `Logger` クラスと名前衝突し GDScript から呼べないため。

extends Node

const RECORD_TYPE: String = "play_record"

# 起動時に控えるセッション情報 (game_exited 時点では GameSession から読めなくなるため)。
var _game_no: int = -1
var _game_id: String = ""       # ログに出す用 (JSON は game_no のみ持つ / SPEC §7.5.3 の露出方針)
var _start_time: int = -1       # UNIX 秒
var _armed: bool = false        # game_started を受けて記録待ちの状態か


func _ready() -> void:
	# ダイアログ表示等で tree.paused になっても signal は届くが、GameSession と同じく明示しておく。
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 同期接続 (CONNECT_DEFERRED を付けないこと。上記クラスコメント参照)。
	GameSession.game_started.connect(_on_game_started)
	GameSession.game_exited.connect(_on_game_exited)


## ゲームのプロセスが起動した。どのゲームをいつ始めたかを控える。
func _on_game_started() -> void:
	_reset()

	var game: GameInfo = GameSession.current_game
	if game == null:
		# start_process() は current_game 非 null を保証してから emit するので通常は起きない。
		LogBridge.warn("[PlayRecordWriter] game_started 時に current_game が null のため記録しません")
		return

	_game_id = game.game_id
	_game_no = game.game_no
	_start_time = int(Time.get_unix_time_from_system())
	_armed = true


## ゲームのプロセスが終了した。控えておいた情報で 1 件書き出す。
func _on_game_exited() -> void:
	if not _armed:
		# game_started を受けていない終了 (起動失敗など)。記録すべきプレイが無い。
		return

	# 以降どの経路を通っても状態は畳む (次のセッションに前回の値を持ち越さない)。
	var game_no := _game_no
	var game_id := _game_id
	var start_time := _start_time
	_reset()

	# 試遊テストは本番プレイではないので記録しない (#311、クラスコメント参照)。
	if GameSession.test_session:
		LogBridge.info("[PlayRecordWriter] 試遊テストのため記録しません: %s" % _label(game_id, game_no))
		return

	# v24 未満の DB / 未採番のゲームは JSON の参照先が作れない。game_no を持たない記録を書くと
	# 集計側でどのゲームか解決できない孤児レコードになるだけなので、書かずに警告を残す。
	if game_no <= 0:
		LogBridge.warn("[PlayRecordWriter] game_no が未採番のため記録しません (Manager で DB を v24 以降に更新してください): %s"
			% _label(game_id, game_no))
		return

	var end_time := int(Time.get_unix_time_from_system())
	var ok := ResponsesWriter.write_record(ResponsesWriter.CATEGORY_PLAY_RECORDS, RECORD_TYPE, game_no, {
		"start_time": start_time,
		"end_time": end_time,
	})

	if ok:
		LogBridge.info("[PlayRecordWriter] プレイ記録を出力: %s 開始=%d 終了=%d (%d 秒)"
			% [_label(game_id, game_no), start_time, end_time, end_time - start_time])
	else:
		LogBridge.warn("[PlayRecordWriter] プレイ記録の出力に失敗しました: %s" % _label(game_id, game_no))


func _reset() -> void:
	_game_no = -1
	_game_id = ""
	_start_time = -1
	_armed = false


## ログ用のゲーム表記。JSON は game_no しか持たないため、障害調査でログだけから記録とゲームを
## 突き合わせられるよう `game_id (no.12)` の形で併記する (SPEC §7.5.3 の露出方針)。
func _label(game_id: String, game_no: int) -> String:
	return "%s (no.%d)" % [game_id, game_no]
