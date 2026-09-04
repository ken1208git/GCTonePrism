
extends CanvasLayer
## サービスモードの全画面メニュー画面。スタッフが現地で動作確認・診断・終了操作を行うための画面。
## 黒背景 + 白文字の素朴な画面。左に項目の一覧、右に選んだ項目の詳細を同時に表示する。
##
## 操作 (キーボード / マウス / コントローラー共通。ui_* は Godot 既定で 矢印/Enter/Esc = D-pad/A/B):
##  - 左リスト: ↑↓ で項目選択 (右の詳細がライブ更新) / → or A/Enter で詳細ペインへ / B/Esc でサービスモード終了
##  - 右詳細: ↑↓ で操作項目移動・A/Enter で実行 / ← or B/Esc で左リストへ戻る
##
## 表示制御・トリガ・60 秒自動復帰は autoload ServiceMode。UI は項目数が多く動的なため code-built。

# ランチャー他画面と同じ日本語フォント (Noto Sans JP)。指定しないと Godot 既定フォントになり
# サービスモードだけ見た目が浮くため、UI 全体に既定フォントとして適用する。
const FONT_REGULAR := preload("res://fonts/NotoSansJP-Regular.ttf")
const FONT_BOLD := preload("res://fonts/NotoSansJP-Bold.ttf")

# 業務用ターミナル調の白黒 (青みを抜いたニュートラル)。背景は真っ黒、階層は 背景<パネル<ボタン。
const C_BG := Color(0.0, 0.0, 0.0, 1.0)       # 真っ黒 (完全不透明。裏のシーンは pause + 不可視で凍結)
const C_PANEL := Color(0.10, 0.10, 0.10, 1.0) # 詳細パネル (黒からわずかに浮かせる)
const C_TEXT := Color(0.85, 0.85, 0.85)       # 本文
const C_MUTED := Color(0.55, 0.55, 0.55)      # 補足
const C_ACCENT := Color(1.0, 1.0, 1.0)        # 詳細見出し・フォーカス枠 (白)
const C_TITLE := Color(1.0, 0.85, 0.20)       # 最上部の「サービスモード」見出し (黄)
const C_DANGER := Color(1.0, 0.45, 0.40)      # 危険/NG (赤)
const C_OK := Color(0.45, 0.90, 0.55)         # OK (緑)

# サービスモードに並ぶ項目の一覧。各 id は _build_detail の match で詳細ビルダーに対応する。
const ITEMS := [
	{"id": "input",        "label": "1. 入力チェック"},
	{"id": "audio",        "label": "2. 音声チェック"},
	{"id": "screen_test",  "label": "3. 画面表示テスト"},
	{"id": "games_test",   "label": "4. ゲーム動作テスト"},
	{"id": "network",      "label": "5. ネットワーク接続テスト"},
	{"id": "records_check","label": "6. 記録・アンケートの動作確認"},
	{"id": "db_check",     "label": "7. データベース整合性チェック"},
	{"id": "log_view",     "label": "8. 簡易ログ確認"},
	{"id": "system_info",  "label": "9. システム情報"},
	{"id": "debug_overlay","label": "10. デバッグオーバーレイ切替"},
	{"id": "fullscreen",   "label": "11. フルスクリーン切替"},
	{"id": "monitor",      "label": "12. ランチャー表示モニタ選択"},
	{"id": "reload",       "label": "13. ランチャーの再読み込み"},
	{"id": "restart",      "label": "14. ランチャーの再起動"},
	{"id": "exit",         "label": "15. ランチャー終了"},
]

# 画面表示テストで順番に表示するパターン。先頭から 1 つずつ全画面表示し、キー送りで次へ進む。
const SCREEN_SEQ := [
	{"mode": "grid",       "color": Color.BLACK,          "label": "グリッド + セーフエリア"},
	{"mode": "colorbar",   "color": Color.BLACK,          "label": "カラーバー"},
	{"mode": "resolution", "color": Color.BLACK,          "label": "解像度 + グレースケール"},
	{"mode": "solid",      "color": Color.WHITE,          "label": "白"},
	{"mode": "solid",    "color": Color.BLACK,            "label": "黒"},
	{"mode": "solid",    "color": Color.RED,              "label": "赤"},
	{"mode": "solid",    "color": Color.GREEN,            "label": "緑"},
	{"mode": "solid",    "color": Color.BLUE,             "label": "青"},
	{"mode": "solid",    "color": Color(0.5, 0.5, 0.5),   "label": "グレー50%"},
]

## (#297) 記録に必要な最小 DB 版数 = `games.game_no` が入った v24。
##
## 判定は **「以上」** で行う。これは「現在の版数」ではなく **「game_no が導入された版数」** なので、
## `DatabaseManager.CURRENT_DB_VERSION` が将来 25, 26… と上がっても**この値は追随させない**
## (列は残り続けるため、v25 の DB でも記録は問題なく取れる)。CURRENT_DB_VERSION と同一視して
## しまうと、Manager が先行更新しただけの正常な環境で「記録できません」と誤報する。
const MIN_DB_VERSION_FOR_RECORDS: int = 24

# ネットワーク接続テストの段階 (上から順に確認。最初に × が出た所が原因)。
const NW_STAGES := [
	["ip",           "1. ローカルIP取得"],
	["gateway",      "2. ゲートウェイ疎通"],
	["dns",          "3. DNS解決"],
	["internet",     "4. インターネット接続"],
	["inet_speed",   "5. インターネット速度"],
	["server",       "6. 共有サーバー接続"],
	["server_speed", "7. 共有サーバー読み込み速度"],
	["monitor",      "8. Monitor接続"],
]

var _root: Control = null
var _theme: Theme = null             # Noto Sans JP を既定フォントにする UI 全体のテーマ
var _focus_sb: StyleBoxFlat = null   # フォーカス枠 (ボタン内側に描く=ScrollContainer のクリップで見切れない)
var _focus_off_sb: StyleBox = null   # マウス操作時の透明 focus (枠を出さない)
var _btn_sb: StyleBoxFlat = null     # 詳細ペインのボタン通常スタイル (薄く色を付ける)
var _btn_hover_sb: StyleBoxFlat = null  # 詳細ペインのボタンホバー/押下スタイル (少し明るく)
var _using_mouse: bool = false       # マウス操作中はフォーカス枠を出さない (他画面と同じ分離)
var _detail_title: Label = null
var _detail_content: VBoxContainer = null
var _footer: Label = null
# サービスモード専用の汎用モーダル (DialogManager は layer 200 より下で隠れるため自前)。
var _modal_layer: Control = null     # 暗幕+中央パネル (非表示が既定)
var _modal_msg: Label = null         # モーダル本文
var _modal_btnbox: HBoxContainer = null  # モーダルのボタン列 (呼び出しごとに作り直す)
var _modal_open: bool = false        # モーダル表示中か (この間は背後の入力を止める)
var _modal_cb: Callable = Callable() # 選択時のコールバック (選んだ index を渡す)
var _menu_buttons: Array[Button] = []
var _selected_index: int = -1        # 左リストで選択中の項目
var _in_detail: bool = false         # フォーカスが右詳細ペインにあるか
var _test_canvas: Control = null     # 画面表示テストの全画面描画ノード (単色 / グリッド / カラーバー / グラデ)
var _test_mode: String = "solid"     # 現在のテスト描画モード ("solid"/"grid"/"colorbar"/"resolution")
var _test_color: Color = Color.BLACK # solid モードの表示色
var _test_active: bool = false
var _seq_index: int = 0              # 画面表示テストで今表示しているパターンの位置
var _games_test_mode: String = ""    # 「ゲーム動作テスト」の選択中モード ("" / exists / auto / play)
var _games_test_desc: Label = null   # 確認方法の選択画面で、フォーカス/ホバー中の選択肢の詳細説明を出すラベル
var _games_focus_idx: int = -1       # キーボード/パッドでフォーカス中の選択肢 (-1=なし)
var _games_hover_idx: int = -1       # マウスでホバー中の選択肢 (-1=なし)
# 起動テスト (4②): チェックを付けたゲームを 1 本ずつ 起動→窓検出→終了 で OK/NG 判定する。
const LT_WINDOW_TIMEOUT_MS := 30000  # 窓が出るのを待つ上限 (これを超えたら NG。ロード長めのゲームも考慮)
const LT_NOWINDOW_OK_MS := 4000      # Companion 無し時、これだけ生きていれば OK 扱い
const LT_KILL_TIMEOUT_MS := 6000     # taskkill 後にプロセス消失を待つ上限
var _lt_games: Array = []            # 登録ゲーム (GameInfo) 一覧
var _lt_checks: Array[CheckBox] = [] # 各ゲームのチェックボックス
var _lt_status: Array[Label] = []    # 各ゲームの結果ラベル
var _lt_start_btn: Button = null     # 「テスト開始」ボタン
var _lt_stop_btn: Button = null      # 「テストを中止」ボタン
var _lt_scroll: ScrollContainer = null  # ゲーム一覧のスクロール枠 (テスト中の行を自動で見せる)
var _lt_running: bool = false        # テスト実行中
var _lt_queue: Array[int] = []       # 残りテスト対象の index キュー
var _lt_cur: int = -1                # 現在テスト中のゲーム index
var _lt_phase: String = ""           # "" / "wait" / "kill"
var _lt_pid: int = -1                # 現在テスト中の cmd プロセス PID
var _lt_phase_ms: int = 0            # 現フェーズ開始時刻
# 試遊テスト (4③): チェックしたゲームを 1 本ずつ自動で起動→試遊→復帰し、戻るたびに 〇× を記録して次へ。
var _pt_games: Array = []            # 登録ゲーム (GameInfo) 一覧
var _pt_checks: Array[CheckBox] = [] # 各ゲームのチェックボックス
var _pt_status: Array[Label] = []    # 各ゲームの結果ラベル
var _pt_start_btn: Button = null     # 「試遊開始」ボタン
var _pt_stop_btn: Button = null      # 「中止」ボタン
var _pt_scroll: ScrollContainer = null   # 一覧スクロール枠 (試遊中の行を自動で見せる)
var _pt_running: bool = false        # 試遊シーケンス実行中
var _pt_queue: Array[int] = []       # 残り試遊対象の index キュー
var _pt_cur: int = -1                # 試遊中 / 〇×入力待ちのゲーム index
var _pt_await: bool = false          # ゲームから戻って 〇× 入力待ちか
# (#311) 試遊は本番と同じ GameSession 経由で起動する (HOME/Guide で本物の中断オーバーレイを確認するため)。
# プロセスの所有・監視・kill は GameSession 側。ここではゲーム終了 (game_exited) を購読して 〇× へ進める。
var _pt_exit_connected: bool = false # GameSession.game_exited 購読中か
# システム情報のリアルタイム更新 (開いている間、変動する行だけ書き換える)。
var _sysinfo_list: ItemList = null   # 表示中のシステム情報リスト (非表示時は null)
var _sysinfo_accum: float = 0.0      # 更新間隔の累積
var _sys_phys_bytes: int = 0         # 物理メモリ総量 (空き表示の再構成用)
var _sys_idx_memfree: int = -1       # 物理メモリ行の index (-1=なし)
var _sys_idx_memapp: int = -1        # アプリ使用メモリ行
var _sys_idx_fps: int = -1           # 現在FPS行
var _sys_idx_datetime: int = -1      # 現在日時行
var _sys_idx_uptime: int = -1        # 稼働時間行
var _audio_player: AudioStreamPlayer = null  # 音声チェックのテスト音再生用
var _test_tone: AudioStreamWAV = null        # 生成したテスト音 (キャッシュ)
# 入力チェック (1): 一覧表示と、ボタンで入る「確認モード」(入力を捕捉して表示・ナビと競合させない)。
var _ic_connected_label: Label = null  # 接続中コントローラー一覧
var _ic_last_label: Label = null       # 最後に来た入力 (確認モード時のみ)
var _ic_capture: bool = false          # 確認モード中か (入力を捕捉してナビに渡さない)
var _ic_guide_count: int = 0           # 確認モード中の Guide ボタン押下回数 (規定回数で戻る)
var _ic_esc_count: int = 0             # 確認モード中の Esc キー押下回数 (規定回数で戻る)
const IC_EXIT_PRESSES := 3             # Esc / Guide を何回押したら確認モードを抜けるか
# ネットワーク接続テスト (5): 別スレッドで段階チェック (ping/TCP はブロッキングなので画面を固めないため)。
var _nw_thread: Thread = null
var _nw_running: bool = false
var _nw_cancel: bool = false           # close / 画面離脱時に true。ワーカーが段階境界で見て早期終了する
var _nw_speed_pending: int = 0         # 待っている速度結果の数 (internet + server で 2)。0 になったら run 解放
var _nw_speed_timeout_left: float = 0.0  # 速度結果待ちの残り秒 (Companion 異常死等で結果が来ない保険)
var _nw_run_id: int = 0                # 速度計測の run 識別子。古い run の遅延結果を弾くため毎 run で増やす
const NW_SPEED_TIMEOUT_SEC := 30.0     # 速度結果が揃わない場合に強制解放するまでの秒数 (内訳: ネット5s + 探索5s + 読込10s + 余裕)
var _nw_run_btn: Button = null
var _nw_rows: Dictionary = {}          # stage_id -> 結果 Label
var _nw_db_host: String = ""           # 共有サーバーのホスト (DBパスから抽出、メインスレッドで取得)
var _nw_db_path: String = ""           # DB ファイルのフルパス (共有サーバーのホスト抽出用)
var _nw_speed_file: String = ""        # 読み込み速度の計測対象 (games フォルダ。Companion が配下の最大ファイルを測る。無ければ DB)


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	# コントローラーの抜き差しで入力チェックの接続一覧を更新する (表示中のみ反映)。
	Input.joy_connection_changed.connect(_on_joy_conn_changed)
	# Companion からの速度計測結果 (ネットワークテストの速度段に反映)。
	var agent := get_node_or_null("/root/LauncherAgent")
	if agent and agent.has_signal("speedtest_result"):
		agent.speedtest_result.connect(_nw_on_speed)


func _notification(what: int) -> void:
	# ネットワークテストのワーカースレッドが走ったまま破棄されないよう join する。
	if what == NOTIFICATION_PREDELETE and _nw_thread and _nw_thread.is_started():
		_nw_thread.wait_to_finish()


func open_overlay() -> void:
	visible = true
	_in_detail = false
	_pt_await = false
	_modal_open = false
	if _modal_layer:
		_modal_layer.visible = false
	_ic_capture = false  # 入力確認モードは持ち越さない
	_set_menu_focusable(true)
	_using_mouse = false  # Ctrl+Alt+F12 (キーボード) で開く → フォーカス枠あり
	_apply_focus_style()
	# 先頭項目を選択 + 詳細表示 + 左リストにフォーカス。
	_selected_index = -1
	if not _menu_buttons.is_empty():
		_menu_buttons[0].grab_focus()  # focus_entered で _select(0) が走る
	_update_footer()


func close_overlay() -> void:
	_hide_test()
	_lt_stop()  # 起動テスト中に閉じてもゲームを置き去りにしない
	_pt_stop()  # 試遊中に閉じてもゲームを置き去りにしない
	_nw_cancel = true  # ネットワークテスト実行中なら次の段階境界で早期終了させる
	visible = false


## ランチャー終了前のクリーンアップ。起動テスト/試遊テストで起動したゲームを終了させる。
## 起動テスト(②)は _spawn_game_process (GameSession 非経由) なので _lt_stop が taskkill で終了、
## 試遊テスト(③)は GameSession 経由 (#311) なので _pt_stop が GameSession.quit() で終了させる。
## どちらも Alt+F4 等の quit 経路で孤児プロセスを残さないため、AppManager の quit 直前と項目14 終了から呼ぶ。
func cleanup_for_quit() -> void:
	_lt_stop()
	_pt_stop()


