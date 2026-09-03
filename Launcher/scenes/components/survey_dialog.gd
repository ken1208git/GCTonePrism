## (#297 PR3 / #35) 来場者向けアンケート画面。★1〜5 ＋ 折りたたみ式の自由記述。
##
## ゲーム終了時 (ゲーム個別) と退出時 (全体) の両方で使う、条件表示を持つ再利用ノードツリーなので
## `.tscn` で持つ (AGENTS.md「UI 実装と分割方針」軸1)。見た目は `common_dialog.tscn` に合わせてあり、
## 来場者から見て「いつものダイアログ」の一種に見えるようにしている。
##
## **どのゲームの評価かを取り違えさせない**のが設計上の要点。ゲーム終了時は `playing` シーンが背面に
## 残っており、そこには**そのゲームの背景画像と大きなサムネイル**が既に表示されている。本ダイアログは
## その上に重なるので、サムネイル (視覚) + [member SubjectLabel] のゲーム名 (文字) の二重で対象を示す。
##
## **スキップは保存しない** (SPEC §機能10)。強制すると評価の質が下がるので明示的な「答えない」を置く。
## 未評価のまま「送る」は押せない (★ を選ぶまで無効) — 空の回答は集計を汚すだけなので。
##
## **自由記述は折りたたみ**。常時出すと画面が重く見えて★だけ押したい人の摩擦になるため、
## 「感想を書く」を選んだ人にだけ展開する。入力は展示 PC の物理キーボード。
##
## **log output 規約**: `LogBridge.info / warn` を使う (AGENTS.md「Cross-component Standards」)。
## 組み込み `Logger` クラスとの名前衝突で `Logger.info()` と直接は書けないが、**呼べないわけではない**
## (`LogBridge` が `/root/Logger` を解決する)。標準の出力関数はレベル指定ができない。

extends Control
class_name SurveyDialog

## 回答が確定した (★を選んで「送る」を押した)。comment は未入力なら null。
signal submitted(rating: int, comment)
## スキップされた (「答えない」/ ESC)。保存はしない。
signal skipped()
## 無操作で時間切れになった。保存はしない。**スキップとは分けてある** — スキップは「人がいて断った」、
## こちらは「人がいない」なので、後続の行き先が違う (SurveyFlow がタイトル画面へ戻す)。
signal timed_out()

const STAR_COUNT: int = 5
const COMMENT_MAX_LENGTH: int = 200  # SurveyWriter.COMMENT_MAX_LENGTH と対。UI 側でも入力を止める

## 無操作で自動的に閉じるまでの時間。**キオスクが復帰不能にならないための保険** (レビュー C-1)。
## アンケート表示中は背後のシーンを止めているため、来場者が答えずに立ち去るとその台は
## アンケートを出したまま固まり、次の来場者が触れない (アイドル → スクリーンセーバーの経路も
## 止まっている)。開場中に誰も気づかなければ、その台は一日死ぬ。
##
## 予告なく消すと「考えている途中で消えた」になるので 2 段階にする。残り時間を出してから閉じる。
## **意図的な入力 (`InputIntent`) で 0 に戻る**ので、操作している人が巻き込まれることはない。
## 「意図的」の線引きは緩い側に倒してある (1px を超えるマウス移動でも延長される) が、
## スティックのドリフトやキーの echo は数えない — そこを数えると永久に発火しなくなる。
## タイムアウトで閉じた場合は**保存しない** (★を選んだだけで立ち去った回答は意思表示とみなさない)。
##
## **時間は `IdleManager` と共有する**。来場者から見ればアンケート画面も通常画面も同じ「放置」で、
## 台ごと・画面ごとに戻る時間が違う理由が無い。数字を書き写すと、キオスクの放置ポリシーを
## 調整したときに片方だけ古い値のまま残る。
const IDLE_WARN_SECONDS: float = IdleManager.IDLE_WARNING_TIME
const IDLE_CLOSE_SECONDS: float = IdleManager.IDLE_RESET_TIME

