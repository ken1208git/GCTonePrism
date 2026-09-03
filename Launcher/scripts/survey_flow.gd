## (#297 PR3 / #35) Autoload: アンケートを「出すかどうか」の判定と、表示〜保存〜後続処理の進行を集約する。
##
## アンケートの発火点は 4 箇所ある (ゲーム終了 / 中断メニューの退出 / カルーセルの退出 / ストアの退出)。
## 判定と進行を各所に散らすと、トグルの読み方や「スキップは保存しない」の扱いが少しずつズレていくので、
## **呼び出し側は「アンケートを挟んでからこれをして」と渡すだけ**にしてある。
##
## **トグルは表示直前に毎回読む**（キャッシュしない）。起動時に読んでキャッシュすると、Manager で
## OFF にしても各キオスクを再起動するまで反映されない (#263)。このトグルは「ピーク時に今すぐ止めたい」
## ために存在するので、再起動が要る時点で機能の意味がほぼ消える。DB は都度 open/close する
## (store_entry_router.gd 等と同じ、単発クエリの流儀)。
##
## **どの経路でも必ず画面を先へ進める**のが最重要の契約。アンケートは付加機能であって、
## 「出せなかった / 保存に失敗した」で来場者を画面に閉じ込めては絶対にいけない。DB が開けない・
## シーンが読めない・例外的な状態、いずれでも遷移は必ず走る。
##
## 進み先は 2 通り。通常は呼び出し側から渡された `on_done`。**無操作でタイムアウトした場合だけは
## `on_done` を使わず、直接タイトル画面 (スクリーンセーバー) へ戻す** — タイムアウト = その場に
## 人がいないということなので、呼び出し側が想定する「次の画面」(例: カルーセルへ戻る) へ進めても
## そこで通常のアイドルタイマーを最初から待ち直すことになり、無人の台が二重に待たされる。
##
## **log output 規約**: `LogBridge.info / warn` を使う (AGENTS.md「Cross-component Standards」)。
## 組み込み `Logger` クラスとの名前衝突で `Logger.info()` と直接は書けないが、**呼べないわけではない**
## (`LogBridge` が `/root/Logger` を解決する)。標準の出力関数はレベル指定ができない。

extends CanvasLayer

## Manager 設定のキー (Manager 側 `SettingsKeys.SurveyGameEndEnabled` / `SurveyLauncherEndEnabled` と対)。
const SETTING_GAME_END_ENABLED: String = "survey_game_end_enabled"
const SETTING_LAUNCHER_END_ENABLED: String = "survey_launcher_end_enabled"

## 設定が未登録のときの既定。**既定は ON** = 新規インストールで何もしなくても収集が始まる。
## 文化祭は 1 日勝負で「設定し忘れて 1 件も取れなかった」の方が損失が大きいため、
## 既定 OFF ではなく既定 ON にして、要らないときにスタッフが切る形にする。
const DEFAULT_ENABLED: bool = true

const SurveyDialogScene := preload("res://scenes/components/survey_dialog.tscn")

var _dialog: SurveyDialog = null
## 閉じるアニメーション中フラグ。**ポーズ維持の watchdog はこの間も効かせる** (レビュー Low-1)。
var _closing: bool = false
var _closing_since_msec: int = 0
## 閉じる処理の世代番号。**遅れて発火した消滅アニメのコールバックを無効化するために使う。**
## failsafe が先にタイトル画面へ逃がした後にコールバックが届くと、解放済みの `playing` ノードに
## 触る (`previously freed instance`) か、タイトル画面から勝手に選択画面へ戻る (レビュー L-1)。
var _close_generation: int = 0
## 閉じている最中のダイアログ実体。**failsafe から解放するために持つ** (レビュー M-4)。
## `_dialog` を null にした後は誰も参照を持たず、tween が完走しないと画面に残り続ける。
## ルートは全画面 Control で `mouse_filter` 既定 = STOP なので、スクリーンセーバーの上に
## 古いパネルが乗ったままマウスクリックを吸い続ける (キー/パッドは `_finished` で素通りする分、
## 「見た目は残っているのに操作はできる」という一番分かりにくい壊れ方になる)。
var _closing_dialog: SurveyDialog = null