func _process(delta: float) -> void:
	if not visible:
		return
	# 起動テスト実行中は毎フレーム進行させる (起動→窓検出→終了)。
	if _lt_running:
		_lt_tick()
	# (#311) 試遊テストは GameSession 経由で起動するので、ゲーム終了監視は GameSession.game_exited
	# (→ _pt_on_return) が担う。毎フレームのプロセス polling は不要。
	# システム情報を開いている間、変動する行 (FPS / メモリ / 日時 / 稼働時間) を定期更新する。
	if _sysinfo_list != null and is_instance_valid(_sysinfo_list):
		_sysinfo_accum += delta
		if _sysinfo_accum >= 0.5:
			_sysinfo_accum = 0.0
			_refresh_sysinfo()
	# 速度結果待ちのタイムアウト (Companion 異常死等で結果が永久に来ない場合の保険)。
	if _nw_speed_pending > 0:
		_nw_speed_timeout_left -= delta
		if _nw_speed_timeout_left <= 0.0:
			for sid in ["inet_speed", "server_speed"]:
				if _nw_rows.has(sid) and is_instance_valid(_nw_rows[sid]) and _nw_rows[sid].text == "測定中…":
					_nw_set(sid, "測定不可 (応答なし)", C_DANGER)
			_nw_release_run()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# 何か操作があった = アクティブ。本 overlay が入力を消費 (set_input_as_handled) すると ServiceMode 側の
	# _input がスキップされ無操作タイマーが進んでしまうため、消費する前にここで明示的にリセットする。
	# (意図的入力かの判定は notify_activity 側で行う = スティックドリフト等では復帰タイマーを止めない)
	ServiceMode.notify_activity(event)
	# 入力確認モード中は全入力を捕捉して表示し、メニューのナビには渡さない。Esc / Guide×3 で戻る。
	if _ic_capture:
		_ic_handle_capture(event)
		return
	# 画面表示テスト中: Esc / B で中断してメニューへ。← / Backspace で前のパターンへ戻る。
	# それ以外のキー / クリック / パッドボタンで次へ送る (最後まで行くと自動でメニューに戻る)。
	if _test_active:
		if event.is_action_pressed("ui_cancel"):
			_hide_test()
			get_viewport().set_input_as_handled()
			return
		var back: bool = event.is_action_pressed("ui_left") \
			or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSPACE)
		if back:
			_retreat_screen_seq()
			get_viewport().set_input_as_handled()
			return
		var advance: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventJoypadButton and event.pressed)
		if advance:
			_advance_screen_seq()
			get_viewport().set_input_as_handled()
		return
	# 入力デバイス分離 (ランチャー他画面と同じ): マウス=カーソル表示+フォーカス枠なし /
	# キー・パッド=カーソル非表示+フォーカス枠あり。
	if event is InputEventMouseMotion and event.relative.length() > 1.0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_using_mouse(true)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_using_mouse(true)
	elif event is InputEventKey and event.pressed and not event.echo:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_set_using_mouse(false)
	elif event is InputEventJoypadButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_set_using_mouse(false)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_set_using_mouse(false)
	# モーダル表示中は背後のナビ/終了を止め、モーダルのボタンだけに操作を委ねる
	# (←→/↑↓ でボタン間移動、Enter で決定。Esc は誤操作防止のため無視)。
	if _modal_open:
		# (#311) キー/パッド操作なのに GUI フォーカスがモーダル外・消失していたら先頭ボタンへ復帰させる。
		# ゲーム終了直後 (試遊の 〇× モーダル) は窓フォーカスの遷移で focus owner が失われることがあり、
		# そのままだと矢印/決定が無反応 = マウスでしか操作できなくなるため。復帰に使った押下はここで
		# 消費する (フォーカスが見えない状態の Enter がいきなり先頭ボタンを決定してしまう誤操作の防止)。
		var is_keypad: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventJoypadButton and event.pressed) \
			or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5)
		if is_keypad and _modal_btnbox and _modal_btnbox.get_child_count() > 0:
			var owner := get_viewport().gui_get_focus_owner()
			if owner == null or not _modal_btnbox.is_ancestor_of(owner):
				(_modal_btnbox.get_child(0) as Control).grab_focus()
				get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	# B / Esc: 詳細内にサブ画面 (ゲーム動作テストのモード表示等) があればまずそこから戻る。
	# 無ければ、詳細ペインなら左リストへ戻る / 左リストならサービスモード終了。
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _in_detail:
			if not _try_detail_subback():
				_exit_detail()
		else:
			ServiceMode.close()
		return
	# → で左リスト→詳細へ、← で詳細→左リスト (またはサブ画面から戻る)。消費して Godot 自動 h-ナビを抑止。
	if not _in_detail and event.is_action_pressed("ui_right"):
		_enter_detail()
		get_viewport().set_input_as_handled()
	elif _in_detail and event.is_action_pressed("ui_left"):
		if not _try_detail_subback():
			_exit_detail()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# フォーカス枠: ボタン矩形の内側にアクセント色のボーダーを描く。デフォルトの focus 枠は矩形の外側に
	# はみ出して描かれ、全幅ボタン + ScrollContainer のクリップで左右が見切れるため自前に差し替える。
	_focus_sb = StyleBoxFlat.new()
	_focus_sb.draw_center = false
	_focus_sb.bg_color = Color(0, 0, 0, 0)
	_focus_sb.set_border_width_all(2)
	_focus_sb.border_color = C_ACCENT
	_focus_sb.set_corner_radius_all(4)
	_focus_off_sb = StyleBoxEmpty.new()  # マウス時: 何も描かない focus 枠

	# 詳細ペインのボタンは黒からグレーで浮かせて「押せる項目」だと分かるようにする (ニュートラルな灰)。
	_btn_sb = StyleBoxFlat.new()
	_btn_sb.bg_color = Color(0.12, 0.12, 0.12)
	_btn_sb.border_color = Color(0.30, 0.30, 0.30)
	_btn_sb.set_border_width_all(1)
	_btn_sb.set_corner_radius_all(6)
	_btn_sb.content_margin_left = 14
	_btn_sb.content_margin_right = 14
	_btn_sb.content_margin_top = 6
	_btn_sb.content_margin_bottom = 6
	_btn_hover_sb = StyleBoxFlat.new()
	_btn_hover_sb.bg_color = Color(0.22, 0.22, 0.22)
	_btn_hover_sb.border_color = Color(0.55, 0.55, 0.55)
	_btn_hover_sb.set_border_width_all(1)
	_btn_hover_sb.set_corner_radius_all(6)
	_btn_hover_sb.content_margin_left = 14
	_btn_hover_sb.content_margin_right = 14
	_btn_hover_sb.content_margin_top = 6
	_btn_hover_sb.content_margin_bottom = 6

	# UI 全体の既定フォントを Noto Sans JP に。_root に theme を付けると子の Label/Button 等へ伝播する。
	_theme = Theme.new()
	_theme.default_font = FONT_REGULAR

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = _theme
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	_root.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var header := Label.new()
	header.text = "サービスモード  —  Launcher %s" % Version.get_version_string()
	header.add_theme_color_override("font_color", C_TITLE)
	header.add_theme_font_override("font", FONT_BOLD)
	header.add_theme_font_size_override("font_size", 26)
	col.add_child(header)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	col.add_child(body)

	# 左: 項目リスト (scrollable・follow_focus で見切れ防止)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.follow_focus = true
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.custom_minimum_size = Vector2(420, 0)
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(menu_scroll)

	var menu_vbox := VBoxContainer.new()
	menu_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_vbox.add_theme_constant_override("separation", 4)
	menu_scroll.add_child(menu_vbox)

	_menu_buttons.clear()
	for i in range(ITEMS.size()):
		var btn := Button.new()
		btn.text = " " + ITEMS[i]["label"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 18)
		btn.focus_entered.connect(_select.bind(i))   # ↑↓ で移動すると詳細がライブ更新
		btn.pressed.connect(_on_menu_pressed.bind(i)) # A/Enter/クリックで詳細ペインへ
		menu_vbox.add_child(btn)
		_apply_focus_style_to(btn)  # ツリー追加後に呼ぶ (get_theme_stylebox がテーマを正しく解決するため)
		_menu_buttons.append(btn)

	# 主リストは端で上下ラップさせる (一番上で↑→一番下 / 一番下で↓→一番上)。固定メニューで
	# 端まで素早く回り込めるように。端点のみ neighbor を指定し、中間は自動 neighbor のまま残す。
	if _menu_buttons.size() >= 2:
		_menu_buttons[0].focus_neighbor_top = _menu_buttons[-1].get_path()
		_menu_buttons[-1].focus_neighbor_bottom = _menu_buttons[0].get_path()

	# 右: 詳細パネル
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = C_PANEL
	panel_sb.set_corner_radius_all(8)
	panel_sb.content_margin_left = 24
	panel_sb.content_margin_right = 24
	panel_sb.content_margin_top = 20
	panel_sb.content_margin_bottom = 20
	detail_panel.add_theme_stylebox_override("panel", panel_sb)
	body.add_child(detail_panel)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail_box)

	_detail_title = Label.new()
	_detail_title.add_theme_color_override("font_color", C_ACCENT)
	_detail_title.add_theme_font_override("font", FONT_BOLD)
	_detail_title.add_theme_font_size_override("font_size", 22)
	detail_box.add_child(_detail_title)
	detail_box.add_child(HSeparator.new())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.follow_focus = true
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(detail_scroll)

	_detail_content = VBoxContainer.new()
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_content.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(_detail_content)

	_footer = Label.new()
	_footer.add_theme_color_override("font_color", C_MUTED)
	_footer.add_theme_font_size_override("font_size", 14)
	col.add_child(_footer)

	_build_modal()