## **回答が 1 ミリも進まないまま経った場合の上限** (レビュー High-1 の構造的な受け皿)。
##
## 上の放置タイマーは「入力があればリセット」で成り立っているので、**リセットが効きすぎる故障**
## (スティックドリフト・ボタンの固着・その他まだ知らない何か) が起きると永久に発火しない。
## 意図的入力の判定 (InputIntent) で既知の原因は潰しているが、判定を賢くする方向だけで守ると
## 「判定をすり抜ける新しい入力源」に対して無防備なままになる。判定に依存しない上限が要る。
##
## **ただし基準を「表示からの経過時間」にしてはいけない。** 自由記述 (200 字) を打つのに数分かかる
## 来場者は普通にいるので、書いている最中に問答無用で閉じることになる。
##
## 故障と本物の来場者を分けるのは**入力の有無ではなく、回答が前に進んでいるかどうか**。壊れた入力は
## ★も選ばせないし文字も増やさない。よってこの上限は **★の選択 / 文字の増減があるたびにリセットする**。
## 「入力は来ているのに何も進まない」状態だけを打ち切るので、書いている人は巻き込まれない。
## 眺めているだけの人は先に放置タイマー (90 秒) が拾う。
const NO_PROGRESS_LIMIT_SECONDS: float = 300.0

## 送信後に「ありがとうございます」を見せる時間。画面を増やさず、同じパネルの中身を差し替える。
## 短すぎると読めず、長いと次の人を待たせるので 1 秒弱。
const THANKS_SECONDS: float = 0.8

@onready var _title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var _subject_label: Label = $Panel/MarginContainer/VBoxContainer/SubjectLabel
@onready var _star_row: HBoxContainer = $Panel/MarginContainer/VBoxContainer/StarRow
@onready var _star_template: Button = $Panel/MarginContainer/VBoxContainer/StarRow/StarTemplate
@onready var _rating_hint: Label = $Panel/MarginContainer/VBoxContainer/RatingHintLabel
@onready var _comment_toggle: Button = $Panel/MarginContainer/VBoxContainer/CommentToggleButton
@onready var _comment_section: VBoxContainer = $Panel/MarginContainer/VBoxContainer/CommentSection
@onready var _comment_edit: TextEdit = $Panel/MarginContainer/VBoxContainer/CommentSection/CommentEdit
@onready var _comment_count: Label = $Panel/MarginContainer/VBoxContainer/CommentSection/CommentCountLabel
@onready var _button_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ButtonContainer
@onready var _skip_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SkipButton
@onready var _submit_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SubmitButton
@onready var _focus_border: Panel = $FocusBorder
@onready var _panel: PanelContainer = $Panel

var _stars: Array[Button] = []
var _rating: int = 0          # 0 = 未選択
var _finished: bool = false   # 二重発火防止 (連打・ESC とボタンの競合)
var _mouse_mode: bool = false # マウス操作中はフォーカス枠を出さない (カーソルが位置を示すため)
var _morph: FocusBorderMorph = null
var _idle_seconds: float = 0.0 # 最後の入力からの経過秒 (放置タイムアウト用)
var _no_progress_seconds: float = 0.0 # 回答が進まないまま経った秒 (回答内容が実際に変わったときだけリセット)
var _last_progress_sig: Array = []    # 直近に進捗と認めた回答内容 (★ と本文)
var _hint_base_text: String = "" # 放置警告で上書きする前のヒント文 (入力が来たら戻す)
var _thanking: bool = false   # 送信後の「ありがとうございます」表示中


## マウス操作中だけカーソルを出す (キーボード / パッド操作中は隠す)。
## common_dialog.gd と同じ流儀。キオスクは既定でカーソルを隠しているため、これが無いと
## マウスで操作したい来場者がカーソルを見失う。逆に常時表示にすると、キー操作中に
## 画面の真ん中にカーソルが居座って邪魔になる。
func _input(event: InputEvent) -> void:
	# マウス移動でカーソルを出すのは 1px を超えたときだけ (`input_handler.gd` と同じ作法)。
	# 閾値が無いと、机の振動程度でカーソルが現れてフォーカス枠が消え、「枠は消えたのに★の色だけ
	# 残る」という以前直した見え方が再発する。
	# 型を明示する: `event.relative` は無型なので `:=` では推論できない (Parse Error になる)。
	var mouse_moved: bool = event is InputEventMouseMotion and event.relative.length() > InputIntent.MOUSE_MOTION_THRESHOLD
	if event is InputEventMouseButton or mouse_moved:
		_mouse_mode = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_mouse_mode = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# **カーソル表示の切り替えと放置タイマーのリセットは条件が違う。**
	# 前者は「どちらのデバイスを使っているか」の話なので生のイベント種別で判断してよいが、
	# 後者は「人がいるか」の話なので意図的な入力に限る (InputIntent)。ここを一緒くたにすると、
	# ドリフトするスティックが挿さった台でタイマーが永久にリセットされ続ける (レビュー High-1)。
	if InputIntent.is_intentional(event):
		_reset_idle()


