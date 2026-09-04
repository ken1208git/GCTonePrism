## (#297 PR3 / #35) アンケート 1 件を `responses/surveys/` へ JSON 出力する。
##
## 書き出しの実務 (日付フォルダ・ファイル名規則・共通フィールド・atomic write・fail-soft) は
## [ResponsesWriter] が持つので、本クラスはアンケート固有のフィールドを組み立てるだけの薄い層。
## プレイ記録側の [PlayRecordWriter] と対になる (あちらは autoload で signal を購読するが、
## こちらは「回答が確定した瞬間」に呼ばれるだけなので autoload である必要がない)。
##
## **スキップは保存しない** (SPEC §機能10)。回答しなかったことを記録しても、無回答と区別できず
## 集計の役に立たないうえ、★評価の平均を歪める。呼び出し側がスキップ時に本クラスを呼ばないことで担保する。
##
## **log output 規約**: `LogBridge.info / warn` を使う (AGENTS.md「Cross-component Standards」)。
## 組み込み `Logger` クラスとの名前衝突で `Logger.info()` と直接は書けないが、**呼べないわけではない**
## (`LogBridge` が `/root/Logger` を解決する)。標準の出力関数はレベル指定ができない。

extends RefCounted
class_name SurveyWriter

const RECORD_TYPE: String = "survey"

## アンケートの発火元 (JSON の `trigger`、SPEC §7.5.3)。
const TRIGGER_GAME_END: String = "game_end"          ## ゲーム終了時のゲーム個別アンケート
const TRIGGER_LAUNCHER_END: String = "launcher_end"  ## 退出時の全体アンケート

const RATING_MIN: int = 1
const RATING_MAX: int = 5
## 自由記述の上限 (SPEC §機能10)。UI 側でも入力を止めるが、書き出し側でも最後の砦として切る。
const COMMENT_MAX_LENGTH: int = 200


## アンケート 1 件を書き出す。
##
## game_no: ゲーム個別アンケートは対象ゲームの番号。**全体アンケートは 0** (ゲームを指さない)。
## rating: 1〜5。範囲外は書き出さない (壊れた値を混ぜるより落とす方が集計が信用できる)。
## comment: 自由記述。**空欄なら空文字ではなく null** を渡すこと (下記参照)。
## trigger: [constant TRIGGER_GAME_END] / [constant TRIGGER_LAUNCHER_END]
## 戻り値: 書き出せたら true。
static func write(game_no: int, rating: int, comment, trigger: String) -> bool:
	if rating < RATING_MIN or rating > RATING_MAX:
		LogBridge.warn("[SurveyWriter] 評価が範囲外 (%d) のため記録しません: trigger=%s" % [rating, trigger])
		return false
	if trigger != TRIGGER_GAME_END and trigger != TRIGGER_LAUNCHER_END:
		LogBridge.warn("[SurveyWriter] 未知の trigger のため記録しません: %s" % trigger)
		return false

	# (SPEC §6.5「任意フィールドの NULL 扱い」) 「書かなかった」(null) と「空欄で送った」("") を
	# 区別できる形で出す。集計側は「コメント有り」を comment != null かつ != "" で判定する。
	# ここでは呼び出し側が渡した null をそのまま通し、文字列なら上限で切る。
	var normalized_comment = null
	if comment != null:
		var text := str(comment)
		if text.length() > COMMENT_MAX_LENGTH:
			LogBridge.warn("[SurveyWriter] コメントが上限 %d 字を超えたため切り詰めます (%d 字)"
				% [COMMENT_MAX_LENGTH, text.length()])
			text = text.substr(0, COMMENT_MAX_LENGTH)
		normalized_comment = text

	var ok := ResponsesWriter.write_record(ResponsesWriter.CATEGORY_SURVEYS, RECORD_TYPE, game_no, {
		"rating": rating,
		"comment": normalized_comment,
		"trigger": trigger,
	})

	if ok:
		LogBridge.info("[SurveyWriter] アンケートを出力: %s 評価=%d コメント=%s"
			% [_label(game_no, trigger), rating, "なし" if normalized_comment == null else "%d 字" % str(normalized_comment).length()])
	else:
		LogBridge.warn("[SurveyWriter] アンケートの出力に失敗しました: %s" % _label(game_no, trigger))
	return ok


## ログ用の表記。JSON は game_no しか持たないため、調査時にログだけで突き合わせられるようにする
## (SPEC §7.5.3 の露出方針)。ゲーム個別は呼び出し側が game_id を知らないので番号のみ併記する。
static func _label(game_no: int, trigger: String) -> String:
	if trigger == TRIGGER_LAUNCHER_END:
		return "全体アンケート"
	return "ゲーム個別 (no.%d)" % game_no