## サービスモード内に出す中央モーダル (暗幕+パネル+ボタン)。_root の最後の子なので最前面に描かれ、
## _root の theme (Noto) を継承する。
func _build_modal() -> void:
	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.visible = false
	_root.add_child(_modal_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # 背後へのクリックを遮断
	_modal_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(center)

	var mpanel := PanelContainer.new()
	mpanel.custom_minimum_size = Vector2(560, 0)
	var msb := StyleBoxFlat.new()
	msb.bg_color = C_PANEL
	msb.set_corner_radius_all(8)
	msb.set_border_width_all(1)
	msb.border_color = Color(0.45, 0.45, 0.45)
	msb.content_margin_left = 28
	msb.content_margin_right = 28
	msb.content_margin_top = 24
	msb.content_margin_bottom = 24
	mpanel.add_theme_stylebox_override("panel", msb)
	center.add_child(mpanel)

	var mvb := VBoxContainer.new()
	mvb.add_theme_constant_override("separation", 18)
	mpanel.add_child(mvb)
	_modal_msg = Label.new()
	_modal_msg.add_theme_color_override("font_color", C_TEXT)
	_modal_msg.add_theme_font_size_override("font_size", 20)
	_modal_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mvb.add_child(_modal_msg)
	_modal_btnbox = HBoxContainer.new()
	_modal_btnbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_modal_btnbox.add_theme_constant_override("separation", 14)
	mvb.add_child(_modal_btnbox)


## モーダルを表示する。options=ボタン文言、colors=各ボタンの文字色 (省略可)、cb=選択時に index を渡す。
func _show_modal(message: String, options: PackedStringArray, cb: Callable, colors: Array = []) -> void:
	for c in _modal_btnbox.get_children():
		_modal_btnbox.remove_child(c)
		c.queue_free()
	_modal_msg.text = message
	_modal_cb = cb
	var first: Button = null
	for i in range(options.size()):
		var b := Button.new()
		b.text = options[i]
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(150, 44)
		b.add_theme_stylebox_override("normal", _btn_sb)
		b.add_theme_stylebox_override("pressed", _btn_hover_sb)
		b.pressed.connect(_modal_pick.bind(i))
		_apply_focus_style_to(b)
		if i < colors.size():
			_set_button_font_color(b, colors[i])
		_modal_btnbox.add_child(b)
		if first == null:
			first = b
	# フォーカスがモーダル外 (背後のボタン等) へ逃げないよう、ボタンの neighbor を相互に固定する。
	var btns := _modal_btnbox.get_children()
	for i in range(btns.size()):
		var b: Control = btns[i]
		var prev: Control = btns[i - 1] if i > 0 else b
		var nxt: Control = btns[i + 1] if i < btns.size() - 1 else b
		b.focus_neighbor_left = prev.get_path()
		b.focus_previous = prev.get_path()
		b.focus_neighbor_right = nxt.get_path()
		b.focus_next = nxt.get_path()
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = b.get_path()
	_modal_open = true
	_modal_layer.visible = true
	if first:
		first.grab_focus()


func _modal_pick(index: int) -> void:
	var cb := _modal_cb
	_modal_open = false
	_modal_cb = Callable()
	if _modal_layer:
		_modal_layer.visible = false
	if cb.is_valid():
		cb.call(index)
	# (#311) モーダルを閉じた後のフォーカス復帰。フォーカスを持ったボタンごとモーダルが hidden になると
	# focus owner が消え、以後のキー/パッド操作が無反応になる (マウスでしか復帰できない)。cb が次の
	# モーダルを開いた場合 (試遊 〇× の 2 問目等) はそちらが focus を取っているので触らない。
	if not _modal_open and visible and get_viewport().gui_get_focus_owner() == null:
		if _in_detail:
			_refocus_detail()
		elif _selected_index >= 0 and _selected_index < _menu_buttons.size():
			_menu_buttons[_selected_index].grab_focus()


# ---------------- 選択 / ペイン移動 ----------------

## 左リストの選択変更 (focus_entered)。選択が変わった時だけ右詳細を作り直す (戻り時の無駄な再構築防止)。
func _select(index: int) -> void:
	if not visible or index == _selected_index:
		return
	_selected_index = index
	_games_test_mode = ""  # 項目を切り替えたらゲーム動作テストのモード選択もリセット
	_detail_title.text = ITEMS[index]["label"]
	_build_detail(ITEMS[index]["id"])


## 左リストで A/Enter/クリック → 詳細ペインへ移動。
func _on_menu_pressed(index: int) -> void:
	_select(index)
	_enter_detail()


## 右詳細ペインへフォーカスを移す。操作可能 control が無ければ移動しない (= false)。
func _enter_detail() -> bool:
	var first := _first_focusable(_detail_content)
	if first == null:
		return false
	_in_detail = true
	first.grab_focus()
	_update_footer()
	return true


## 詳細ペイン内のサブ画面から一段戻れるなら戻る (詳細ペインからは出ない)。戻したら true。
## 現状「ゲーム動作テスト」のモード表示中のみ: 確認方法の選択へ戻る。
func _try_detail_subback() -> bool:
	if _selected_index >= 0 and _selected_index < ITEMS.size() \
			and ITEMS[_selected_index]["id"] == "games_test" and _games_test_mode != "":
		_games_test_mode = ""
		_build_detail("games_test")
		_refocus_detail()
		return true
	return false


## 左リストへフォーカスを戻す。
func _exit_detail() -> void:
	_in_detail = false
	if _selected_index >= 0 and _selected_index < _menu_buttons.size():
		_menu_buttons[_selected_index].grab_focus()
	_update_footer()


func _update_footer() -> void:
	if _in_detail:
		_footer.text = "↑↓ で操作   A/Enter で実行   ← / B / Esc で項目一覧へ戻る"
	else:
		_footer.text = "↑↓ で項目選択   → / A/Enter で詳細へ   B / Esc で閉じる   (60 秒無操作で自動復帰)"


# ---------------- 詳細ビルド ----------------

func _build_detail(id: String) -> void:
	_clear_content()
	match id:
		"input": _build_input_check()
		"network": _build_network()
		"system_info": _build_system_info()
		"games_test": _build_games_test()
		"records_check": _build_records_check()
		"db_check": _build_db_check()
		"log_view": _build_log_view()
		"audio": _build_audio_check()
		"screen_test": _build_screen_test()
		"debug_overlay": _build_debug_overlay()
		"fullscreen": _build_fullscreen()
		"monitor": _build_monitor()
		"reload": _build_reload()
		"restart": _build_restart()
		"exit": _build_exit()
		_: _build_stub()
	_constrain_detail_focus()


## 入力チェック: 接続中コントローラー一覧を表示。ボタンで「確認モード」に入ると入力を捕捉して表示する。
## 「パッドが効かない」を 一覧に出ない(OS未認識) / 出るが反応しない(マッピング等) / 正常 で切り分ける。
func _build_input_check() -> void:
	_add_text("接続中のコントローラー", C_ACCENT)
	_ic_connected_label = Label.new()
	_ic_connected_label.add_theme_color_override("font_color", C_TEXT)
	_ic_connected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.add_child(_ic_connected_label)
	_ic_refresh_connected()
	_detail_content.add_child(HSeparator.new())

	if not _ic_capture:
		# 一覧表示中はメニュー操作と競合させないため、入力捕捉は確認モードに入ってから。
		_ic_last_label = null
		_add_text("「入力確認を開始」を押すと、押したボタン/キーが画面に表示される確認モードに入ります。", C_MUTED)
		_add_button("入力確認を開始", _ic_enter_capture)
		_add_text("コントローラーが一覧に出ない場合は OS が認識していません（ケーブル/レシーバー/電池/ドライバを確認）。", C_MUTED)
		return

	# 確認モード: 押した入力をライブ表示。ナビは止まる。
	_add_text("【入力確認モード】 ボタン/キー/スティックを操作してください。", C_ACCENT)
	_ic_last_label = Label.new()
	_ic_last_label.add_theme_color_override("font_color", C_OK)
	_ic_last_label.add_theme_font_size_override("font_size", 26)
	_ic_last_label.text = "（操作待ち…）"
	_detail_content.add_child(_ic_last_label)
	_detail_content.add_child(HSeparator.new())
	_add_text("戻る: Esc キーまたはコントローラーの Guide ボタンを %d 回押す。" % IC_EXIT_PRESSES, C_MUTED)


## 接続中コントローラー一覧を更新する。
func _ic_refresh_connected() -> void:
	if not is_instance_valid(_ic_connected_label):
		return
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		_ic_connected_label.text = "接続なし"
		_ic_connected_label.add_theme_color_override("font_color", C_MUTED)
		return
	var lines: Array[String] = []
	for p in pads:
		lines.append("・パッド %d: %s" % [p, _ic_joy_display_name(p)])
	_ic_connected_label.text = "\n".join(lines)
	_ic_connected_label.add_theme_color_override("font_color", C_TEXT)


## 接続中パッドの表示名。get_joy_name は "XInput Controller" のような総称しか返さないことが多いため、
## get_joy_info の raw_name (実際の製品名。例: "Xbox Series X Controller") を優先し、無ければ総称にフォールバック。
func _ic_joy_display_name(p: int) -> String:
	var info := Input.get_joy_info(p)
	var raw := String(info.get("raw_name", "")).strip_edges()
	if raw != "":
		return raw
	var n := Input.get_joy_name(p).strip_edges()
	return n if n != "" else "(不明なコントローラー)"


## コントローラーの抜き差し → 入力チェック表示中なら一覧を更新。
func _on_joy_conn_changed(_device: int, _connected: bool) -> void:
	if is_instance_valid(_ic_connected_label):
		_ic_refresh_connected()


## 確認モードに入る (入力捕捉開始)。メニューボタンのフォーカスを無効化してナビを止める
## (入力を「消費」して止めると親 ServiceMode のアイドル計測/Ctrl+Alt+F12 が効かなくなるため)。
func _ic_enter_capture() -> void:
	_ic_capture = true
	_ic_guide_count = 0
	_ic_esc_count = 0
	_set_menu_focusable(false)
	_build_detail("input")


## 確認モードを抜ける。メニューのフォーカスを戻す。
func _ic_exit_capture() -> void:
	_ic_capture = false
	_ic_guide_count = 0
	_ic_esc_count = 0
	_set_menu_focusable(true)
	_build_detail("input")
	_refocus_detail()


## 左メニューのボタンのフォーカス可否を一括設定する (確認モード中はナビさせない)。
func _set_menu_focusable(on: bool) -> void:
	for b in _menu_buttons:
		if is_instance_valid(b):
			b.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE


## 確認モード中の入力処理。Esc / Guide×3 は消費して抜ける。テスト入力は消費しない
## (ServiceMode のアイドル計測/F12 を生かすため。ナビはメニューのフォーカス無効化で止めている)。
func _ic_handle_capture(event: InputEvent) -> void:
	# Esc キーを規定回数押したら戻る (B ボタンはテスト対象なので使わない。Esc も誤操作防止で複数回)。
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_ic_esc_count += 1
		get_viewport().set_input_as_handled()
		if _ic_esc_count >= IC_EXIT_PRESSES:
			_ic_exit_capture()
		elif is_instance_valid(_ic_last_label):
			_ic_last_label.text = "Esc (あと %d 回で戻る)" % (IC_EXIT_PRESSES - _ic_esc_count)
		return
	# Guide ボタンを規定回数押したら戻る。
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_GUIDE:
		_ic_guide_count += 1
		get_viewport().set_input_as_handled()
		if _ic_guide_count >= IC_EXIT_PRESSES:
			_ic_exit_capture()
		elif is_instance_valid(_ic_last_label):
			_ic_last_label.text = "Guide (あと %d 回で戻る)" % (IC_EXIT_PRESSES - _ic_guide_count)
		return
	# テスト入力は表示するだけ (消費しない)。
	var desc := _describe_input(event)
	if desc != "" and is_instance_valid(_ic_last_label):
		_ic_last_label.text = desc


## 入力イベントを分かりやすい文字列にする。対象外は "" を返す。
func _describe_input(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed and not event.echo:
		return "キーボード: %s" % _key_label(event)
	if event is InputEventJoypadButton and event.pressed:
		return "パッド %d: %s" % [event.device, _joy_button_name(event.button_index)]
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		return "パッド %d: %s" % [event.device, _joy_axis_name(event.axis, event.axis_value)]
	if event is InputEventMouseButton and event.pressed:
		return "マウス: ボタン %d" % event.button_index
	return ""


## キーイベントの表示名。論理キー名 (配列依存) → 物理キー名 → 生コードの順にフォールバックする。
## 無変換/変換/半角全角/かな 等の日本語配列キーは Godot に論理名が無く KEY_UNKNOWN になるため、
## 物理キー名や生コードを出して「検知はできている」ことが分かるようにする。
func _key_label(event: InputEventKey) -> String:
	var name := _kc_name(event.keycode)
	if name == "":
		var pname := _kc_name(event.physical_keycode)
		if pname != "":
			name = pname + "（物理）"
	if name == "":
		var lname := _kc_name(event.key_label)
		if lname != "":
			name = lname + "（ラベル）"
	if name == "" and event.unicode != 0:
		name = "「%s」" % char(event.unicode)
	if name == "":
		name = "名称なしキー (物理コード %d)" % event.physical_keycode
	return name


## キーコードの表示名。0 / KEY_UNKNOWN / "Unknown" は名前なし扱いで "" を返す。
func _kc_name(code: int) -> String:
	if code == 0 or code == KEY_UNKNOWN:
		return ""
	var s := OS.get_keycode_string(code)
	return "" if s == "Unknown" else s


## パッドのボタン番号を分かりやすい名前にする (Xbox 表記基準)。
func _joy_button_name(idx: int) -> String:
	match idx:
		JOY_BUTTON_A: return "A ボタン"
		JOY_BUTTON_B: return "B ボタン"
		JOY_BUTTON_X: return "X ボタン"
		JOY_BUTTON_Y: return "Y ボタン"
		JOY_BUTTON_BACK: return "戻る (Back/View)"
		JOY_BUTTON_GUIDE: return "Guide (ガイド)"
		JOY_BUTTON_START: return "メニュー (Start)"
		JOY_BUTTON_LEFT_STICK: return "左スティック押し込み"
		JOY_BUTTON_RIGHT_STICK: return "右スティック押し込み"
		JOY_BUTTON_LEFT_SHOULDER: return "LB (左ショルダー)"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB (右ショルダー)"
		JOY_BUTTON_DPAD_UP: return "十字キー ↑"
		JOY_BUTTON_DPAD_DOWN: return "十字キー ↓"
		JOY_BUTTON_DPAD_LEFT: return "十字キー ←"
		JOY_BUTTON_DPAD_RIGHT: return "十字キー →"
	return "ボタン %d" % idx


## パッドの軸を分かりやすい名前 (方向付き) にする。
func _joy_axis_name(axis: int, value: float) -> String:
	match axis:
		JOY_AXIS_LEFT_X: return "左スティック " + ("→ 右" if value > 0 else "← 左")
		JOY_AXIS_LEFT_Y: return "左スティック " + ("↓ 下" if value > 0 else "↑ 上")
		JOY_AXIS_RIGHT_X: return "右スティック " + ("→ 右" if value > 0 else "← 左")
		JOY_AXIS_RIGHT_Y: return "右スティック " + ("↓ 下" if value > 0 else "↑ 上")
		JOY_AXIS_TRIGGER_LEFT: return "LT (左トリガー)"
		JOY_AXIS_TRIGGER_RIGHT: return "RT (右トリガー)"
	return "軸 %d (%+.2f)" % [axis, value]


# ---------------- ネットワーク接続テスト (5) ----------------

## ネットワーク接続テスト: 手前から順に IP→ゲートウェイ→DNS→インターネット/共有サーバー を確認する。
## ping/TCP はブロッキングなので別スレッドで実行し、結果を call_deferred でラベルへ反映する (画面を固めない)。
func _build_network() -> void:
	_add_text("ネットワークの繋がりを手前から順に確認します。最初に × が出た所が原因です。", C_TEXT)
	_nw_run_btn = _add_button("接続テストを実行", _nw_start)
	# 前回の確認が疎通フェーズ進行中 (画面を離れて戻ってきた) なら、新ボタンを押しても _nw_start が
	# no-op になるので、無効化して進行中であることを示す (ワーカー完了時に _nw_done が再び有効化する)。
	if _nw_running:
		_nw_run_btn.disabled = true
		_nw_run_btn.text = "確認中…"
	_detail_content.add_child(HSeparator.new())

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	_detail_content.add_child(box)
	_nw_rows = {}
	for i in range(NW_STAGES.size()):
		var sid: String = NW_STAGES[i][0]
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _lt_row_style(Color(0.07, 0.07, 0.07) if i % 2 == 0 else Color(0.11, 0.11, 0.11)))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(row)
		var name_lbl := Label.new()
		name_lbl.text = NW_STAGES[i][1]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)
		var st := Label.new()
		st.custom_minimum_size = Vector2(280, 0)
		st.add_theme_color_override("font_color", C_MUTED)
		st.text = "—"
		row.add_child(st)
		box.add_child(panel)
		_nw_rows[sid] = st
	# Monitor は未実装。
	_nw_set("monitor", "未実装", C_MUTED)
	_detail_content.add_child(HSeparator.new())
	_add_text("共有サーバー = 教室のサーバー (ゲーム本体やDBが置いてある場所)。本番はここから読むので最重要。", C_MUTED)


## 結果ラベルを更新 (メインスレッドから / call_deferred 経由で呼ばれる)。
func _nw_set(stage_id: String, text: String, color: Color) -> void:
	if _nw_rows.has(stage_id) and is_instance_valid(_nw_rows[stage_id]):
		_nw_rows[stage_id].text = text
		_nw_rows[stage_id].add_theme_color_override("font_color", color)


## テスト開始: 各段階を「確認中」にしてワーカースレッドを起動する。
func _nw_start() -> void:
	if _nw_running:
		return
	_nw_cancel = false
	_nw_db_path = PathManager.get_database_path()  # autoload アクセスはメインで済ませる
	_nw_db_host = _nw_extract_host(_nw_db_path)
	_nw_speed_file = _nw_pick_speed_file()  # 読み込み速度は実ゲーム exe で測る (DB は小さすぎるため)
	for s in NW_STAGES:
		if s[0] != "monitor":
			_nw_set(s[0], "確認中…", C_TEXT)
	_nw_running = true
	if _nw_run_btn and is_instance_valid(_nw_run_btn):
		_nw_run_btn.disabled = true
		_nw_run_btn.text = "確認中…"
	_nw_thread = Thread.new()
	_nw_thread.start(_nw_run)


## ワーカースレッド本体。各段階をブロッキングで確認し、結果は call_deferred でメインへ。
## 段階境界ごとに _nw_cancel を見て、サービスモードが閉じられた / 画面を離れたら早期終了する
## (個々のブロッキング呼び出しは中断できないので、次の境界までは進む)。
func _nw_run() -> void:
	# 1. ローカルIP
	var ip := _nw_local_ipv4()
	if ip != "":
		call_deferred("_nw_set", "ip", "OK  %s" % ip, C_OK)
	else:
		call_deferred("_nw_set", "ip", "NG  IPなし (LAN未接続/ケーブル確認)", C_DANGER)
	if _nw_cancel:
		call_deferred("_nw_done")
		return
	# 2. ゲートウェイ
	var gw := _nw_default_gateway()
	if gw == "":
		call_deferred("_nw_set", "gateway", "NG  ゲートウェイ不明", C_DANGER)
	else:
		var g = _nw_ping(gw)
		if g[0]:
			call_deferred("_nw_set", "gateway", "OK  %s" % gw, C_OK)
		elif _nw_arp_reachable(gw):
			# ping を返さないルーターは多い。ARP に MAC があれば L2 到達OK (機能はしている)。
			call_deferred("_nw_set", "gateway", "OK  %s (ping無応答・ARPで確認)" % gw, C_OK)
		else:
			call_deferred("_nw_set", "gateway", "NG  %s 応答なし" % gw, C_DANGER)
	if _nw_cancel:
		call_deferred("_nw_done")
		return
	# 3. DNS
	var t0 := Time.get_ticks_msec()
	var resolved := IP.resolve_hostname("www.google.com", IP.TYPE_IPV4)
	var dms := Time.get_ticks_msec() - t0
	if resolved != "":
		call_deferred("_nw_set", "dns", "OK  %s (%dms)" % [resolved, dms], C_OK)
	else:
		call_deferred("_nw_set", "dns", "NG  名前解決できない (%dms)" % dms, C_DANGER)
	if _nw_cancel:
		call_deferred("_nw_done")
		return
	# 4. インターネット (DNS非依存で IP 直 TCP)
	var inet = _nw_tcp("1.1.1.1", 443, 3000)
	if inet[0]:
		call_deferred("_nw_set", "internet", "OK  (%dms)" % inet[1], C_OK)
	else:
		call_deferred("_nw_set", "internet", "NG  外部に届かない", C_DANGER)
	if _nw_cancel:
		call_deferred("_nw_done")
		return
	# 5. 共有サーバー疎通
	if _nw_db_host == "":
		call_deferred("_nw_set", "server", "対象外 (ローカル/不明なDBパス)", C_MUTED)
	else:
		var srv = _nw_tcp(_nw_db_host, 445, 3000)
		if srv[0]:
			call_deferred("_nw_set", "server", "OK  %s (%dms)" % [_nw_db_host, srv[1]], C_OK)
		else:
			call_deferred("_nw_set", "server", "NG  %s に届かない" % _nw_db_host, C_DANGER)
	call_deferred("_nw_done")


## 疎通テスト完了 (メインスレッド)。スレッドを join し、速度計測を Companion へ依頼する。
## 速度プローブは非同期 (結果は speedtest_result シグナル) なので、両方の結果が届く (または
## タイムアウトする) まで run state を保持しボタンを無効のままにする。投げた直後に解放すると、
## 結果到着前の再実行が Companion 側 _speedRunning に弾かれ「測定中…」固着し得るため (Codex #2)。
func _nw_done() -> void:
	if _nw_thread:
		_nw_thread.wait_to_finish()  # ワーカーは既に return 済みなので即座に返る
		_nw_thread = null
	# 閉じられた / 画面を離れた場合は join + フラグ解除だけ行い、速度計測の依頼や UI 復帰はしない
	# (対象の行/ボタンは解放済みのことがある)。
	if _nw_cancel:
		_nw_running = false
		# 離脱中に network 画面が作り直されている場合、その新ボタンを「実行可能」に戻す
		# (「確認中…」で固着させない)。close 時は _nw_run_btn=null なので guard で skip。
		if _nw_run_btn and is_instance_valid(_nw_run_btn):
			_nw_run_btn.disabled = false
			_nw_run_btn.text = "接続テストを実行"
		return
	# 速度計測は Companion 側で実施 (キャッシュ回避の正確な測定。結果は speedtest_result シグナル)。
	var agent := get_node_or_null("/root/LauncherAgent")
	if agent and agent.has_method("is_available") and agent.is_available():
		_nw_set("inet_speed", "測定中…", C_TEXT)
		_nw_set("server_speed", "測定中…", C_TEXT)
		_nw_run_id += 1  # この run の識別子。これ以外の run_id の結果 (古い遅延結果) は無視する
		agent.request_speedtest(_nw_speed_file, _nw_run_id)
		_nw_speed_pending = 2  # internet + server の 2 結果を待つ
		_nw_speed_timeout_left = NW_SPEED_TIMEOUT_SEC
		if _nw_run_btn and is_instance_valid(_nw_run_btn):
			_nw_run_btn.text = "計測中…"  # disabled のまま保持
		return
	# Companion 無し: 速度測定はできないのでここで解放。
	_nw_set("inet_speed", "—（Companion無し）", C_MUTED)
	_nw_set("server_speed", "—（Companion無し）", C_MUTED)
	_nw_release_run()


## ネットワークテスト完了。run state を解放しボタンを再有効化する。
func _nw_release_run() -> void:
	_nw_running = false
	_nw_speed_pending = 0
	if _nw_run_btn and is_instance_valid(_nw_run_btn):
		_nw_run_btn.disabled = false
		_nw_run_btn.text = "もう一度テスト"


## Companion からの速度計測結果。kind="internet"/"server" を対応する段に反映する。
func _nw_on_speed(kind: String, ok: bool, text: String, run_id: int) -> void:
	# 現在の run の結果のみ受理する。古いプローブの遅延結果が新 run の行/pending を汚すのを防ぐ。
	if run_id != _nw_run_id:
		return
	var sid := "inet_speed" if kind == "internet" else ("server_speed" if kind == "server" else "")
	if sid == "":
		return
	_nw_set(sid, text, C_OK if ok else C_DANGER)
	# 両方の速度結果が揃ったら run state を解放してボタンを戻す (Codex #2)。
	if _nw_speed_pending > 0:
		_nw_speed_pending -= 1
		if _nw_speed_pending <= 0:
			_nw_release_run()


## ループバック/APIPA を除いた最初のローカル IPv4。
func _nw_local_ipv4() -> String:
	for a in IP.get_local_addresses():
		if "." in a and not a.begins_with("127.") and not a.begins_with("169.254."):
			return a
	return ""


## デフォルトゲートウェイの IP を route テーブルから取得する (locale 非依存。取れなければ "")。
func _nw_default_gateway() -> String:
	var out: Array = []
	OS.execute("route", ["print", "-4", "0.0.0.0"], out)
	if out.is_empty():
		return ""
	var rx := RegEx.new()
	rx.compile("0\\.0\\.0\\.0\\s+0\\.0\\.0\\.0\\s+(\\d+\\.\\d+\\.\\d+\\.\\d+)")
	var m := rx.search(str(out[0]))
	return m.get_string(1) if m else ""