## 放置タイマーを 0 に戻し、出していれば警告表示も畳む。
##
## **呼ばれるのは意図的な入力のときだけ** (`_input` が `InputIntent.is_intentional` で絞る)。
## 「押していないが読んでいる / 書こうとしている」人を切らないよう判定は緩い側に倒してあるが、
## **無条件ではない** — `InputIntent.MOUSE_MOTION_THRESHOLD` (1px) と `AXIS_DEADZONE` (0.5) の
## 外側だけを数える。ここを「何でもリセット」に戻すと、ドリフトするパッドが挿さった台で
## タイマーが永久に発火しなくなる (実際にその実装から直した経緯がある)。
func _reset_idle() -> void:
	_idle_seconds = 0.0
	if _rating_hint and _rating_hint.text != _hint_base_text and not _thanking:
		_rating_hint.text = _hint_base_text


## 「回答が前に進んだ」かを判定してタイマーを戻す。
##
## **呼ばれたことではなく、回答内容が実際に変わったことを見る。** 呼ばれた時点で無条件に戻すと、
## 次の 2 つを進捗と誤認して上限が発火しなくなる — どちらも上限が拾うべき当のケース (レビュー H-2):
## - 決定ボタンのチャタリング / 固着で、同じ★が繰り返し「選ばれる」
## - 本文が既に 200 字に達した状態でキーが押しっぱなしになり、切り戻して同じ本文のまま
##   `text_changed` だけが飛び続ける
##
## 進捗の有無こそが、壊れた入力と本物の来場者を分ける唯一の手掛かりなので、ここは厳しく見る。
func _reset_progress() -> void:
	var sig: Array = [_rating, _comment_edit.text]
	if sig == _last_progress_sig:
		return  # 入力は来たが回答は 1 ミリも動いていない
	_last_progress_sig = sig
	_no_progress_seconds = 0.0


## 共有フォーカス枠を既存ダイアログと同じ動き (対象へ滑らかに移動・拡縮 + ブリージング発光) で
## 追従させる。ロジックは FocusBorderMorph に集約 (common_dialog.gd と同じ見た目にするため)。
func _process(delta: float) -> void:
	if _morph:
		# 編集中は枠を出さない (キャレットが位置を示しているので二重の指示になる)。
		# お礼表示中も出さない (押せるものが無いので枠だけ残ると操作を促してしまう)。
		var hide_border := _mouse_mode or _comment_edit.editable or _thanking
		_morph.update(delta, get_viewport(), _panel, hide_border)
	_tick_idle(delta)


## 放置タイムアウトを進める。詳細は IDLE_WARN_SECONDS のコメントを参照。
func _tick_idle(delta: float) -> void:
	if _finished:
		return
	_idle_seconds += delta
	_no_progress_seconds += delta
	# 進捗が無いままの上限。入力の種類を問わないので、放置タイマーがリセットされ続ける故障でも
	# 必ずここで閉じる。★を選ぶ / 文字を打つとリセットされるため、回答中の人には当たらない。
	if _no_progress_seconds >= NO_PROGRESS_LIMIT_SECONDS:
		LogBridge.warn("[SurveyDialog] 回答が %d 秒進まなかったためアンケートを閉じました (入力は来ていた可能性があります)"
			% int(NO_PROGRESS_LIMIT_SECONDS))
		_finished = true
		timed_out.emit()
		return
	if _idle_seconds < IDLE_WARN_SECONDS:
		return
	if _idle_seconds >= IDLE_CLOSE_SECONDS:
		# 保存はしない。★だけ選んで立ち去った状態を「回答」にすると、自由記述を書こうとして
		# 諦めた人の中途半端な評価まで混ざる。
		LogBridge.info("[SurveyDialog] 無操作 %d 秒でアンケートを閉じました (保存しません)" % int(IDLE_CLOSE_SECONDS))
		_finished = true
		timed_out.emit()
		return
	# **ダイアログは重ねない**。別の確認画面を出すと、この画面と DialogManager の両方が
	# ツリーの停止を持つことになり、片方が先に解除して背面が動き出す (同種の不具合が実際にあった)。
	# 既存のヒント行を書き換えるだけなら、所有者も行数も増えない。
	# 文言は通常のアイドル警告 (IdleManager) と揃える。行き先が同じ (タイトル画面) なので、
	# アンケート中だけ違う言い方をすると「これは別の何かか」と読ませてしまう。
	var remaining := int(ceil(IDLE_CLOSE_SECONDS - _idle_seconds))
	_rating_hint.text = "あと %d 秒でタイトル画面に戻ります　（何か押すと続けられます）" % remaining