## 閉じ始めてからこの時間を過ぎてもポーズが戻らなければ、強制的に手放してタイトル画面へ逃がす。
##
## ポーズの解除は `DialogAnimator.animate_out` の完了コールバック 1 本に依存している。tween の
## 対象が先に解放される等で発火しなければ、`_closing` を見る watchdog が善意でポーズを維持し続け、
## **全画面フリーズが永続する**。watchdog を置いたことで新しく生まれた失敗経路なので、
## 出口も一緒に用意しておく。消滅アニメは 0.2 秒なので 2 秒あれば通常は必ず終わっている。
const CLOSE_FAILSAFE_MSEC: int = 2000
## トグルの直近の読み取り結果と、その時刻 (ms)。**時間をまたぐキャッシュではない** — 下記参照。
var _toggles: Dictionary = {}
var _toggles_read_at_msec: int = 0

## 直近の読み取りを再利用してよい時間。
##
## 「表示直前に毎回読む」契約 (#263) は**時間をまたいでキャッシュしない**という意味であって、
## 同じ瞬間に 2 回開いてよいという意味ではない。ゲーム終了時にトグルが OFF だと、
## 個別アンケートの判定 → (出さずに) 退出処理 → 全体アンケートの判定、が数フレームの間に走り、
## SMB 上の SQLite を 2 回 open することになる。1 回の open は `journal_mode` / `busy_timeout` の
## PRAGMA と版数チェックを伴い、ロック競合時は busy_timeout の 10 秒まで待ちうる。
## ゲームが終わった直後は**一番待たせたくない瞬間**なので、ここだけは畳む。
##
## 1 秒は来場者が知覚できる遅延ではないので、「Manager で切り替えた瞬間に効く」は保たれる。
## 個別 → 全体を両方表示する経路では回答操作で必ず 1 秒以上あくため、2 回目は読み直しになる。
const TOGGLE_REUSE_WINDOW_MSEC: int = 1000

## トグルを読むときのロック待ち上限。既定の 10 秒ではなく短く張る (レビュー M-3)。
## 再利用窓は 2 回目以降しか畳めないので、**1 回目の競合**はこの値で頭を打たせる。
## 超えたら既定 (表示する) で続行する = 最悪でもこの時間しか止まらない。
const TOGGLE_READ_TIMEOUT_MSEC: int = 500


func _ready() -> void:
	# DialogManager (127) より下、通常 UI より上。アンケート表示中にエラーダイアログが出たら
	# そちらが前面に来るべきなので下に置く。
	layer = 126
	process_mode = Node.PROCESS_MODE_ALWAYS


## アンケート表示中はツリーの停止を毎フレーム主張し直す (レビュー H-1)。
##
## **なぜ要るか**: 停止を持っている主体が 2 つある。`DialogManager` は自分が出したダイアログの
## 消滅アニメーションが終わった時点で無条件に `paused = false` にするが、その頃には
## こちらのアンケートが既に出ている。実際に起きる経路はこう:
##
##     退出確認ダイアログ (DialogManager が停止 ON)
##       → 「退出する」→ アンケート表示 (こちらが停止 ON)
##       → 0.2 秒後、退出確認の消滅アニメ完了 → DialogManager が停止 OFF  ← ここで漏れる
##
## 停止が外れると背面のシーンが動き出す。背面の入力ハンドラは軒並み
## `if get_tree().paused: return` で守られているので、**停止さえ維持できていれば**
## フォーカスも入力もアンケートに集まる (= この 1 行がその前提を守っている)。
## 放置すると (1) アンケート操作で背面のカルーセルも一緒に動く、(2) 背面のアイドルタイマーが
## 進んでスクリーンセーバーへ遷移し、アンケートだけが画面に残る → `_dialog` が残ったままになり
## **以降そのキオスクではアンケートが二度と出ない**、という壊れ方をする。
##
## 本来は停止の所有者を 1 つに寄せるべきだが、`DialogManager` は全ダイアログが通る最頻経路で
## headless では見た目を検証できないため、文化祭直前に触るのは避けてここで封じ込める (#429)。
## 外れても次のフレームで戻るので自己修復する (漏れるのは最大 1 フレーム)。
func _process(_delta: float) -> void:
	# **閉じている最中も対象に含める** (`_closing`)。ポーズ解除は animate_out の完了コールバックに
	# しかないので、その 0.2 秒の間に `_dialog` を見るだけの watchdog では守れる相手がいなくなる。
	# tween が何らかの理由で完了しなければ「ポーズしたまま誰も戻さない」= 全画面フリーズになる
	# ため、その区間こそ守りたい (レビュー Low-1)。
	if (_dialog != null or _closing) and not get_tree().paused:
		get_tree().paused = true
	if _closing and Time.get_ticks_msec() - _closing_since_msec > CLOSE_FAILSAFE_MSEC:
		# 消滅アニメの完了が来ない = 想定外。ポーズを手放し、確実に人が触れる状態へ戻す。
		LogBridge.error("[SurveyFlow] アンケートの消滅処理が %d ms 以内に完了しませんでした。ポーズを解除してタイトル画面へ戻します"
			% CLOSE_FAILSAFE_MSEC)
		# 世代を進めて、遅れて届くコールバックを無効化する (二重に遷移させない)。
		_close_generation += 1
		# アニメが完走していない = queue_free も走っていないので、ここで実体を片付ける。
		# これをしないと画面にパネルが残り、全画面 Control がクリックを吸い続ける。
		if is_instance_valid(_closing_dialog):
			_closing_dialog.queue_free()
		_closing_dialog = null
		_release_pause()
		IdleManager.transition_to_screensaver(get_tree())