## ping を 1 回打って応答有無と所要 ms を返す ([ok, ms])。locale に依存しない "TTL=" で判定。
func _nw_ping(host: String) -> Array:
	# 3 回打って 1 回でも返れば OK (単発だと不安定/ロスのある回線で取りこぼして誤NGになるため)。
	var t0 := Time.get_ticks_msec()
	var out: Array = []
	OS.execute("ping", ["-n", "3", "-w", "1000", host], out)
	var ms := Time.get_ticks_msec() - t0
	var text := str(out[0]) if not out.is_empty() else ""
	return [text.contains("TTL=") or text.contains("ttl="), ms]


## ARP テーブルに host の MAC があるか (= L2 到達OK)。ping を返さないルーターでも到達確認できる。
func _nw_arp_reachable(host: String) -> bool:
	var out: Array = []
	OS.execute("arp", ["-a", host], out)
	if out.is_empty():
		return false
	var rx := RegEx.new()
	rx.compile("([0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2}")
	var m := rx.search(str(out[0]))
	if m == null:
		return false
	var mac := m.get_string(0).to_lower()
	return mac != "ff-ff-ff-ff-ff-ff" and mac != "00-00-00-00-00-00"


## TCP 接続を試みて成否と所要 ms を返す ([ok, ms])。timeout_ms で打ち切る。
func _nw_tcp(host: String, port: int, timeout_ms: int) -> Array:
	var t0 := Time.get_ticks_msec()
	var tcp := StreamPeerTCP.new()
	if tcp.connect_to_host(host, port) != OK:
		return [false, Time.get_ticks_msec() - t0]
	while true:
		tcp.poll()
		var s := tcp.get_status()
		if s == StreamPeerTCP.STATUS_CONNECTED:
			tcp.disconnect_from_host()
			return [true, Time.get_ticks_msec() - t0]
		if s == StreamPeerTCP.STATUS_ERROR:
			return [false, Time.get_ticks_msec() - t0]
		if Time.get_ticks_msec() - t0 >= timeout_ms:
			tcp.disconnect_from_host()
			return [false, timeout_ms]
		OS.delay_msec(50)
	return [false, timeout_ms]  # 到達しないが GDScript の戻り値検査のため


## 読み込み速度の計測対象を選ぶ。games フォルダを丸ごと Companion に渡し、配下で最大の
## ファイル (.pck / プレビュー動画 .mp4 / Unity の .resS 等) を測らせる。exe は Godot ゲームだと
## 数百KB と小さく速度がブレるため対象にしない。games フォルダが無ければ DB にフォールバック。
func _nw_pick_speed_file() -> String:
	var games := PathManager.get_games_folder()
	if DirAccess.dir_exists_absolute(games):
		return games
	return _nw_db_path


## DB パスから共有サーバーのホスト名を取り出す (UNC \\HOST\... のみ。それ以外は "")。
func _nw_extract_host(path: String) -> String:
	var p := path.replace("/", "\\")
	if p.begins_with("\\\\"):
		var rest := p.substr(2)
		var slash := rest.find("\\")
		return rest.substr(0, slash) if slash > 0 else rest
	return ""


func _build_system_info() -> void:
	var list := ItemList.new()
	list.focus_mode = Control.FOCUS_ALL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 460)
	_detail_content.add_child(list)
	# リアルタイム更新用に参照とインデックスを初期化。
	_sysinfo_list = list
	_sys_idx_memfree = -1
	_sys_idx_memapp = -1
	_sys_idx_fps = -1
	_sys_idx_datetime = -1
	_sys_idx_uptime = -1

	var screen := get_window().current_screen
	var ev := Engine.get_version_info()
	var pc := OS.get_environment("COMPUTERNAME")
	if pc.is_empty():
		pc = "(不明)"

	# ── ハードウェア ──
	_sysinfo_header(list, "ハードウェア")
	_sysinfo_line(list, "CPU", "%s （%d コア）" % [OS.get_processor_name(), OS.get_processor_count()])
	_sysinfo_line(list, "GPU", "%s / %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()])
	var mem := OS.get_memory_info()
	var phys: int = int(mem.get("physical", -1))
	_sys_phys_bytes = phys
	if phys > 0:
		_sys_idx_memfree = _sysinfo_line(list, "物理メモリ", _phys_mem_text())
	_sys_idx_memapp = _sysinfo_line(list, "アプリ使用メモリ", _app_mem_text())

	# ── ディスプレイ ──
	_sysinfo_header(list, "ディスプレイ")
	_sysinfo_line(list, "現在のモニタ", "#%d  %s" % [screen, str(DisplayServer.screen_get_size(screen))])
	var rr := DisplayServer.screen_get_refresh_rate(screen)
	_sysinfo_line(list, "リフレッシュレート", ("%.0f Hz" % rr) if rr > 0.0 else "不明")
	_sysinfo_line(list, "ウィンドウサイズ", str(DisplayServer.window_get_size()))
	_sysinfo_line(list, "モニタ数", "%d" % DisplayServer.get_screen_count())
	_sysinfo_line(list, "DPI", "%d" % DisplayServer.screen_get_dpi(screen))
	_sysinfo_line(list, "V-Sync", _vsync_mode_text())
	_sys_idx_fps = _sysinfo_line(list, "現在のFPS", "%d" % Engine.get_frames_per_second())
	_sysinfo_line(list, "描画", "%s / %s" % [DisplayServer.get_name(), RenderingServer.get_video_adapter_api_version()])

	# ── システム ──
	_sysinfo_header(list, "システム")
	_sysinfo_line(list, "PC 名", pc)
	_sysinfo_line(list, "OS", "%s  %s" % [OS.get_name(), OS.get_version()])
	_sysinfo_line(list, "ロケール", OS.get_locale())
	_sys_idx_datetime = _sysinfo_line(list, "現在日時", Time.get_datetime_string_from_system(false, true))
	_sys_idx_uptime = _sysinfo_line(list, "稼働時間", _uptime_text())
	_sysinfo_line(list, "ローカルIP", _local_ipv4())

	# ── バージョン / パス ──
	_sysinfo_header(list, "バージョン / パス")
	_sysinfo_line(list, "Launcher", Version.get_version_string())
	_sysinfo_line(list, "Godot", str(ev.get("string", "?")))
	_sysinfo_line(list, "プロセス PID", "%d" % OS.get_process_id())
	_sysinfo_line(list, "実行ファイル", OS.get_executable_path())
	_sysinfo_line(list, "DB", PathManager.get_database_path())


## システム情報の見出し行 (選択不可・アクセント色)。
func _sysinfo_header(list: ItemList, text: String) -> void:
	var idx := list.add_item("── %s ──" % text)
	list.set_item_custom_fg_color(idx, C_ACCENT)
	list.set_item_selectable(idx, false)
	# 既定だと項目ツールチップが空文字→項目テキストにフォールバックし、ホバー時に見出し名が
	# カーソル付近にフキダシで浮く (中央あたりにセクション名が出る誤解の原因)。行内に全文見えているので無効化。
	list.set_item_tooltip_enabled(idx, false)


## システム情報の 1 行 ("ラベル: 値")。追加した item の index を返す (リアルタイム更新用)。
func _sysinfo_line(list: ItemList, label: String, value: String) -> int:
	var idx := list.add_item("%s: %s" % [label, value])
	list.set_item_tooltip_enabled(idx, false)  # 行テキストの重複フキダシを抑止 (見出しと同様)
	return idx


## 現在の V-Sync モードを日本語で返す。
func _vsync_mode_text() -> String:
	match DisplayServer.window_get_vsync_mode():
		DisplayServer.VSYNC_DISABLED: return "無効"
		DisplayServer.VSYNC_ENABLED: return "有効"
		DisplayServer.VSYNC_ADAPTIVE: return "アダプティブ"
		DisplayServer.VSYNC_MAILBOX: return "メールボックス"
	return "?"


## 主要なローカル IPv4 アドレスを返す (ループバック・APIPA は除外)。
func _local_ipv4() -> String:
	var addrs: Array[String] = []
	for a in IP.get_local_addresses():
		if "." in a and not a.begins_with("127.") and not a.begins_with("169.254."):
			addrs.append(a)
	return ", ".join(addrs) if not addrs.is_empty() else "なし"


func _phys_mem_text() -> String:
	var s := "%.1f GB" % (_sys_phys_bytes / 1073741824.0)
	var freemem: int = int(OS.get_memory_info().get("free", -1))
	if freemem > 0:
		s += "  （空き %.1f GB）" % (freemem / 1073741824.0)
	return s


func _app_mem_text() -> String:
	return "%.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)


func _uptime_text() -> String:
	return "%d 秒" % int(Time.get_ticks_msec() / 1000.0)


## システム情報の変動する行だけを書き換える (行は作り直さずスクロール位置を保つ)。
func _refresh_sysinfo() -> void:
	var list := _sysinfo_list
	if list == null or not is_instance_valid(list):
		return
	if _sys_idx_memfree >= 0:
		list.set_item_text(_sys_idx_memfree, "物理メモリ: " + _phys_mem_text())
	if _sys_idx_memapp >= 0:
		list.set_item_text(_sys_idx_memapp, "アプリ使用メモリ: " + _app_mem_text())
	if _sys_idx_fps >= 0:
		list.set_item_text(_sys_idx_fps, "現在のFPS: %d" % Engine.get_frames_per_second())
	if _sys_idx_datetime >= 0:
		list.set_item_text(_sys_idx_datetime, "現在日時: " + Time.get_datetime_string_from_system(false, true))
	if _sys_idx_uptime >= 0:
		list.set_item_text(_sys_idx_uptime, "稼働時間: " + _uptime_text())


## ゲーム動作テスト。まず確認方法を選ぶ画面を出し、選ぶと中身全体がそのモード画面に切り替わる。
## モード画面で ← / B / Esc を押すと確認方法の選択へ戻る (詳細ペインからは出ない)。
func _build_games_test() -> void:
	if _games_test_mode == "":
		_build_games_test_menu()
	else:
		# モード画面: 先頭に「戻る」を置き (操作の起点 + フォーカス先)、その下にモードの中身。
		_add_button("← 戻る（確認方法の選択へ）",
			func(): _games_test_mode = ""; _build_detail("games_test"); _refocus_detail())
		_detail_content.add_child(HSeparator.new())
		match _games_test_mode:
			"exists": _render_games_exists_check()
			"auto": _build_games_launch_test()
			"play": _build_games_playtest()


## ゲーム動作テストの確認方法 選択画面 (3 段階)。3 択の下に、今フォーカス (キーボード) または
## ホバー (マウス) している選択肢の詳細説明をライブ表示する。どれも選んでいない時は何も出さない。
func _build_games_test_menu() -> void:
	_add_text("ゲームの動作を 3 段階で確認できます。確認方法を選んでください。", C_TEXT)
	_games_focus_idx = -1
	_games_hover_idx = -1
	var b1 := _add_button("① ファイル存在チェック（起動しない・全件一括）",
		func(): _games_test_mode = "exists"; _build_detail("games_test"); _refocus_detail())
	var b2 := _add_button("② 起動テスト（自動で起動→終了し、起動可否だけ確認）",
		func(): _games_test_mode = "auto"; _build_detail("games_test"); _refocus_detail())
	var b3 := _add_button("③ 試遊テスト（実際に遊ぶ・中断メニューも確認）",
		func(): _games_test_mode = "play"; _build_detail("games_test"); _refocus_detail())
	_connect_games_method(b1, 0)
	_connect_games_method(b2, 1)
	_connect_games_method(b3, 2)
	_detail_content.add_child(HSeparator.new())
	_games_test_desc = Label.new()
	_games_test_desc.add_theme_color_override("font_color", C_MUTED)
	_games_test_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.add_child(_games_test_desc)
	# 初期は空。フォーカス/ホバーが乗った時だけ出す。


## 各選択肢ボタンの focus/hover の出入りを index として記録し、説明を更新する。is_hovered()/has_focus() を
## その場で問い合わせると _input 途中で状態が古いことがあるため、シグナルで index を確実に追跡する。
func _connect_games_method(b: Button, idx: int) -> void:
	b.focus_entered.connect(func() -> void:
		_games_focus_idx = idx
		_update_games_test_desc())
	b.focus_exited.connect(func() -> void:
		if _games_focus_idx == idx:
			_games_focus_idx = -1
		_update_games_test_desc())
	b.mouse_entered.connect(func() -> void:
		_games_hover_idx = idx
		_update_games_test_desc())
	b.mouse_exited.connect(func() -> void:
		if _games_hover_idx == idx:
			_games_hover_idx = -1
		_update_games_test_desc())


## 今「表示されている方」の指標で選ばれている選択肢の説明を出す。どれも選んでいなければ空にする。
## キーボード/パッド操作中 (カーソル非表示) はフォーカス index のみ、マウス操作中 (フォーカス枠非表示) は
## ホバー index のみを見る。これで、非表示側の指標 (置き去りのマウスホバー / 裏のキーボードフォーカス) に
## 反応して説明が出るのを防ぐ。
func _update_games_test_desc() -> void:
	if _games_test_desc == null or not is_instance_valid(_games_test_desc):
		return
	var idx := _games_hover_idx if _using_mouse else _games_focus_idx
	if idx >= 0 and idx < 3:
		_set_games_test_desc(["exists", "auto", "play"][idx])
	else:
		_games_test_desc.text = ""


## 確認方法の選択画面で、選択肢の詳細説明を切り替える。
func _set_games_test_desc(mode: String) -> void:
	if _games_test_desc == null or not is_instance_valid(_games_test_desc):
		return
	match mode:
		"exists":
			_games_test_desc.text = "各ゲームの実行ファイル(exe)が実際にあるかを、起動せずに全件まとめて確認します。LAN 共有の未接続・フォルダ移動・パス設定ミスで実行ファイルが見つからないゲームを一覧で洗い出せます。一番手軽に確認できます。"
		"auto":
			_games_test_desc.text = "各ゲームを自動で起動し、ウィンドウが出るところまで確認してから自動で終了します。起動できるか(OK/NG)だけを一覧で判定。DLL 不足や起動直後のクラッシュなど『そもそも立ち上がらない』問題の検出向けです。"
		"play":
			_games_test_desc.text = "選んだゲームを実際に起動して遊んで確認します。終了は原則、遊んでいる最中に HOMEキー / Guideボタンで本番と同じ中断メニューを出して「試遊を終了する」を選びます（試遊中は「続ける／試遊を終了する」の 2 択）。ゲームごとに『正しく遊べたか』『中断メニューが動いたか』の 2 つを 〇× で記録して次へ進みます。『実際にちゃんと遊べるか』＋『中断メニューが効くか』を見る最終確認向けです。

※ 試遊のプレイは記録に残りません（人気ランキングを汚さないため意図的に除外しています）。記録が取れる状態かは「6. 記録・アンケートの動作確認」で確かめてください。"


## モード①: 各ゲームの実行ファイル(exe)が存在するか (= パス切れ/ファイル欠落がないか) を起動せずチェック。
func _render_games_exists_check() -> void:
	var db := DatabaseManager.new()
	if not db.open():
		_add_text("⚠ データベースを開けませんでした。Manager での初期化が必要かもしれません。", C_DANGER)
		return
	var repo := GameRepository.new(db)
	var games := repo.get_all_games()
	db.close()
	if games.is_empty():
		_add_text("登録ゲームがありません (または DB 読み込みに失敗)。", C_MUTED)
		return
	var ng := 0
	for g in games:
		if GamePathResolver.find_executable(g) == "":
			ng += 1
	_add_text("登録 %d 件中  OK %d / NG %d" % [games.size(), games.size() - ng, ng],
		C_OK if ng == 0 else C_DANGER)
	_add_text("（各ゲームの exe が存在するかを確認。NG はパス切れ/ファイル欠落。起動はしません）", C_MUTED)
	# 一覧は ItemList で表示。フォーカス可能なのでキーボード/コントローラー (↑↓) でもスクロールできる
	# (Label の羅列だとフォーカスが移れず長い一覧をスクロールできないため)。
	var list := ItemList.new()
	list.focus_mode = Control.FOCUS_ALL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 360)
	for g in games:
		var ok := GamePathResolver.find_executable(g) != ""
		var line := "✓ %s  [%s]" % [g.title, g.game_id] if ok \
			else "✗ %s  [%s]  exe 不明: %s" % [g.title, g.game_id, g.executable_path]
		var idx := list.add_item(line)
		list.set_item_custom_fg_color(idx, C_OK if ok else C_DANGER)
		list.set_item_selectable(idx, true)
	_detail_content.add_child(list)