func _ready() -> void:
	_build_stars()
	_comment_toggle.pressed.connect(_on_comment_toggle_pressed)
	_comment_edit.text_changed.connect(_on_comment_changed)
	# 入力欄からキーだけで抜ける手段。TextEdit は矢印 (キャレット移動) も Tab (インデント) も
	# 消費するため、focus_neighbor では出られない。gui_input で明示的に捕まえる。
	_comment_edit.gui_input.connect(_on_comment_edit_gui_input)
	# 既定は「フォーカスは当たるが編集はしない」状態。他のボタンと同じ感覚で通り過ぎられる。
	# 決定 (Enter / スペース / パッドの決定) を押して初めて編集に入る。
	_comment_edit.editable = false
	_comment_edit.focus_mode = Control.FOCUS_ALL
	_skip_button.pressed.connect(_on_skip_pressed)
	_submit_button.pressed.connect(_on_submit_pressed)
	# 初期は全消灯にする。ここで塗らないとテーマ既定の文字色のままで「最初から全部点いている」
	# ように見え、未選択であることが伝わらない (プレビュー点灯を撤去したため必須)。
	_paint_stars(0)
	# 放置警告で上書きする前の文言を控えておく (入力が来たらここへ戻す)。
	_hint_base_text = _rating_hint.text
	# 進捗判定の基準を初期状態で確定させる (★未選択・本文空)。
	_last_progress_sig = [_rating, _comment_edit.text]
	_refresh_submit_enabled()
	_wire_focus_neighbors()
	# 共有フォーカス枠の追従対象 (これ以外にフォーカスがあるときは枠を隠す)。
	# TextEdit は対象に含めない: 文字入力中は枠より caret が主役で、枠が出ると二重に見える。
	_morph = FocusBorderMorph.new(_focus_border)
	var focusables: Array = []
	focusables.append_array(_stars)
	focusables.append(_comment_toggle)
	# 入力欄も枠の対象に含める。「フォーカスされているが編集していない」状態を他のボタンと
	# 同じ見た目 (共有枠) で示すため。編集中は枠を出さない (キャレットが位置を示すので二重になる)。
	focusables.append(_comment_edit)
	focusables.append(_skip_button)
	focusables.append(_submit_button)
	_morph.set_targets(focusables)
	# 最初は★の真ん中にフォーカスを置く。左右どちらへも動かしやすく、
	# 「まず★を選ぶ画面」であることが操作前に伝わる。
	_stars[STAR_COUNT / 2].grab_focus()


## 表示内容を設定する。
## title: 見出し / subject: 対象の説明 (ゲーム名。全体アンケートは空文字で行ごと隠す)
func setup(title: String, subject: String) -> void:
	if not is_node_ready():
		await ready
	_title_label.text = title
	_subject_label.text = subject
	_subject_label.visible = not subject.is_empty()


func _build_stars() -> void:
	for i in range(STAR_COUNT):
		var star := _star_template.duplicate() as Button
		star.visible = true
		star.name = "Star%d" % (i + 1)
		# 押したときだけ「その位置までを点灯」させる (一般的な★評価の操作感)。
		#
		# **フォーカスを当てただけでは点灯させない**。当初はプレビュー点灯していたが、
		# 「カーソルを合わせた時点でもう評価が決まったように見えて気持ち悪い」ため撤去した。
		# 未確定と確定を色で区別できる方が、押す前に迷える。位置はフォーカス枠が示すので
		# プレビューが無くても操作に困らない。
		star.pressed.connect(func(): _set_rating(i + 1))
		_star_row.add_child(star)
		_stars.append(star)