## ゲーム終了時のゲーム個別アンケート。game が null / 未採番なら出さずに on_done へ抜ける。
func maybe_show_game_end(game: GameInfo, on_done: Callable) -> void:
	if game == null or game.game_no <= 0:
		# 未採番 (DB v24 未満) は保存しても参照先を解決できない孤児レコードになるだけ。
		# プレイ記録側と同じ判断で、出さずに素通りする。
		_finish(on_done)
		return
	if not _is_enabled(SETTING_GAME_END_ENABLED):
		_finish(on_done)
		return
	# 見出しと対象名の両方で「このゲームの評価」だと分かるようにする。背面のサムネと合わせて三重。
	_show(game.game_no, SurveyWriter.TRIGGER_GAME_END, "このゲームは楽しかった？", "「%s」" % game.title, on_done)


## 退出時の全体アンケート。特定のゲームを指さないので game_no は 0。
func maybe_show_launcher_end(on_done: Callable) -> void:
	if not _is_enabled(SETTING_LAUNCHER_END_ENABLED):
		_finish(on_done)
		return
	# 対象を「展示全体」と明示する。直前までゲームを遊んでいた場合、見出しだけだと
	# 「さっきのゲームの話か？」と読めてしまうため、個別アンケートとの違いを文言で切る。
	_show(0, SurveyWriter.TRIGGER_LAUNCHER_END, "今日は楽しめましたか？", "展示全体についてお聞きします", on_done)


## トグルを 1 件読む。DB が開けない場合は既定値 (ON) を採る。
## 「設定が読めない」を理由にアンケートを止めると、SMB が一瞬不調だっただけで収集が静かに止まる。
## 逆に出しすぎても来場者はスキップできるので、読めないときは出す方向へ倒す。
func _is_enabled(key: String) -> bool:
	var now := Time.get_ticks_msec()
	if _toggles.has(key) and now - _toggles_read_at_msec <= TOGGLE_REUSE_WINDOW_MSEC:
		return _toggles[key]

	var db := DatabaseManager.new()
	# **待ちを有界にする** (レビュー M-3)。ここはゲームが終わった直後 = 画面が固まって見える瞬間に
	# 呼ばれるので、既定の 10 秒待ちを持ち込むと来場者を最悪 10 秒足止めする。設定 1 つのために
	# それは割に合わない。読めなければ既定 (表示する) に倒す — アンケートは出しすぎても
	# スキップできるが、来場者を待たせるのは取り返しがつかない。
	# 版数チェックも切る (設定を 1 つ読むだけで migration の案内は要らない。SMB では 1 クエリ = 1 往復)。
	if not db.open(TOGGLE_READ_TIMEOUT_MSEC, false):
		LogBridge.warn("[SurveyFlow] 設定を読めないため既定 (%s) で続行: key=%s"
			% ["表示する" if DEFAULT_ENABLED else "表示しない", key])
		return DEFAULT_ENABLED
	# 開いたついでに 2 キーとも読む。片方だけ読むと、直後に来るもう片方の判定でもう一度
	# 開くことになる (open の往復こそが重いのであって、SELECT 1 本の差は無視できる)。
	var repo := SettingsRepository.new(db)
	var read := {
		SETTING_GAME_END_ENABLED: repo.get_bool(SETTING_GAME_END_ENABLED, DEFAULT_ENABLED),
		SETTING_LAUNCHER_END_ENABLED: repo.get_bool(SETTING_LAUNCHER_END_ENABLED, DEFAULT_ENABLED),
	}
	db.close()
	_toggles = read
	_toggles_read_at_msec = now
	return read[key]