## モード②: 起動テスト。チェックを付けたゲームを 1 本ずつ実際に起動し、ウィンドウが出れば OK・
## 出なければ NG と判定して自動終了する。各ゲームにチェックボックス + 「すべてチェック/外す」+「テスト開始」。
func _build_games_launch_test() -> void:
	_lt_reset_state()
	var db := DatabaseManager.new()
	if not db.open():
		_add_text("⚠ データベースを開けませんでした。Manager での初期化が必要かもしれません。", C_DANGER)
		return
	var repo := GameRepository.new(db)
	_lt_games = repo.get_all_games()
	db.close()
	if _lt_games.is_empty():
		_add_text("登録ゲームがありません (または DB 読み込みに失敗)。", C_MUTED)
		return

	_add_text("チェックを付けたゲームを 1 本ずつ実際に起動し、ウィンドウが出れば OK と判定して自動終了します。", C_TEXT)
	_add_text("※ テスト中はゲーム画面が一瞬ずつ前面に出ます。", C_MUTED)
	_add_button("すべてチェック", func(): _lt_set_all(true))
	_add_button("すべて外す", func(): _lt_set_all(false))
	_lt_start_btn = _add_button("チェックしたゲームをテスト", _lt_start)
	_lt_stop_btn = _add_button("テストを中止", _lt_abort)
	_lt_stop_btn.disabled = true  # 実行中のみ有効

	# システム情報と同様、高さ固定のスクロール枠の中に一覧を陳列する (枠内だけがスクロールする)。
	_lt_scroll = ScrollContainer.new()
	_lt_scroll.follow_focus = true
	_lt_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_lt_scroll.custom_minimum_size = Vector2(0, 420)
	_lt_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_content.add_child(_lt_scroll)
	var list_box := VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 0)  # 行を詰めてゼブラを連続させる
	_lt_scroll.add_child(list_box)
	# ゼブラ (交互背景) でリスト感を出す。行は詰める。
	var row_a := _lt_row_style(Color(0.07, 0.07, 0.07))
	var row_b := _lt_row_style(Color(0.11, 0.11, 0.11))
	_lt_checks.clear()
	_lt_status.clear()
	for i in range(_lt_games.size()):
		var g = _lt_games[i]
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", row_a if i % 2 == 0 else row_b)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(row)
		var cb := CheckBox.new()
		cb.text = " " + g.title
		cb.button_pressed = true  # 既定は全部チェック
		cb.focus_mode = Control.FOCUS_ALL
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.add_theme_stylebox_override("normal", _lt_empty_sb())  # 行の地を活かす (ボタン地を出さない)
		_apply_focus_style_to(cb)
		row.add_child(cb)
		var st := Label.new()
		st.add_theme_color_override("font_color", C_MUTED)
		st.text = "未"
		st.custom_minimum_size = Vector2(220, 0)
		row.add_child(st)
		list_box.add_child(panel)
		_lt_checks.append(cb)
		_lt_status.append(st)


## 起動テスト一覧の行背景スタイル (ゼブラ用)。
func _lt_row_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


func _lt_empty_sb() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


## 全チェックボックスを一括 ON/OFF。
func _lt_set_all(on: bool) -> void:
	if _lt_running:
		return
	for cb in _lt_checks:
		if is_instance_valid(cb):
			cb.button_pressed = on


## テスト開始: チェック済みゲームをキューに積んで実行を始める。
func _lt_start() -> void:
	if _lt_running:
		return
	_lt_queue.clear()
	for i in range(_lt_checks.size()):
		if is_instance_valid(_lt_checks[i]) and _lt_checks[i].button_pressed:
			_lt_queue.append(i)
			_lt_set_status(i, "待機", C_MUTED)
		else:
			_lt_set_status(i, "—", C_MUTED)
	if _lt_queue.is_empty():
		return
	_lt_running = true
	if _lt_start_btn and is_instance_valid(_lt_start_btn):
		_lt_start_btn.disabled = true
		_lt_start_btn.text = "テスト中…"
	if _lt_stop_btn and is_instance_valid(_lt_stop_btn):
		_lt_stop_btn.disabled = false
	_lt_begin_next()


## キューの次のゲームをテスト開始する。空ならテスト完了。
func _lt_begin_next() -> void:
	if _lt_queue.is_empty():
		_lt_finish()
		return
	_lt_cur = _lt_queue.pop_front()
	# テスト中のゲーム行が常に見えるよう自動スクロール。
	if _lt_scroll and is_instance_valid(_lt_scroll) and _lt_cur < _lt_checks.size():
		_lt_scroll.ensure_control_visible(_lt_checks[_lt_cur])
	var g = _lt_games[_lt_cur]
	var exe := GamePathResolver.find_executable(g)
	if exe.is_empty():
		_lt_set_status(_lt_cur, "NG: 実行ファイルなし", C_DANGER)
		_lt_begin_next()
		return
	var pid := _spawn_game_process(exe, g)
	if pid == -1:
		_lt_set_status(_lt_cur, "NG: 起動失敗", C_DANGER)
		_lt_begin_next()
		return
	_lt_pid = pid
	if LauncherAgent.is_available():
		LauncherAgent.watch(pid)
	_lt_set_status(_lt_cur, "起動中…", C_TEXT)
	_lt_phase = "wait"
	_lt_phase_ms = Time.get_ticks_msec()


## exe を cmd 経由で起動し PID を返す (GameSession.start_process と同方式)。失敗で -1。
## 起動テスト(②)と試遊テスト(③)の両方から呼ぶ純粋ヘルパー (内部状態を持たない)。
func _spawn_game_process(exe_path: String, game) -> int:
	var working_dir := exe_path.get_base_dir()
	var cmd := 'cd /d "%s" && "%s"' % [working_dir, exe_path]
	var args := GamePathResolver.parse_arguments(game.arguments)
	if not args.is_empty():
		var escaped: Array = []
		for a in args:
			escaped.append('"%s"' % a.replace('"', '\\"'))
		cmd += " " + " ".join(escaped)
	return OS.create_process("cmd.exe", ["/C", cmd])


func _lt_set_status(index: int, text: String, color: Color) -> void:
	if index >= 0 and index < _lt_status.size() and is_instance_valid(_lt_status[index]):
		_lt_status[index].text = text
		_lt_status[index].add_theme_color_override("font_color", color)


## テスト完了: 後始末して開始ボタンを戻す。
func _lt_finish() -> void:
	_lt_running = false
	_lt_cur = -1
	_lt_pid = -1
	_lt_phase = ""
	if LauncherAgent.is_available():
		LauncherAgent.unwatch()
	_lt_restore_buttons()


## ユーザーが「テストを中止」: 進行中のテストを止め、残りを「中止」表示にする。
func _lt_abort() -> void:
	if not _lt_running:
		return
	if _lt_cur >= 0:
		_lt_set_status(_lt_cur, "中止", C_MUTED)
	for i in _lt_queue:
		_lt_set_status(i, "中止", C_MUTED)
	_lt_stop()  # 起動中ゲームを終了 + watch 解除 + 実行フラグ解除
	_lt_restore_buttons()


## 開始/中止ボタンの表示を待機状態に戻す。
func _lt_restore_buttons() -> void:
	if _lt_start_btn and is_instance_valid(_lt_start_btn):
		_lt_start_btn.disabled = false
		_lt_start_btn.text = "チェックしたゲームをテスト"
	if _lt_stop_btn and is_instance_valid(_lt_stop_btn):
		_lt_stop_btn.disabled = true


func _lt_reset_state() -> void:
	_lt_stop()
	_lt_games = []
	_lt_checks = []
	_lt_status = []
	_lt_start_btn = null
	_lt_stop_btn = null
	_lt_scroll = null


## 進行中の起動テストを止める (画面を離れる / 閉じる時)。起動中のゲームは終了させ、watch も解除する。
func _lt_stop() -> void:
	if _lt_pid != -1 and OS.is_process_running(_lt_pid):
		OS.create_process("taskkill", ["/PID", str(_lt_pid), "/T", "/F"])
	if _lt_running and LauncherAgent.is_available():
		LauncherAgent.unwatch()
	_lt_running = false
	_lt_queue = []
	_lt_cur = -1
	_lt_phase = ""
	_lt_pid = -1


## 起動テストの毎フレーム進行 (_process から呼ぶ)。窓検出 or 早期終了 or タイムアウトで判定 → kill → 次へ。
func _lt_tick() -> void:
	if not _lt_running:
		return
	var now := Time.get_ticks_msec()
	match _lt_phase:
		"wait":
			# プロセスが先に消えた = 起動直後にクラッシュ/即終了。
			if not OS.is_process_running(_lt_pid):
				_lt_set_status(_lt_cur, "NG: すぐ終了 (クラッシュ?)", C_DANGER)
				_lt_after_kill()
				return
			if LauncherAgent.is_available():
				var st := LauncherAgent.get_window_state()
				if st == LauncherAgent.WindowState.VISIBLE_FOREGROUND or st == LauncherAgent.WindowState.VISIBLE_BACKGROUND:
					_lt_set_status(_lt_cur, "OK (ウィンドウ確認)", C_OK)
					_lt_kill_current()
					return
				if now - _lt_phase_ms >= LT_WINDOW_TIMEOUT_MS:
					_lt_set_status(_lt_cur, "NG: ウィンドウが出ない", C_DANGER)
					_lt_kill_current()
					return
			else:
				# Companion 不在 (エディタ等): 窓検出できないので、一定時間生きていれば OK 扱い。
				if now - _lt_phase_ms >= LT_NOWINDOW_OK_MS:
					_lt_set_status(_lt_cur, "OK (起動のみ確認)", C_OK)
					_lt_kill_current()
					return
		"kill":
			# taskkill 発行後、プロセス消失を待ってから次へ (重複起動を避ける)。
			if not OS.is_process_running(_lt_pid) or now - _lt_phase_ms >= LT_KILL_TIMEOUT_MS:
				if LauncherAgent.is_available():
					LauncherAgent.unwatch()
				_lt_pid = -1
				_lt_begin_next()


## 現在テスト中のゲームを終了し、消失待ちフェーズへ。
func _lt_kill_current() -> void:
	if _lt_pid != -1:
		OS.create_process("taskkill", ["/PID", str(_lt_pid), "/T", "/F"])
	_lt_phase = "kill"
	_lt_phase_ms = Time.get_ticks_msec()


## kill 不要 (既に終了済み) の場合に次へ進む。
func _lt_after_kill() -> void:
	if LauncherAgent.is_available():
		LauncherAgent.unwatch()
	_lt_pid = -1
	_lt_begin_next()


# ---------------- 試遊テスト (4③) ----------------

## モード③: 試遊テスト。チェックしたゲームを 1 本ずつ自動で起動→試遊→復帰し、戻るたびに 〇× を記録して次へ。
func _build_games_playtest() -> void:
	_pt_reset_state()
	var db := DatabaseManager.new()
	if not db.open():
		_add_text("⚠ データベースを開けませんでした。Manager での初期化が必要かもしれません。", C_DANGER)
		return
	var repo := GameRepository.new(db)
	_pt_games = repo.get_all_games()
	db.close()
	if _pt_games.is_empty():
		_add_text("登録ゲームがありません (または DB 読み込みに失敗)。", C_MUTED)
		return

	_add_text("チェックしたゲームを 1 本ずつ起動して試遊します。終了は原則、遊んでいる最中に HOMEキー / Guideボタンで本番と同じ中断メニューを出し、「試遊を終了する」を選んでください（中断メニューの動作確認を兼ねるため）。", C_TEXT)
	_add_text("ゲームが終了するたびに「正しく遊べたか」「中断メニューが動いたか」の 2 つを 〇× で記録して、自動で次のゲームに進みます（結果は「遊 / 中断」の順に表示）。中断メニューが出ない・操作できないときは、ゲーム自体の終了操作で閉じて中断に × を付けてください。", C_TEXT)
	# (#311/#297) 試遊は test_session により**プレイ記録から意図的に除外**される。ここに書かないと
	# 「試遊できた＝記録も取れている」と誤解したまま開場してしまい、当日ぶんの記録が丸ごと失われる。
	# 取り返しがつかないデータなので、実行画面にも明示して確認先へ誘導する。
	_add_text("※ 試遊のプレイは記録に残りません（人気ランキングを汚さないため意図的に除外）。記録が取れる状態かは「6. 記録・アンケートの動作確認」で確かめてください。", C_MUTED)
	_add_button("すべてチェック", func(): _pt_set_all(true))
	_add_button("すべて外す", func(): _pt_set_all(false))
	_pt_start_btn = _add_button("チェックしたゲームを試遊", _pt_start)
	_pt_stop_btn = _add_button("中止", _pt_abort)
	_pt_stop_btn.disabled = true

	_pt_scroll = ScrollContainer.new()
	_pt_scroll.follow_focus = true
	_pt_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pt_scroll.custom_minimum_size = Vector2(0, 360)
	_pt_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_content.add_child(_pt_scroll)
	var list_box := VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 0)
	_pt_scroll.add_child(list_box)
	var row_a := _lt_row_style(Color(0.07, 0.07, 0.07))
	var row_b := _lt_row_style(Color(0.11, 0.11, 0.11))
	_pt_checks.clear()
	_pt_status.clear()
	for i in range(_pt_games.size()):
		var g = _pt_games[i]
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", row_a if i % 2 == 0 else row_b)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(row)
		var cb := CheckBox.new()
		cb.text = " " + g.title
		cb.button_pressed = true
		cb.focus_mode = Control.FOCUS_ALL
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.add_theme_stylebox_override("normal", _lt_empty_sb())
		_apply_focus_style_to(cb)
		row.add_child(cb)
		var st := Label.new()
		st.custom_minimum_size = Vector2(150, 0)
		st.text = "未"
		st.add_theme_color_override("font_color", C_MUTED)
		row.add_child(st)
		list_box.add_child(panel)
		_pt_checks.append(cb)
		_pt_status.append(st)


func _pt_set_all(on: bool) -> void:
	if _pt_running:
		return
	for cb in _pt_checks:
		if is_instance_valid(cb):
			cb.button_pressed = on


## 試遊開始: まず戻り方 (ゲーム終了 / HOMEキー・Guideボタン) を案内する確認モーダルを出し、開始の同意を取る。
func _pt_start() -> void:
	if _pt_running:
		return
	# 少なくとも 1 つチェックされているか確認 (無ければ何もしない)。
	var any := false
	for cb in _pt_checks:
		if is_instance_valid(cb) and cb.button_pressed:
			any = true
			break
	if not any:
		return
	_show_modal(
		"チェックしたゲームを順番に試遊します。\n\n【終了のしかた】原則、遊んでいる最中に HOMEキー（またはコントローラーの Guideボタン）で中断メニューを出し、「試遊を終了する」を選んでください（中断メニューが正しく動くかの確認を兼ねます）。\n\n中断メニューが出ない・操作できないときは、ゲーム自体の終了操作で閉じてください。\n\nゲーム終了後に「遊べたか」「中断メニューが動いたか」の 2 つを 〇× で記録して次へ進みます。\n\n開始しますか？",
		PackedStringArray(["開始する", "キャンセル"]),
		func(idx):
			if idx == 0:
				_pt_begin_sequence())


## 実際に試遊シーケンスを開始する (確認モーダルで「開始する」を選んだ後)。
func _pt_begin_sequence() -> void:
	if _pt_running:
		return
	_pt_queue.clear()
	for i in range(_pt_checks.size()):
		if is_instance_valid(_pt_checks[i]) and _pt_checks[i].button_pressed:
			_pt_queue.append(i)
			_set_pt_status(i, "待機", C_MUTED)
		else:
			_set_pt_status(i, "—", C_MUTED)
	if _pt_queue.is_empty():
		return
	_pt_running = true
	if _pt_start_btn and is_instance_valid(_pt_start_btn):
		_pt_start_btn.disabled = true
		_pt_start_btn.text = "試遊中…"
	if _pt_stop_btn and is_instance_valid(_pt_stop_btn):
		_pt_stop_btn.disabled = false
	# (#311) ゲーム終了 (手動終了 / 中断オーバーレイの「別のゲーム」「退出」由来の quit) を購読し、
	# 戻るたびに 〇× を尋ねて次へ進める。シーケンス終了/中止で外す。
	if not _pt_exit_connected:
		GameSession.game_exited.connect(_pt_on_return)
		_pt_exit_connected = true
	_pt_begin_next()


## キューの次のゲームを試遊起動する。空ならシーケンス完了。
func _pt_begin_next() -> void:
	if _pt_queue.is_empty():
		_pt_finish()
		return
	_pt_cur = _pt_queue.pop_front()
	if _pt_scroll and is_instance_valid(_pt_scroll) and _pt_cur < _pt_checks.size():
		_pt_scroll.ensure_control_visible(_pt_checks[_pt_cur])
	var g = _pt_games[_pt_cur]
	var exe := GamePathResolver.find_executable(g)
	if exe.is_empty():
		_set_pt_status(_pt_cur, "× 起動できない", C_DANGER)
		_pt_begin_next()
		return
	# (#311) 本番と同じ GameSession 経由で起動する。これにより HOME/Guide を OverlayManager が拾い、
	# 本物の中断オーバーレイ (再開 / 別のゲーム / 退出) が出る = サービスモードで実機確認できる。
	# begin_launch → set_current_game (タイトル/サムネ設定 + トリガ購読) → start_process の順。
	# test=true: 試遊セッションを test_session として焼き込む (将来のプレイ記録 #297 PR2 が集計から除外する)。
	# begin_launch の false は「前のセッションがまだ生きている」(running_pid 残存 / _is_launching) 競合のみで、
	# ゲーム固有の問題ではない (レビュー D-1)。「起動失敗」と書くとゲームのせいに誤診されるため区別して表示。
	# 正常な逐次フロー (_on_exited が running_pid を畳んでから 〇× → 次へ) では到達しない。
	if not GameSession.begin_launch(g, true):
		_set_pt_status(_pt_cur, "× セッション競合", C_DANGER)
		_pt_begin_next()
		return
	OverlayManager.set_current_game(g)
	if not GameSession.start_process():  # exe 不在等。begin_launch のフラグは内部で解除される。
		_set_pt_status(_pt_cur, "× 起動失敗", C_DANGER)
		_pt_begin_next()
		return
	_set_pt_status(_pt_cur, "試遊中…", C_TEXT)