func _set_rating(value: int) -> void:
	_rating = clampi(value, 0, STAR_COUNT)
	_paint_stars(_rating)
	_hint_base_text = "★%d を選びました" % _rating
	_rating_hint.text = _hint_base_text
	_reset_idle()
	_reset_progress()
	_refresh_submit_enabled()


func _paint_stars(lit_count: int) -> void:
	for i in range(_stars.size()):
		var lit := i < lit_count
		# 点灯 = 金、消灯 = 暗いグレー。文字色だけで表現し、レイアウトを動かさない
		# (サイズを変えると押すたびに行が揺れて狙いづらくなる)。
		var base := Color(1, 0.85, 0.3) if lit else Color(0.35, 0.35, 0.35)
		_stars[i].add_theme_color_override("font_color", base)
		# **focus 色は通常色と同じにする**。フォーカスの表示は共有枠 1 枚に一本化しており、
		# 枠はマウス操作中に隠れる。ここで focus 色だけ明るくすると、枠が消えた後も★が明るいまま
		# residue として残り「選んだように見える」(実機で発覚)。フォーカスは枠だけで示す。
		_stars[i].add_theme_color_override("font_focus_color", base)
		# hover はマウスカーソルに追従して消えるので残らない。触っている★を示す手掛かりとして残す。
		_stars[i].add_theme_color_override("font_hover_color", Color(1, 0.9, 0.45) if lit else Color(0.55, 0.55, 0.55))


func _refresh_submit_enabled() -> void:
	# ★未選択では送れない (空の回答は集計を汚すだけ)。押せないことが見て分かるよう薄くする。
	_submit_button.disabled = (_rating == 0)
	_submit_button.modulate.a = 1.0 if _rating > 0 else 0.5


## 文字数と操作案内を 1 行にまとめる。専用の行を足すとパネルの高さが変わってレイアウトが
## 崩れるため、既存の文字数ラベルに同居させる。案内は状態で変える (編集中かどうかで
## 次にできることが違うため)。
func _comment_hint_text(length: int) -> String:
	var guide := "Esc または Tab で入力欄から出る" if _comment_edit.editable else "決定キーで入力できます"
	return "%s　　%d / %d" % [guide, length, COMMENT_MAX_LENGTH]


## 現在の状態でヒントを描き直す。
func _refresh_comment_hint() -> void:
	_comment_count.text = _comment_hint_text(_comment_edit.text.length())


func _on_comment_toggle_pressed() -> void:
	var opening := not _comment_section.visible
	_comment_section.visible = opening
	_comment_toggle.text = "− 感想を閉じる" if opening else "＋ 感想を書く（任意）"
	_wire_comment_neighbors()
	if opening:
		# 開いた時点では**編集を始めない**。フォーカスだけ当てて、決定キーで編集に入る
		# (他のボタンと同じ感覚に揃える)。ヒントは開いた時点で見せる。
		_end_editing_comment()
		_comment_edit.grab_focus()
	else:
		# 畳むときは編集状態を残さない (次に開いたときいきなり編集中にならないように)。
		_end_editing_comment()


func _on_comment_changed() -> void:
	# 上限超過は入力時点で切る (書き出し側でも切るが、あちらは最後の砦。ここで止めれば
	# 来場者が「打ったのに消えた」と感じずに済む)。
	var text := _comment_edit.text
	if text.length() > COMMENT_MAX_LENGTH:
		var caret := _comment_edit.get_caret_column()
		_comment_edit.text = text.substr(0, COMMENT_MAX_LENGTH)
		_comment_edit.set_caret_column(mini(caret, COMMENT_MAX_LENGTH))
		text = _comment_edit.text
	_comment_count.text = _comment_hint_text(text.length())
	# 打っている間は上限に当たらないようにする (書いている人を切らない)。
	_reset_progress()