func _show(game_no: int, trigger: String, title: String, subject: String, on_done: Callable) -> void:
	if _dialog != null:
		# 既に表示中 (想定外の二重呼び出し)。後勝ちで画面を差し替えると回答が消えるので、
		# 新しい要求の方を捨てて後続処理だけ進める。
		LogBridge.warn("[SurveyFlow] アンケート表示中に別のアンケート要求が来たため無視します: trigger=%s" % trigger)
		_finish(on_done)
		return

	var dialog := SurveyDialogScene.instantiate() as SurveyDialog
	if dialog == null:
		LogBridge.warn("[SurveyFlow] アンケート画面を生成できませんでした: trigger=%s" % trigger)
		_finish(on_done)
		return

	_dialog = dialog
	add_child(dialog)
	dialog.setup(title, subject)
	# ダイアログ表示中は背後のシーンを止める (DialogManager と同じ流儀)。
	# 本ダイアログは process_mode=ALWAYS なのでポーズ中も動く。
	get_tree().paused = true
	# 登場アニメーションも既存ダイアログと同じものを使う (DialogManager / ErrorManager と共有)。
	# ここを自前で書くと「アンケートだけ出方が違う」という違和感になる。
	DialogAnimator.animate_in(dialog, self)

	dialog.submitted.connect(func(rating: int, comment):
		SurveyWriter.write(game_no, rating, comment, trigger)
		_close_and_continue(on_done)
	)
	dialog.skipped.connect(func():
		# スキップは保存しない (SPEC §機能10)。無回答と区別できず、★の平均も歪めるため。
		LogBridge.info("[SurveyFlow] アンケートをスキップ: trigger=%s" % trigger)
		_close_and_continue(on_done)
	)
	dialog.timed_out.connect(func():
		# 無操作 = 人がいない。on_done (カルーセルへ戻る等) では通常のアイドルタイマーを
		# 最初から待ち直すことになるので、通常の放置と同じくタイトル画面へ直接戻す。
		LogBridge.info("[SurveyFlow] 無操作でアンケートを閉じ、タイトル画面へ戻ります: trigger=%s" % trigger)
		_close_and_screensaver()
	)


func _close_and_continue(on_done: Callable) -> void:
	var dialog := _dialog
	_dialog = null
	_closing = true
	_closing_since_msec = Time.get_ticks_msec()
	_close_generation += 1
	_closing_dialog = dialog
	var gen := _close_generation
	if dialog == null:
		_release_pause()
		_finish(on_done)
		return
	# 消滅アニメーションも既存と共通。**アニメ完了を待ってから** ポーズ解除と後続処理を行う
	# (先に遷移すると、閉じるアニメの途中でシーンごと差し替わって画面が飛んで見える)。
	# animate_out が dialog を queue_free する。
	DialogAnimator.animate_out(dialog, self, func():
		if gen != _close_generation:
			return  # failsafe が先に処理済み。ここで進めると解放済みノードに触る
		_release_pause()
		_finish(on_done)
	)


## タイムアウト時の終わり方。`on_done` を捨ててタイトル画面へ戻す。
## 消滅アニメーションを待ってからポーズを解除して遷移する点は _close_and_continue と同じ
## (先に遷移すると閉じるアニメの途中でシーンごと差し替わり、画面が飛んで見える)。
func _close_and_screensaver() -> void:
	var dialog := _dialog
	_dialog = null
	_closing = true
	_closing_since_msec = Time.get_ticks_msec()
	_close_generation += 1
	_closing_dialog = dialog
	var gen := _close_generation
	if dialog == null:
		_release_pause()
		IdleManager.transition_to_screensaver(get_tree())
		return
	DialogAnimator.animate_out(dialog, self, func():
		if gen != _close_generation:
			return
		_release_pause()
		IdleManager.transition_to_screensaver(get_tree())
	)


## ポーズを手放す。**`_closing` を先に降ろしてから解除する** — 逆順だと watchdog が
## 同じフレームで押し直してしまい、永久に解除できない。
func _release_pause() -> void:
	_closing = false
	_closing_dialog = null
	get_tree().paused = false


## 後続処理を必ず呼ぶ。deferred にしているのは、signal コールバックの途中で
## シーン遷移が走ると、まだ生きているダイアログのノードが解放されうるため。
func _finish(on_done: Callable) -> void:
	if on_done.is_valid():
		on_done.call_deferred()