## ゲームが終了 (手動終了 / 中断オーバーレイの「続ける以外」由来の quit) → GameSession.game_exited で
## 呼ばれる。復帰して 〇× プロンプト (2 問: 遊べたか → 中断メニューが動いたか) を表示する。HOME/Guide での
## 中断は OverlayManager が本物の中断メニューを出すので (#311)、ここでは「ゲームが実際に終了したとき」だけを扱う。
func _pt_on_return() -> void:
	# game_exited はシーケンス外 (中止後の遅延 kill / 既に 〇× 待ち) でも届きうるので状態で弾く。
	if not _pt_running or _pt_await:
		return
	var w := get_window()
	if w:
		w.grab_focus()  # 中断オーバーレイ窓/ゲーム消失後にメイン窓へフォーカスを戻す
	_pt_await = true
	# 中央モーダルで 〇× を尋ねる (戻った瞬間にはっきり「答えて」と分かるように)。
	_show_modal("「%s」は正しく遊べましたか？" % _pt_games[_pt_cur].title,
		PackedStringArray(["〇 遊べた", "× 問題あり"]),
		func(idx): _pt_ask_overlay(idx == 0),
		[C_OK, C_DANGER])


## (#311) 2 問目: 中断メニュー (オーバーレイ) の動作確認。終了は原則オーバーレイ経由の運用なので毎回尋ねる
## (出なかった/操作できなかったゲーム = 排他フルスクリーン系の問題児をここで洗い出す)。
func _pt_ask_overlay(play_ok: bool) -> void:
	if not _pt_await:
		return
	_show_modal("中断メニューは正しく出て、操作できましたか？\n（HOMEキー / Guideボタン → 「試遊を終了する」で終了）",
		PackedStringArray(["〇 動いた", "× 問題あり"]),
		func(idx): _pt_record(play_ok, idx == 0),
		[C_OK, C_DANGER])


## 〇× (遊べたか / 中断メニュー) を記録 → 次のゲームへ (モーダルは選択時に自動で閉じている)。
func _pt_record(play_ok: bool, overlay_ok: bool) -> void:
	if not _pt_await:
		return
	var txt := "遊%s / 中断%s" % ["〇" if play_ok else "×", "〇" if overlay_ok else "×"]
	_set_pt_status(_pt_cur, txt, C_OK if (play_ok and overlay_ok) else C_DANGER)
	_pt_await = false
	_pt_begin_next()


## 試遊シーケンス完了。
func _pt_finish() -> void:
	_pt_disconnect_exit()
	_pt_running = false
	_pt_cur = -1
	_pt_await = false
	_pt_restore_buttons()


## GameSession.game_exited の購読を外す (シーケンス終了/中止時)。
func _pt_disconnect_exit() -> void:
	if _pt_exit_connected and GameSession.game_exited.is_connected(_pt_on_return):
		GameSession.game_exited.disconnect(_pt_on_return)
	_pt_exit_connected = false


## ユーザーが「中止」: 試遊中ゲームを終了し残りを「中止」表示にする。
func _pt_abort() -> void:
	if not _pt_running:
		return
	if _pt_cur >= 0 and not _pt_await:
		_set_pt_status(_pt_cur, "中止", C_MUTED)
	for i in _pt_queue:
		_set_pt_status(i, "中止", C_MUTED)
	_pt_stop()
	_pt_restore_buttons()


func _pt_restore_buttons() -> void:
	if _pt_start_btn and is_instance_valid(_pt_start_btn):
		_pt_start_btn.disabled = false
		_pt_start_btn.text = "チェックしたゲームを試遊"
	if _pt_stop_btn and is_instance_valid(_pt_stop_btn):
		_pt_stop_btn.disabled = true


func _set_pt_status(index: int, text: String, color: Color) -> void:
	if index >= 0 and index < _pt_status.size() and is_instance_valid(_pt_status[index]):
		_pt_status[index].text = text
		_pt_status[index].add_theme_color_override("font_color", color)


func _pt_reset_state() -> void:
	_pt_stop()
	_pt_games = []
	_pt_checks = []
	_pt_status = []
	_pt_start_btn = null
	_pt_stop_btn = null
	_pt_scroll = null
	_pt_queue = []
	_pt_await = false


## 試遊を中断する (画面を離れる / 閉じる時)。起動中ゲームは終了させる。
func _pt_stop() -> void:
	# (#311) 試遊は GameSession 経由なので、置き去り防止も GameSession.quit() で行う (taskkill 直叩きしない)。
	# 中止/離脱で呼ばれるため、quit() 由来の game_exited が _pt_on_return で 〇× を出さないよう先に購読を外す
	# (オーバーレイの「終了中」handoff は OverlayManager が別途 game_exited を受けて処理する)。
	_pt_disconnect_exit()
	if GameSession.is_running():
		GameSession.quit()
	_pt_running = false
	_pt_cur = -1


## データベース整合性チェック: ファイル存在→接続→バージョン→テーブル存在/件数→読み取りテスト。
## ランチャーはデータベースを読むだけ (書き込みはしない) ので、読み取りテストのみ行う。
## 簡易ログ確認: 現セッションの直近ログ (Logger のメモリバッファ) を一覧表示。WARN/ERROR は色分け。
## Logger は組み込み Logger クラスと名前衝突するため、autoload ノードを /root/Logger 経由で参照する。
func _build_log_view() -> void:
	var logger := get_node_or_null("/root/Logger")
	if logger == null or not logger.has_method("get_recent_logs"):
		_add_text("ログ機能が利用できません。", C_DANGER)
		return
	_add_button("最新の状態に更新", func(): _build_detail("log_view"); _refocus_detail())
	var lines: Array = logger.get_recent_logs()
	if lines.is_empty():
		_add_text("ログがありません。", C_MUTED)
		return
	_add_text("現セッションの直近ログ %d 行 (古い順。最新は最下部)" % lines.size(), C_TEXT)
	var list := ItemList.new()
	list.focus_mode = Control.FOCUS_ALL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 420)
	for ln in lines:
		var idx := list.add_item(str(ln))
		if "[ERROR]" in ln:
			list.set_item_custom_fg_color(idx, C_DANGER)
		elif "[WARN]" in ln:
			list.set_item_custom_fg_color(idx, Color(1.0, 0.8, 0.4))
	_detail_content.add_child(list)
	# 最新行 (最下部) を見せる。
	if list.item_count > 0:
		list.select(list.item_count - 1)
		list.ensure_current_is_visible()


## (#297 / #34 / #35) 記録・アンケートの動作確認。
##
## **なぜ専用画面が要るか**: 「4. ゲーム動作テスト」の試遊は `GameSession.test_session` が立つため、
## プレイ記録から**意図的に除外**される (#311、試遊で本番ランキングを汚さないため)。つまり
## **スタッフが試遊しても記録は 1 件も出ない**ので、「試して確かめる」が原理的に使えない。
## 記録は文化祭当日にしか取れず取り直しも効かないので、開場前に「今日ちゃんと記録できる状態か」を
## 確認する出口がどうしても必要になる。
##
## **偽のレコードは書かない**。書き込み可否は `.probe` ファイルを作って即削除する形で確かめる。
## 本物のアンケート/プレイ記録を混ぜると集計が汚れるため。
func _build_records_check() -> void:
	_add_text("記録が取れる状態かを確認します（試遊テストでは確認できません）", C_MUTED)
	_add_text("")

	# --- 1) DB が game_no を持つか ---
	# game_no はプレイ記録・アンケート JSON がゲームを指す唯一のキー。これが無い DB では
	# 書き出し側が「参照先を解決できない孤児レコード」を避けるために記録を skip する = 全滅する。
	var dbm := DatabaseManager.new()
	var db_ok := dbm.open()
	if not db_ok:
		_add_text("✗ データベースに接続できません → 記録は 1 件も保存されません", C_DANGER)
		_add_text("　 対処: Manager が起動しているか、共有フォルダに繋がっているか確認してください", C_MUTED)
	else:
		# 版数取得も戻り値を見る。失敗すると ver = 0 に落ちて「データベースが古く記録できません (v0)」
		# という**誤った原因**をスタッフに見せることになり、「Manager を起動して更新」しても直らない
		# 切り分け不能状態に送り込む。判定の正確さと同じくらい原因表示の正確さが要る画面なので分ける。
		var ver := -1
		if dbm.db.query("PRAGMA user_version"):
			var vres := dbm.db.get_query_result()
			if vres and vres.size() > 0:
				ver = int(vres[0].get("user_version", 0))
		if ver < 0:
			_add_text("? データベースの版数を確認できませんでした（読み取りに失敗）", C_MUTED)
			_add_text("　 対処: 共有フォルダへの接続を確認し、再確認してください", C_MUTED)
		elif ver >= MIN_DB_VERSION_FOR_RECORDS:
			_add_text("✓ データベースが記録に対応しています (v%d)" % ver, C_OK)
		else:
			_add_text("✗ データベースが古く記録できません (v%d / 必要 v%d 以上)" % [ver, MIN_DB_VERSION_FOR_RECORDS], C_DANGER)
			_add_text("　 対処: Manager を起動して更新してください", C_MUTED)

		# 未採番のゲームがあると、そのゲームだけ記録が出ない (静かに欠ける) ので個別に出す。
		# 必要版数未満では game_no 列自体が無くクエリが失敗するため、版数 NG のときは走らせない
		# (走らせると「0 件 = 問題なし」と読めてしまい、列が無いのに ✓ を出す嘘になる)。
		if ver >= MIN_DB_VERSION_FOR_RECORDS:
			# query() の戻り値を必ず見る。失敗を 0 件と同一視すると、上記と同じ嘘の ✓ を生む。
			if not dbm.db.query("SELECT COUNT(*) AS c FROM games WHERE game_no IS NULL OR game_no <= 0"):
				_add_text("? ゲームの番号を確認できませんでした（読み取りに失敗）", C_MUTED)
			else:
				var ures := dbm.db.get_query_result()
				var unnumbered := -1
				if ures and ures.size() > 0:
					unnumbered = int(ures[0].get("c", 0))
				if unnumbered < 0:
					_add_text("? ゲームの番号を確認できませんでした（結果を読めません）", C_MUTED)
				elif unnumbered > 0:
					_add_text("✗ 記録できないゲームが %d 本あります（番号が未割り当て）" % unnumbered, C_DANGER)
					_add_text("　 対処: Manager を起動すると自動で割り当てられます", C_MUTED)
				else:
					_add_text("✓ 全ゲームに番号が割り当てられています", C_OK)
				# **未採番が 0 件でも「番号の再利用」は別問題** (レビュー M-4)。
				# SPEC §7.5.3 が唯一の残存リスクとして名指ししているのが「記録は残っているのに
				# DB を古い状態へ復元した」ケースで、そのとき採番は既に記録が参照している番号を
				# 踏みうる (= 新しいゲームが削除済みゲームの過去記録を横取りする / JSON は番号しか
				# 持たないので誰も気づけない)。未採番チェックだけ見て ✓ を出すと、この画面が
				# 一番避けたい「嘘の ✓」になる。ファイル名から読むだけなので中身は開かない。
				_add_number_reuse_check(dbm)

	# --- 2) アンケートのトグル状態 ---
	# 「アンケートが 1 件も出ない」の原因が『壊れている』のか『設定で OFF』なのかを現場で切り分ける。
	# ピーク時に OFF にして戻し忘れる、が一番ありそうな事故なので目立たせる。
	if db_ok:
		var repo := SettingsRepository.new(dbm)
		var ge := repo.get_bool(SurveyFlow.SETTING_GAME_END_ENABLED, SurveyFlow.DEFAULT_ENABLED)
		var le := repo.get_bool(SurveyFlow.SETTING_LAUNCHER_END_ENABLED, SurveyFlow.DEFAULT_ENABLED)
		_add_text("")
		_add_text("ゲーム終了時のアンケート: %s" % ("表示する" if ge else "表示しない ← Manager の設定で OFF"),
			C_OK if ge else C_MUTED)
		_add_text("退出時のアンケート: %s" % ("表示する" if le else "表示しない ← Manager の設定で OFF"),
			C_OK if le else C_MUTED)
		dbm.close()

	# --- 3) 実際に書き込めるか (.probe を作って消す) ---
	_add_text("")
	var base_dir := PathManager.get_base_directory()
	if base_dir.is_empty():
		_add_text("✗ インストール先を特定できません → 記録の保存先が決まりません", C_DANGER)
	else:
		var probe_dir := base_dir.path_join(ResponsesWriter.RESPONSES_DIRNAME).path_join(ResponsesWriter.CATEGORY_PLAY_RECORDS)
		var err := OK
		if not DirAccess.dir_exists_absolute(probe_dir):
			err = DirAccess.make_dir_recursive_absolute(probe_dir)
		if err != OK:
			_add_text("✗ 記録用フォルダを作れません（書き込み権限なし / 共有が切れている）", C_DANGER)
			_add_text("　 %s" % probe_dir, C_MUTED)
		else:
			# 本物の書き込みと**同じ手順**を通す (作る → 書く → 成否確認 → rename)。
			# rename を省くと、「作成は許可されているが rename は不可」な共有設定や、ウイルス対策が
			# .tmp を掴んでいる環境で probe だけ ✓ になり、本物の記録は全滅する — 診断画面が一番
			# 防ぎたい事態を見逃す。rename 先は .done にして **.json は一度も作らない**
			# (作ると件数カウントと採番走査に混ざりうる)。
			var probe_tmp := probe_dir.path_join(".write_probe.tmp")
			var probe_done := probe_dir.path_join(".write_probe.done")
			var f := FileAccess.open(probe_tmp, FileAccess.WRITE)
			if f == null:
				_add_text("✗ 記録用フォルダに書き込めません → 記録は 1 件も保存されません", C_DANGER)
				_add_text("　 対処: 共有フォルダの接続と書き込み権限を確認してください", C_MUTED)
			else:
				f.store_string("probe")
				var werr := f.get_error()
				f.close()
				if werr != OK:
					DirAccess.remove_absolute(probe_tmp)
					_add_text("✗ 書き込みに失敗しました（ディスク空き容量 / 共有の切断）", C_DANGER)
				else:
					var rerr := DirAccess.rename_absolute(probe_tmp, probe_done)
					if rerr != OK:
						DirAccess.remove_absolute(probe_tmp)
						_add_text("✗ ファイルの確定（名前の変更）に失敗しました → 記録は 1 件も保存されません", C_DANGER)
						_add_text("　 対処: 共有フォルダの権限設定と、ウイルス対策ソフトの除外設定を確認してください", C_MUTED)
					else:
						# 後始末の戻り値も見る。残骸自体は無害 (件数カウントも採番走査も .json しか
						# 見ない) だが、**消せない = 権限か AV が掴んでいる**という診断上の信号を
						# 捨てることになる。この画面は「戻り値を必ず見る」を自分の規約にしている。
						var derr := DirAccess.remove_absolute(probe_done)
						if derr != OK:
							_add_text("✓ 記録用フォルダに書き込めます（ただし確認用ファイルを消せませんでした）", C_OK)
							_add_text("　 残骸: %s" % probe_done, C_MUTED)
							_add_text("　 記録自体は保存できますが、権限かウイルス対策ソフトの影響が疑われます", C_MUTED)
						else:
							_add_text("✓ 記録用フォルダに書き込めます", C_OK)
			_add_text("　 保存先: %s" % probe_dir, C_MUTED)

	# --- 4) 実際に溜まっている件数 (ファイル名を数えるだけ = 1 ファイルも開かない) ---
	_add_text("")
	_add_text("これまでに保存された記録:", C_TEXT)
	_add_counts_for(ResponsesWriter.CATEGORY_PLAY_RECORDS, "プレイ記録")
	_add_counts_for(ResponsesWriter.CATEGORY_SURVEYS, "アンケート")

	# --- 5) 書き込みの失敗 ---
	# **判定の根拠は ResponsesWriter のカウンタで、ログではない。** ログの保持は 400 行の
	# リングバッファなので、来場者が回った日の夕方には朝の失敗が押し出されて消える。それを根拠に
	# 「エラーはありません」と出すと、この画面が一番やってはいけない「嘘の ✓」になる
	# (同じ画面で v23 DB の query 失敗を 0 件と読んでいた silent pass と同種)。カウンタは溢れない。
	_add_text("")
	var fails: int = ResponsesWriter.write_fail_count
	if fails == 0:
		_add_text("✓ 今回の起動以降、記録の書き込みに失敗はありません (成功 %d 件)"
			% ResponsesWriter.write_ok_count, C_OK)
	else:
		_add_text("✗ 今回の起動以降、記録の書き込みに %d 件失敗しています (成功 %d 件)"
			% [fails, ResponsesWriter.write_ok_count], C_DANGER)
		_add_text("　 最後の失敗: %s" % ResponsesWriter.last_write_error, C_MUTED)
		_add_text("　 → 上の「記録用フォルダに書き込めます」も確認してください。共有が切れている / 空き容量が無い可能性があります。", C_MUTED)
	# ログ由来の行は補助表示。カウンタが 0 でもここに何か出ることがある (書き込み以外の警告)。
	var errors := _recent_record_warnings()
	if not errors.is_empty():
		_add_text("　 参考 (直近のログ、古い行は流れます):", C_MUTED)
		for line in errors:
			_add_text("　 %s" % line, C_MUTED)

	_add_text("")
	_add_button("再確認", func(): _build_detail("records_check"); _refocus_detail())