## 入力欄の中でのキー処理。**キーボードだけで入力欄から出られる**ようにするためのもの。
##
## TextEdit は矢印キーをキャレット移動に、Tab をインデントに使うので、通常のフォーカス移動
## (focus_neighbor) では脱出できない。放置すると来場者が入力欄に閉じ込められる。
##
## **Esc は「入力欄から出る」であって「アンケートを閉じる」ではない** (2 段階)。入力欄の外での
## Esc はスキップ扱い (_unhandled_input) だが、入力中の Esc までスキップにすると、
## 「入力をやめたいだけ」で回答ごと消えてしまう。
func _on_comment_edit_gui_input(event: InputEvent) -> void:
	if not _comment_edit.editable:
		# --- フォーカスされているだけの状態 ---
		# 決定で編集を開始する。**InputEventKey に限定しないこと** — ゲームパッドの決定は
		# InputEventJoypadButton で来るため、キー限定にするとパッドから編集に入れない。
		if event.is_action_pressed("ui_accept"):
			_comment_edit.accept_event()
			_begin_editing_comment()
			return
		# **上下移動は自分で処理する。** TextEdit は編集不可でも矢印をキャレット移動として
		# 消費するため、focus_neighbor に任せると入力欄から出られなくなる (実機で発覚)。
		# 移動先は _wire_comment_neighbors が張った neighbor を読む (経路の定義を 1 箇所に保つ)。
		if event.is_action_pressed("ui_up"):
			_comment_edit.accept_event()
			_focus_neighbor_of(_comment_edit.focus_neighbor_top)
			return
		if event.is_action_pressed("ui_down"):
			_comment_edit.accept_event()
			_focus_neighbor_of(_comment_edit.focus_neighbor_bottom)
			return
		# 左右は移動先が無い。放置するとキャレットだけ動いて「反応したのに何も起きない」
		# 状態になるので、消費して何もしない。
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_comment_edit.accept_event()
			return
		return

	# --- 編集中 --- (以降はキーボード固有の操作なので InputEventKey に限定)
	if not (event is InputEventKey) or not event.pressed:
		return
	if event.keycode == KEY_ESCAPE:
		# 編集をやめてフォーカス状態へ戻る (入力欄からは離れない)。accept_event() で
		# _unhandled_input (= アンケートのスキップ) まで伝播させない。Esc は入れ子で
		# 「編集をやめる」→「アンケートをやめる」の順に効く。
		_comment_edit.accept_event()
		_end_editing_comment()
	elif event.keycode == KEY_TAB:
		# Tab = 編集をやめて次へ / Shift+Tab = 前へ。インデント挿入は止める。
		_comment_edit.accept_event()
		_end_editing_comment()
		if event.shift_pressed:
			_comment_toggle.grab_focus()
		elif _submit_button.disabled:
			_skip_button.grab_focus()
		else:
			_submit_button.grab_focus()


## neighbor path が指すコントロールへフォーカスを移す。押せないボタン (★未選択時の「送る」) には
## 移さず「答えない」へ逃がす — 押せないボタンで止まると進めなくなるため。
func _focus_neighbor_of(path: NodePath) -> void:
	if path.is_empty():
		return
	var target := get_node_or_null(path) as Control
	if target == null:
		return
	if target is Button and (target as Button).disabled:
		_skip_button.grab_focus()
		return
	target.grab_focus()


## 編集を開始する (キャレットを出す)。
func _begin_editing_comment() -> void:
	_comment_edit.editable = true
	_comment_edit.grab_focus()
	_comment_edit.set_caret_line(_comment_edit.get_line_count() - 1)
	_comment_edit.set_caret_column(_comment_edit.get_line(_comment_edit.get_line_count() - 1).length())
	_refresh_comment_hint()


## 編集をやめる (フォーカスは入力欄に残したまま、キャレットを消す)。
func _end_editing_comment() -> void:
	_comment_edit.editable = false
	_refresh_comment_hint()


func _on_skip_pressed() -> void:
	if _finished:
		return
	_finished = true
	skipped.emit()


func _on_submit_pressed() -> void:
	if _finished or _rating == 0:
		return
	_finished = true
	# 空欄は空文字ではなく null で渡す。「書かなかった」と「空欄で送った」を集計側が
	# 区別できるようにするため (SPEC §6.5「任意フィールドの NULL 扱い」)。
	var text := _comment_edit.text.strip_edges()
	# 押した直後に画面が消えると「送れたのか分からない」ままになる。**画面は増やさず**、
	# 同じパネルの中身を一瞬お礼に差し替えてから既存の消滅アニメーションへ渡す。
	# スキップ時は出さない (礼を言われる筋合いが無いうえ、立ち去る人を足止めするだけ)。
	await _show_thanks()
	submitted.emit(_rating, null if text.is_empty() else text)