## 番号の再利用が起きうる状態かを、`settings.game_no_seq` と実際の記録の突き合わせで見る。
##
## 検出したいのは「DB だけ過去に巻き戻った」状態。復元やリセットで seq が下がっても、
## `responses/` の記録は消えないので **記録が参照している番号 > seq** という食い違いが残る。
## これを見れば、次にゲームを追加したときに番号を踏むことを**開場前に**知れる。
## (Manager 側も走査失敗時に警告を出すが、それは Manager のログにしか出ず、スタッフが朝見るのは
##  この画面なので、ここでも判定する。)
func _add_number_reuse_check(dbm) -> void:
	var seq := -1
	if dbm.db.query("SELECT value FROM settings WHERE key = 'game_no_seq'"):
		# 型を明示する: get_query_result() は無型なので `:=` では推論できない (Parse Error)。
		var r: Array = dbm.db.get_query_result()
		if r and r.size() > 0:
			seq = int(str(r[0].get("value", "0")))
	var max_in_db := -1
	if dbm.db.query("SELECT COALESCE(MAX(game_no), 0) AS m FROM games"):
		var r2: Array = dbm.db.get_query_result()
		if r2 and r2.size() > 0:
			max_in_db = int(r2[0].get("m", 0))
	if seq < 0 or max_in_db < 0:
		_add_text("? 番号の採番状態を確認できませんでした（読み取りに失敗）", C_MUTED)
		return

	var max_in_records := _max_game_no_in_records()
	if max_in_records > seq:
		_add_text("✗ 記録が使っている番号 (no.%d) が、次の採番位置 (no.%d) より進んでいます" % [max_in_records, seq], C_DANGER)
		_add_text("　 バックアップから古いデータベースを復元した可能性があります。このまま", C_MUTED)
		_add_text("　 ゲームを追加すると、過去の記録と結び付きが入れ替わります", C_MUTED)
		_add_text("　 対処: 開発者に連絡してください（記録は消えていません）", C_MUTED)
	elif seq < max_in_db:
		_add_text("✗ 採番位置 (no.%d) が、実際に使われている最大番号 (no.%d) より小さいです" % [seq, max_in_db], C_DANGER)
		_add_text("　 対処: 開発者に連絡してください", C_MUTED)
	else:
		_add_text("✓ 番号の重複は起きません（次の採番: no.%d）" % (seq + 1), C_OK)


## `responses/` の記録ファイル名から、参照されている最大の game_no を読む。
## **ファイル名だけ**を見る (`<unix_ts>-<game_no>-<uuid>.json`) ので 1 ファイルも開かない。
## 旧形式や `.tmp` は分割数が合わないので自然に 0 として無視される。
func _max_game_no_in_records() -> int:
	var base_dir := PathManager.get_base_directory()
	if base_dir.is_empty():
		return 0
	var max_no := 0
	for category in [ResponsesWriter.CATEGORY_PLAY_RECORDS, ResponsesWriter.CATEGORY_SURVEYS]:
		var dir := base_dir.path_join(ResponsesWriter.RESPONSES_DIRNAME).path_join(category)
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for d in DirAccess.get_directories_at(dir):
			for fn in DirAccess.get_files_at(dir.path_join(d)):
				if not fn.ends_with(".json"):
					continue
				var parts := fn.split("-")
				if parts.size() < 3:
					continue
				var no := int(parts[1])
				if no > max_no:
					max_no = no
	return max_no


## 指定 category の日付フォルダごとの件数を、新しい日付から順に出す。
## ファイル名を数えるだけで中身は開かない (ファイル名が `<unix_ts>-<game_no>-<uuid>.json` なので
## 件数も時刻も名前から分かる。本番は SMB なので「開く回数 = ネットワーク往復」= ここが効く)。
func _add_counts_for(category: String, label: String) -> void:
	var base_dir := PathManager.get_base_directory()
	if base_dir.is_empty():
		return
	var dir := base_dir.path_join(ResponsesWriter.RESPONSES_DIRNAME).path_join(category)
	if not DirAccess.dir_exists_absolute(dir):
		_add_text("　 %s: まだ 1 件もありません" % label, C_MUTED)
		return

	var days := DirAccess.get_directories_at(dir)
	days.sort()
	days.reverse()  # 新しい日付が先頭 (名前が YYYY-MM-DD なので辞書順 = 時系列)
	if days.is_empty():
		_add_text("　 %s: まだ 1 件もありません" % label, C_MUTED)
		return

	var today := ResponsesWriter.date_folder(int(Time.get_unix_time_from_system()))
	var shown := 0
	for d in days:
		if shown >= 3:
			break
		var count := 0
		var newest_ts := 0
		for fn in DirAccess.get_files_at(dir.path_join(d)):
			if not fn.ends_with(".json"):
				continue
			count += 1
			var ts := int(fn.split("-")[0])
			if ts > newest_ts:
				newest_ts = ts
		var suffix := ""
		if newest_ts > 0:
			var dt := Time.get_datetime_dict_from_unix_time(newest_ts + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
			suffix = "（最後 %02d:%02d）" % [int(dt.get("hour", 0)), int(dt.get("minute", 0))]
		var is_today := (d == today)
		_add_text("　 %s %s: %d 件 %s%s" % [label, d, count, suffix, "  ← 今日" if is_today else ""],
			C_OK if is_today and count > 0 else C_TEXT)
		shown += 1

	if not days.has(today):
		_add_text("　 %s: 今日はまだ 0 件です" % label, C_MUTED)


## 直近ログから記録の書き込みに関する警告だけを拾う (最大 5 件、新しい順)。
## 記録に関する WARN / ERROR を新しい順に最大 5 件返す。**あくまで補助表示**。
##
## Logger が持っているのは 400 行のメモリ上リングバッファなので、(a) 前回の起動で出たエラーは
## 見えず、(b) **同じ起動の中でも古い行は押し出されて消える**。したがって「0 件だからエラーが
## 無かった」とは言えない。成否の判定は `ResponsesWriter` のカウンタで行い、ここは
## 「何が起きたか」の手掛かりを添えるためだけに使うこと (レビュー Medium-2)。
func _recent_record_warnings() -> Array[String]:
	var out: Array[String] = []
	var logger = get_node_or_null("/root/Logger")
	if logger == null or not logger.has_method("get_recent_logs"):
		return out
	var lines: Array = logger.get_recent_logs()
	for i in range(lines.size() - 1, -1, -1):
		var line := str(lines[i])
		if not (line.contains("WARN") or line.contains("ERROR")):
			continue
		if line.contains("ResponsesWriter") or line.contains("PlayRecordWriter") or line.contains("SurveyWriter"):
			out.append(line.strip_edges())
			if out.size() >= 5:
				break
	return out


func _build_db_check() -> void:
	var db_path := PathManager.get_database_path()
	if not FileAccess.file_exists(db_path):
		_add_text("✗ DB ファイルが見つかりません: %s" % db_path, C_DANGER)
		_add_text("Manager での初期化が必要です。", C_MUTED)
		return
	_add_text("✓ DB ファイル: %s" % db_path, C_OK)

	var dbm := DatabaseManager.new()
	if not dbm.open():
		_add_text("✗ DB に接続できませんでした。", C_DANGER)
		return
	_add_text("✓ DB 接続 OK（読み取りテスト成功）", C_OK)

	# バージョン
	dbm.db.query("PRAGMA user_version")
	var vres := dbm.db.get_query_result()
	var ver := 0
	if vres and vres.size() > 0:
		ver = int(vres[0].get("user_version", 0))
	_add_text("DB バージョン (user_version): %d  /  Launcher 期待: %d" % [ver, DatabaseManager.CURRENT_DB_VERSION],
		C_OK if ver == DatabaseManager.CURRENT_DB_VERSION else C_MUTED)
	if ver > DatabaseManager.CURRENT_DB_VERSION:
		_add_text("  → DB が Launcher より新しい (Manager が先行更新。通常は無害)", C_MUTED)
	elif ver != 0 and ver < DatabaseManager.CURRENT_DB_VERSION:
		_add_text("  → DB が古い。Manager で更新してください", C_DANGER)

	# テーブル一覧
	dbm.db.query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
	var trows := dbm.db.get_query_result()
	var names: Array[String] = []
	if trows:
		for r in trows:
			names.append(str(r.get("name", "")))

	# 主要テーブルの存在
	for req in ["games", "developers", "store_sections"]:
		_add_text(("✓ テーブル %s あり" % req) if req in names else ("✗ 必須テーブル %s が見つかりません" % req),
			C_OK if req in names else C_DANGER)

	_add_text("テーブル別レコード数:", C_TEXT)
	var list := ItemList.new()
	list.focus_mode = Control.FOCUS_ALL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 280)
	for n in names:
		dbm.db.query('SELECT COUNT(*) AS c FROM "%s"' % n)
		var cres := dbm.db.get_query_result()
		var cnt := -1
		if cres and cres.size() > 0:
			cnt = int(cres[0].get("c", 0))
		list.add_item("%s: %s" % [n, "%d 件" % cnt if cnt >= 0 else "読み取り失敗"])
	_detail_content.add_child(list)
	dbm.close()


## 音声チェック: 正弦波のテスト音を生成して再生し、音声出力が機能しているかを確認する。
## (音声ファイルを持たないので毎回その場で作る。音量調整は今後ここに追加予定。)
func _build_audio_check() -> void:
	_add_text("テスト音を再生して音声出力を確認します。音が出ない問題の切り分け用。", C_TEXT)
	_add_button("テスト音を再生 (880Hz / 0.6秒)", _play_test_tone)
	_add_text("音が聞こえない場合: スピーカー/ヘッドホン接続、OS のミュート/音量、出力デバイスを確認してください。", C_MUTED)
	_add_text("（音量調整は今後ここにも追加予定）", C_MUTED)


func _play_test_tone() -> void:
	if _audio_player == null:
		# overlay (PROCESS_MODE_ALWAYS) 配下に置くので、サービスモードの tree pause 中でも再生される。
		_audio_player = AudioStreamPlayer.new()
		add_child(_audio_player)
	if _test_tone == null:
		_test_tone = _generate_tone(880.0, 0.6)
	_audio_player.stream = _test_tone
	_audio_player.play()


## 指定周波数・長さの 16bit モノラル正弦波を生成する (端は短くフェードしてクリック音を防ぐ)。
func _generate_tone(freq: float, dur: float) -> AudioStreamWAV:
	var rate := 44100
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var env := minf(1.0, minf(t / 0.02, (dur - t) / 0.02))  # 立ち上がり/終わりをフェード
		var s := sin(TAU * freq * t) * env * 0.6
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _build_screen_test() -> void:
	_add_text("テスト用の表示を全画面で順番に出します。モニター相性・色・スケーリングの確認用。")
	_add_text("開始すると次の順で表示します:", C_MUTED)
	var names: Array[String] = []
	for p in SCREEN_SEQ:
		names.append(str(p["label"]))
	_add_text("　" + " → ".join(names), C_MUTED)
	_add_text("次へ: 任意のキー / クリック / パッドボタン　　戻る: ← / Backspace　　中断: Esc / B", C_MUTED)
	_add_button("テストを開始（順番に表示）", _start_screen_seq)


func _build_debug_overlay() -> void:
	var on: bool = DebugOverlay.is_enabled()
	_add_text("画面左上に FPS・メモリ・PC名・シーン状態・DB接続などを常時表示します。")
	_add_text("現在: %s" % ("ON" if on else "OFF"), C_OK if on else C_MUTED)
	_add_text("サービスモードを閉じても表示し続けます。再起動でOFFに戻ります。", C_MUTED)
	_add_button("デバッグオーバーレイを %s" % ("OFF にする" if on else "ON にする"),
		func(): DebugOverlay.toggle(); _build_detail("debug_overlay"); _refocus_detail())


func _build_fullscreen() -> void:
	_add_text("現在: %s" % ("フルスクリーン" if _is_fullscreen() else "ウィンドウ"))
	_add_text("モニター違いでの表示崩れ対応用。再起動で起動時の設定 (フルスクリーン) に戻ります。", C_MUTED)
	_add_button("フルスクリーン ⇔ ウィンドウ を切り替え", _toggle_fullscreen)


func _build_monitor() -> void:
	var cur := get_window().current_screen
	_add_text("現在のモニタ: #%d" % cur)
	_add_text("複数モニタ環境用。この変更は一時的で、再起動でプライマリに戻ります。", C_MUTED)
	for i in range(DisplayServer.get_screen_count()):
		var sz := DisplayServer.screen_get_size(i)
		var label := "モニタ #%d  (%dx%d)%s" % [i, sz.x, sz.y, "  ← 現在" if i == cur else ""]
		_add_button(label, _set_monitor.bind(i))


func _build_reload() -> void:
	_add_text("DB を再読み込みして現在の画面を作り直します (再起動より軽い)。")
	if GameSession.is_running():
		_add_text("⚠ ゲーム実行中のため再読み込みできません。", C_DANGER)
	else:
		_add_button("ランチャーを再読み込み", _do_reload)


func _build_restart() -> void:
	_add_text("ランチャーを OS プロセスとして再起動します。")
	if GameSession.is_running():
		_add_text("⚠ ゲーム実行中のため再起動できません。", C_DANGER)
	else:
		_add_button("ランチャーを再起動", _do_restart)


func _build_exit() -> void:
	if GameSession.is_running():
		_add_text("⚠ ゲーム実行中のため終了できません (先にゲームを終了してください)。", C_DANGER)
		return
	# サービスモード自体が隠し画面 (Ctrl+Alt+F12) で、ここまで辿り着く操作自体が十分に意図的なため、
	# 押したら即終了する (二段階確認は廃止)。通常は Alt+F4 / × を無効化しているのでここから終了する。
	_add_text("ランチャーを終了します。Alt+F4 や × ボタンは無効にしてあるため、終了はこのボタンから行います。")
	var btn := _add_button("ランチャーを終了", func(): cleanup_for_quit(); get_tree().quit())
	_set_button_font_color(btn, C_DANGER)


# 未知の id 用の防御的フォールバック (通常 ITEMS の id は全て match で処理されるため到達しない)。
func _build_stub() -> void:
	_add_text("不明な項目です。", C_MUTED)


# ---------------- アクション ----------------

## 全画面テスト表示の描画ノードを用意する (初回のみ生成)。CanvasLayer 直下に置くので
## サービスモード UI より後 = 最前面に出る。描画内容は _draw_test が _test_mode を見て決める。
func _ensure_test_canvas() -> void:
	if _test_canvas != null:
		return
	_test_canvas = Control.new()
	_test_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_test_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_test_canvas.theme = _theme  # draw_string のキャプションも Noto Sans JP で描く
	_test_canvas.draw.connect(_draw_test)
	add_child(_test_canvas)


## 画面表示テストを先頭パターンから開始する。
func _start_screen_seq() -> void:
	_seq_index = 0
	_show_seq_current()


## 現在の _seq_index のパターンを全画面表示する。
func _show_seq_current() -> void:
	_ensure_test_canvas()
	var p: Dictionary = SCREEN_SEQ[_seq_index]
	_test_mode = str(p["mode"])
	_test_color = p["color"]
	_test_canvas.visible = true
	_test_canvas.queue_redraw()
	_test_active = true


## 次のパターンへ送る。最後まで行ったらテストを終了してメニューへ戻る。
func _advance_screen_seq() -> void:
	_seq_index += 1
	if _seq_index >= SCREEN_SEQ.size():
		_hide_test()
	else:
		_show_seq_current()


## 前のパターンへ戻る (← / Backspace)。先頭では何もしない。
func _retreat_screen_seq() -> void:
	if _seq_index <= 0:
		return
	_seq_index -= 1
	_show_seq_current()


func _hide_test() -> void:
	if _test_canvas:
		_test_canvas.visible = false
	_test_active = false
	_refocus_detail()  # メニューに戻った時、開始ボタンへフォーカスを戻す


## 全画面テストの実描画。_test_canvas の draw シグナルから呼ばれる。画面サイズに追従するので
## どの解像度・モニタでもくっきり描ける (画像アセット不要)。
func _draw_test() -> void:
	var size := _test_canvas.size
	match _test_mode:
		"grid": _draw_test_grid(size)
		"colorbar": _draw_test_colorbar(size)
		"resolution": _draw_test_resolution(size)
		_: _test_canvas.draw_rect(Rect2(Vector2.ZERO, size), _test_color)


## ジオメトリ/クロスハッチ: 放送のモニタ調整パターン風。クロスハッチ (細密+粗) + 四隅対角線 +
## 中央&四隅の真円 (画素アスペクト/歪みの確認: 真円が楕円に見えたら縦横比がおかしい) + 中央十字 +
## セーフエリア枠 (90% / 80%)。解像度・拡大率・歪み・端の見切れをまとめて確認する。
func _draw_test_grid(size: Vector2) -> void:
	var cv := _test_canvas
	cv.draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var center := size * 0.5
	# クロスハッチ: 細密 (32px) を淡く、粗 (128px) を濃く 2 段で描く
	_draw_grid_lines(size, 32.0, Color(0.16, 0.16, 0.16))
	_draw_grid_lines(size, 128.0, Color(0.42, 0.42, 0.42))
	# 四隅対角線 (中心ずれ・台形歪みの確認)
	var diag := Color(0.25, 0.25, 0.25)
	cv.draw_line(Vector2.ZERO, size, diag, 1.0)
	cv.draw_line(Vector2(size.x, 0), Vector2(0, size.y), diag, 1.0)
	# 真円群 (画素アスペクト・幾何歪みの確認)。半径は短辺基準で等倍 → 正しければ真円に見える
	var unit := minf(size.x, size.y)
	var circ := Color(0.55, 0.55, 0.55)
	cv.draw_arc(center, unit * 0.46, 0, TAU, 128, circ, 1.5)
	cv.draw_arc(center, unit * 0.30, 0, TAU, 96, circ, 1.5)
	var r_corner := unit * 0.12
	for cpt in [Vector2(r_corner, r_corner), Vector2(size.x - r_corner, r_corner),
			Vector2(r_corner, size.y - r_corner), Vector2(size.x - r_corner, size.y - r_corner)]:
		cv.draw_arc(cpt, r_corner, 0, TAU, 48, circ, 1.5)
	# 中央十字 + 中央点
	cv.draw_line(Vector2(center.x, 0), Vector2(center.x, size.y), C_ACCENT, 2.0)
	cv.draw_line(Vector2(0, center.y), Vector2(size.x, center.y), C_ACCENT, 2.0)
	cv.draw_circle(center, 4.0, C_ACCENT)
	# セーフエリア枠
	_draw_safe_frame(size, 0.90, Color(0.95, 0.85, 0.30), "90%")
	_draw_safe_frame(size, 0.80, Color(0.95, 0.55, 0.25), "80%")


## 指定間隔の縦横グリッド線を描く。
func _draw_grid_lines(size: Vector2, step: float, color: Color) -> void:
	var x := step
	while x < size.x:
		_test_canvas.draw_line(Vector2(x, 0), Vector2(x, size.y), color, 1.0)
		x += step
	var y := step
	while y < size.y:
		_test_canvas.draw_line(Vector2(0, y), Vector2(size.x, y), color, 1.0)
		y += step


func _draw_safe_frame(size: Vector2, ratio: float, color: Color, label: String) -> void:
	var inset := size * (1.0 - ratio) * 0.5
	var rect := Rect2(inset, size - inset * 2.0)
	_test_canvas.draw_rect(rect, color, false, 2.0)
	var font: Font = _test_canvas.get_theme_default_font()
	_test_canvas.draw_string(font, rect.position + Vector2(8, 22), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)


## カラーバー: 放送規格 (SMPTE RP 219 / ARIB) の HD カラーバー。色再現・色順・黒レベルの確認用。
## 4 段構成: 上=75% カラーバー + 両端 40% グレー袖 (7/12) / リバース (1/12) / ランプ (1/12) /
## PLUGE = 黒レベル調整 (3/12)。横幅 a=画面幅、中央帯 x=3/4a を 7 列 (各 c=x/7) に分ける。
func _draw_test_colorbar(size: Vector2) -> void:
	var cv := _test_canvas
	var a := size.x
	var y := size.y
	var side := a / 8.0          # 両端の袖幅 (a/8)
	var x := a * 3.0 / 4.0       # 中央のカラー帯領域 (3/4 a)
	var c := x / 7.0             # 1 列の幅 (x/7)
	var r1 := y * 7.0 / 12.0     # 上段 (カラーバー) 高さ
	var r2 := y / 12.0           # リバース段
	var r3 := y / 12.0           # ランプ段
	var y2 := r1
	var y3 := r1 + r2
	var y4 := r1 + r2 + r3
	var r4 := y - y4             # PLUGE 段 (3/12)
	var W75 := Color(0.75, 0.75, 0.75)
	var W40 := Color(0.40, 0.40, 0.40)
	cv.draw_rect(Rect2(0, 0, a, y), Color.BLACK)

	# 上段: 左袖 40%W + 75% 7色 (白黄シアン緑マゼンタ赤青) + 右袖 40%W
	cv.draw_rect(Rect2(0, 0, side, r1), W40)
	var cols := [W75, Color(0.75, 0.75, 0), Color(0, 0.75, 0.75), Color(0, 0.75, 0),
		Color(0.75, 0, 0.75), Color(0.75, 0, 0), Color(0, 0, 0.75)]
	for i in range(7):
		cv.draw_rect(Rect2(side + c * i, 0, c + 1.0, r1), cols[i])
	cv.draw_rect(Rect2(side + x, 0, side, r1), W40)

	# リバース段: 100%Cy | 100%W(1列) | 75%W(6列) | 100%B
	cv.draw_rect(Rect2(0, y2, side, r2), Color(0, 1, 1))
	cv.draw_rect(Rect2(side, y2, c, r2), Color.WHITE)
	cv.draw_rect(Rect2(side + c, y2, c * 6.0, r2), W75)
	cv.draw_rect(Rect2(side + x, y2, side, r2), Color(0, 0, 1))

	# ランプ段: 100%Y | 0→100% 黒白ランプ | 100%R
	cv.draw_rect(Rect2(0, y3, side, r3), Color(1, 1, 0))
	var steps := 128
	var sw := x / steps
	for i in range(steps):
		var v := float(i) / (steps - 1)
		cv.draw_rect(Rect2(side + sw * i, y3, sw + 1.0, r3), Color(v, v, v))
	cv.draw_rect(Rect2(side + x, y3, side, r3), Color(1, 0, 0))

	# PLUGE 段: 両袖 15%W。中央は Bk(1.5c) | 100%W(2c) | 黒地 + PLUGE(-2/0/+2/0/+4%) | Bk(1c)
	cv.draw_rect(Rect2(0, y4, side, r4), Color(0.15, 0.15, 0.15))
	cv.draw_rect(Rect2(side, y4, c * 1.5, r4), Color.BLACK)
	cv.draw_rect(Rect2(side + c * 1.5, y4, c * 2.0, r4), Color.WHITE)
	var p := c / 3.0             # PLUGE 各バー幅 (x/21)
	var px := side + c * 3.5 + c * (5.0 / 6.0)  # 黒地のフィラーぶん右へ寄せる
	var pluge := [Color.BLACK, Color.BLACK, Color(0.02, 0.02, 0.02),
		Color.BLACK, Color(0.04, 0.04, 0.04)]
	for pc in pluge:
		cv.draw_rect(Rect2(px, y4, p, r4), pc)
		px += p
	cv.draw_rect(Rect2(side + x, y4, side, r4), Color(0.15, 0.15, 0.15))


## 解像度 + グレースケール: 中央にシーメンススター (放射状の白黒くさび、中心ほど線が細くなる)、
## 上部に周波数縞 (1〜4px ピッチの細線パッチ)、下部に離散グレースケール段 (11 段)。
## シャープネス・スケーリングのボケ/モアレ (native 表示か) とガンマ/階調段差の確認用。
func _draw_test_resolution(size: Vector2) -> void:
	var cv := _test_canvas
	cv.draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	# 上部: 周波数縞 (縦線) を 1/2/3/4px ピッチで 4 パッチ。中央寄せでキャプション(左上)を避ける
	var pw := size.x * 0.16
	var ph := size.y * 0.13
	var gap := size.x * 0.02
	var total := pw * 4 + gap * 3
	var sx := (size.x - total) * 0.5
	var py := size.y * 0.06
	for k in range(4):
		var pitch := k + 1
		var rx := sx + (pw + gap) * k
		var on := true
		var lx := rx
		while lx < rx + pw:
			if on:
				cv.draw_rect(Rect2(lx, py, float(pitch), ph), Color.WHITE)
			on = not on
			lx += pitch
		cv.draw_rect(Rect2(rx, py, pw, ph), Color(0.5, 0.5, 0.5), false, 1.0)
	# 中央: シーメンススター (白黒のくさび。中心へ向かうほど線が密集 = 解像度限界やモアレが見える)
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius := minf(size.x, size.y) * 0.30
	var wedges := 72
	for i in range(wedges):
		var a0 := TAU * (2 * i) / float(2 * wedges)
		var a1 := TAU * (2 * i + 1) / float(2 * wedges)
		var tri := PackedVector2Array([center,
			center + Vector2(cos(a0), sin(a0)) * radius,
			center + Vector2(cos(a1), sin(a1)) * radius])
		cv.draw_colored_polygon(tri, Color.WHITE)
	cv.draw_arc(center, radius, 0, TAU, 128, Color(0.5, 0.5, 0.5), 1.0)
	# 下部: 離散グレースケール段 (11 段、黒→白)。ガンマ・階調段差の確認
	var seg := 11
	var bw := size.x / seg
	var bh := size.y * 0.15
	var by := size.y - bh
	for i in range(seg):
		var v := float(i) / (seg - 1)
		cv.draw_rect(Rect2(bw * i, by, bw + 1.0, bh), Color(v, v, v))


func _is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if _is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_build_detail("fullscreen")
	_refocus_detail()


func _set_monitor(index: int) -> void:
	get_window().current_screen = index
	_build_detail("monitor")
	_refocus_detail()


func _do_reload() -> void:
	if GameSession.is_running():
		return
	ServiceMode.close()
	get_tree().reload_current_scene()


func _do_restart() -> void:
	if GameSession.is_running():
		return
	OS.create_process(OS.get_executable_path(), [])
	get_tree().quit()


# ---------------- UI ヘルパー ----------------

## 入力デバイス変更時にフォーカス枠の表示/非表示を全ボタンへ反映する。
func _set_using_mouse(v: bool) -> void:
	if _using_mouse == v:
		return
	_using_mouse = v
	_apply_focus_style()
	# 入力が切り替わったら、ゲーム動作テストの説明も「今表示されている方の指標」で出し直す
	# (キーボード時=フォーカス / マウス時=ホバー)。
	_update_games_test_desc()


## 現在の _using_mouse に応じて 1 ボタンの focus / hover スタイルを切り替える。
## キーボード・パッド操作中はマウスホバーのハイライトも消す: カーソルを隠してもマウスは物理的に
## ボタンの上に残るため、そのままだとホバー表示が消え残り、キーボードのフォーカス枠と二重に光って
## 見える。ホバーを通常表示と同じにすることで、残ったホバーを見えなくする。
func _apply_focus_style_to(b: Button) -> void:
	# 色付きボタン (詳細ペイン) はマウス時に専用ホバー、プレーンボタン (左メニュー) は既定ホバーに戻す。
	var colored := b.has_theme_stylebox_override("normal")
	if _using_mouse:
		b.add_theme_stylebox_override("focus", _focus_off_sb)
		if colored:
			b.add_theme_stylebox_override("hover", _btn_hover_sb)
		else:
			b.remove_theme_stylebox_override("hover")
	else:
		b.add_theme_stylebox_override("focus", _focus_sb)
		b.add_theme_stylebox_override("hover", b.get_theme_stylebox("normal"))


## メニュー + 詳細 + モーダルの全ボタンに現在のフォーカス枠スタイルを適用する。
## (#311) モーダルのボタンも対象にする: 従来はモーダルが対象外で、マウス操作中にモーダルを開いてから
## キー/パッドへ切り替えるとフォーカス枠が透明のまま残り、フォーカスがどこにあるか見えず
## 「キーボード/コントローラーで操作できない」ように見えていた。
func _apply_focus_style() -> void:
	for b in _menu_buttons:
		_apply_focus_style_to(b)
	if _detail_content:
		for c in _detail_content.get_children():
			if c is Button:
				_apply_focus_style_to(c)
	if _modal_btnbox:
		for c in _modal_btnbox.get_children():
			if c is Button:
				_apply_focus_style_to(c)


func _clear_content() -> void:
	_sysinfo_list = null  # 詳細を作り直すのでシステム情報のリアルタイム更新対象も解除
	_ic_connected_label = null  # 入力チェックのライブ更新対象も解除
	_ic_last_label = null
	_nw_cancel = true     # ネットワークテスト中に画面を離れたらワーカーを次の段階境界で止める
	# 速度結果待ち中 (= ワーカースレッドは join 済み) に離脱したら run state を解放しておく。
	# そうしないと戻った時 _nw_running が true のまま残り、新ボタンを押しても最大 NW_SPEED_TIMEOUT_SEC 秒
	# サイレント無反応になる。疎通フェーズ中 (thread 実行中, pending=0) は触らず cancel + _nw_done に任せる。
	if _nw_speed_pending > 0:
		_nw_running = false
		_nw_speed_pending = 0
	_nw_rows = {}         # 解放されるラベルへの参照を捨てる (worker の _nw_set は has() で空振りする)
	_nw_run_btn = null
	_lt_stop()            # 起動テスト実行中なら止める (画面を離れるのでゲームを置き去りにしない)
	_pt_stop()            # 試遊中なら止める (同上)
	# remove_child を即時に行ってから queue_free する。queue_free だけだとフレーム末まで子が get_children に
	# 残り、直後の _first_focusable が「解放予定の古いボタン」を掴んでフォーカスを当て、フレーム末に消えて
	# フォーカス喪失で詰む (詳細を作り直す系の操作でキーボードフォーカスが出ない不具合)。
	for c in _detail_content.get_children():
		_detail_content.remove_child(c)
		c.queue_free()


func _add_text(text: String, color: Color = C_TEXT) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.add_child(l)


func _add_button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 40)
	# 薄く色を付けて「押せる項目」だと分かりやすくする (通常/押下)。ホバー/フォーカスは _apply_focus_style_to。
	b.add_theme_stylebox_override("normal", _btn_sb)
	b.add_theme_stylebox_override("pressed", _btn_hover_sb)
	b.pressed.connect(on_pressed)
	_detail_content.add_child(b)
	_apply_focus_style_to(b)  # ツリー追加後に呼ぶ (get_theme_stylebox がテーマを正しく解決するため)
	return b


## ボタンの文字色を全状態 (通常/フォーカス/ホバー/押下) に適用する。font_color だけ上書きすると
## フォーカス時に既定の font_focus_color (白系) が使われて色が変わってしまうため、全状態を揃える。
func _set_button_font_color(b: Button, color: Color) -> void:
	for state in ["font_color", "font_focus_color", "font_hover_color",
			"font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, color)


## 詳細を作り直した後、詳細ペインに居るなら先頭の操作可能 control へフォーカスを戻す。
func _refocus_detail() -> void:
	if not _in_detail:
		return
	var first := _first_focusable(_detail_content)
	if first:
		first.grab_focus()
	else:
		_in_detail = false
		_exit_detail()


func _first_focusable(node: Node) -> Control:
	for c in node.get_children():
		if c is Control and (c as Control).focus_mode != Control.FOCUS_NONE:
			return c
	return null


## 詳細ペイン内の上下フォーカス移動を詰める。先頭の操作項目で↑、末尾で↓を押しても
## 左の項目一覧 (外側) へフォーカスが逃げないよう、上下の neighbor を自分自身に向ける
## (Godot の自動 neighbor が幾何的に左リストを拾って選択が変わるのを防ぐ)。
## 詳細から一覧へ戻るのは ← / B / Esc に一本化する。
func _constrain_detail_focus() -> void:
	# サブツリー全体を再帰的に走査する。スクロール枠等にネストしたフォーカス対象 (起動テストの
	# チェックボックス等) も拾わないと、直下の最後のボタンの下方向が自分自身に固定され、
	# ネストした項目へ降りられなくなる。
	var focusables: Array[Control] = []
	_collect_focusables(_detail_content, focusables)
	if focusables.is_empty():
		return
	focusables[0].focus_neighbor_top = focusables[0].get_path()
	focusables[-1].focus_neighbor_bottom = focusables[-1].get_path()


## node 以下のフォーカス可能 Control を、表示順 (深さ優先・子の順) で集める。
func _collect_focusables(node: Node, out: Array[Control]) -> void:
	for c in node.get_children():
		if c is Control and (c as Control).focus_mode != Control.FOCUS_NONE:
			out.append(c)
		_collect_focusables(c, out)