## パネルの中身をお礼に差し替えて少し待つ。
##
## **要素を hide() せず透明にする**のは、PanelContainer が中身に合わせて縮み、
## 消える直前にカードの大きさが跳ねるのを避けるため。位置はそのまま、文字だけが入れ替わって見える。
func _show_thanks() -> void:
	_thanking = true
	for node in [_star_row, _subject_label, _comment_toggle, _comment_section, _button_container]:
		(node as CanvasItem).modulate.a = 0.0
	_focus_border.visible = false
	_title_label.text = "ご協力ありがとうございます"
	_rating_hint.text = "回答を受け取りました"
	# ツリーは止まっているので、ポーズ中も進むタイマーを使う (create_timer の既定)。
	await get_tree().create_timer(THANKS_SECONDS).timeout


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	# ESC はスキップ扱い。来場者が「閉じたい」と思ったときに逃げ道が無いと、
	# 適当な★を押して立ち去られる (= 質の低い回答が混ざる) 方が困る。
	#
	# **入力欄の中の Esc はここに来ない** — _on_comment_edit_gui_input が accept_event() で
	# 止め、「入力欄から出る」に割り当てているため (2 段階)。TextEdit は Esc を消費しないので、
	# 明示的に止めないとここへ伝播して「入力をやめたいだけ」で回答ごと消える。
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# **1 回目は「答えない」にフォーカスを移すだけ**、同じ状態でもう一度押したら確定。
		# 誤爆で回答が消えるのを防ぐワンクッション。確認ダイアログは作らない —
		# アンケートは元々スキップ可能で失うものが無く、ダイアログを重ねるとポーズの
		# 二重管理 (本画面も DialogManager と同じくツリーを止めている) になるため。
		if get_viewport().gui_get_focus_owner() == _skip_button:
			_on_skip_pressed()
		else:
			_skip_button.grab_focus()


## フォーカスの行き来を明示配線する。★の行 → 感想ボタン → 下段ボタン、で縦に降りられるようにする。
## (既定の自動計算だと TextEdit を挟んだ時に意図しない飛び方をするため。)
func _wire_focus_neighbors() -> void:
	for i in range(_stars.size()):
		var star := _stars[i]
		star.focus_neighbor_left = _stars[maxi(i - 1, 0)].get_path()
		star.focus_neighbor_right = _stars[mini(i + 1, _stars.size() - 1)].get_path()
		star.focus_neighbor_top = star.get_path()
		star.focus_neighbor_bottom = _comment_toggle.get_path()

	_comment_toggle.focus_neighbor_top = _stars[0].get_path()
	_wire_comment_neighbors()

	_submit_button.focus_neighbor_left = _skip_button.get_path()
	_submit_button.focus_neighbor_right = _skip_button.get_path()
	_submit_button.focus_neighbor_top = _comment_toggle.get_path()
	_skip_button.focus_neighbor_left = _submit_button.get_path()
	_skip_button.focus_neighbor_right = _submit_button.get_path()
	_skip_button.focus_neighbor_top = _comment_toggle.get_path()


## 感想欄の開閉に合わせてフォーカス経路を繋ぎ替える。畳んでいるときに入力欄へ飛ぶと
## 見えないコントロールにフォーカスが乗って操作不能に見える。
func _wire_comment_neighbors() -> void:
	if _comment_section.visible:
		_comment_toggle.focus_neighbor_bottom = _comment_edit.get_path()
		_comment_edit.focus_neighbor_top = _comment_toggle.get_path()
		_comment_edit.focus_neighbor_bottom = _submit_button.get_path()
		_submit_button.focus_neighbor_top = _comment_edit.get_path()
		_skip_button.focus_neighbor_top = _comment_edit.get_path()
	else:
		_comment_toggle.focus_neighbor_bottom = _submit_button.get_path()
		_submit_button.focus_neighbor_top = _comment_toggle.get_path()
		_skip_button.focus_neighbor_top = _comment_toggle.get_path()
