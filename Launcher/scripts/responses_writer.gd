## (#297 PR2) `responses/` へ 1 件 1 ファイルの JSON を atomic に書き出す共通ライター。
##
## プレイ記録 (`play_records`) とアンケート (`surveys`) は**書き出し方が完全に同じ**で、違うのは
## category 名と固有フィールドだけなので、共通フィールド・ファイル名規則・日付フォルダ・atomic write・
## 失敗時の振る舞いを本クラス 1 箇所に集約する (SoT)。呼び出し側は固有フィールドを渡すだけでよい。
##
## 出力先: `<base>/responses/<category>/YYYY-MM-DD/<unix_ts>-<game_no>-<uuid>.json` (SPEC §7.5.3)
##  - **日付フォルダ**: 1 フォルダあたりのファイル数を抑え、会期日単位の集計・retention・走査を容易にする。
##    バケットは `created_at` から導く (フォルダと JSON 内の日付が食い違わないように)。
##  - **ファイル名**: `<unix_ts>-<game_no>-<uuid>.json`。時刻 prefix で名前順 = 時系列、uuid で複数 PC が
##    同時に書いても物理的に別ファイル (= 衝突なし・二重カウントなし)。**game_no を名前に持たせるのが要点**で、
##    「人気ランキング (ゲーム別の件数)」と「最近プレイ (最新 N 件)」が **1 ファイルも開かずに**求まる。
##    本番は SMB 共有なので「ファイルを開く回数 = ネットワーク往復回数」であり、会期中ずっと数十秒おきに
##    走る集計からその往復を消せる意味は大きい (ローカル実測でも全件パース 220ms に対し一覧のみ 13ms /
##    3000 件、SMB では差がさらに開く)。中身を開く必要があるのはプレイ時間・★評価・コメントなど、
##    文化祭後にゆっくりやればよい分析だけになる。
##  - **atomic write**: `.tmp` に書いてから rename。書きかけの JSON を集計側に読ませないため。
##    session_heartbeat.gd の同型 pattern が下敷きだが、**書き込みの成否を確認してから rename する点だけ違う**
##    (heartbeat は 10 秒ごとに上書きされる使い捨てなので未確認でも無害、こちらは 1 回きり・取り直し不可の
##    不変レコードなので壊れたまま公開すると取り返しがつかない)。
##  - **追記しない**: 1 度書いたら read-only で放置する (#297 で 3-state フォルダ `imported/` `failed/` は廃止)。
##  - **ファイル名と中身は重複してよい** (`created_at` / `game_no` は両方に入る。`type` も category フォルダから
##    導ける)。**中身が正本、ファイル名はそれを速く読むための索引**、という関係にする。DB の index が
##    テーブルの内容を複製するのと同じで、重複は設計上の意図。理由は 2 つ:
##    (1) **レコードは単体で完結していなければならない**。ファイル名は「ファイルに付いた外側の情報」に過ぎず、
##        コピーツールが `foo (1).json` に改名する / 手でフォルダを整理する / zip から展開する / 将来の
##        retention 処理が並べ替える、といった操作で失われうる。中身にも持っていれば、名前が壊れても
##        レコード自体は読める (取り直し不可能なデータなので、名前に依存させるのは危険)。
##    (2) **両者は必ず一致する**。同一の atomic write で同時に決まり、書いた後は二度と変更しないため、
##        ズレようがない。もし食い違うファイルを見つけたら、それは外部からの改名なので**中身を信じる**。
##    重複コストは 1 件あたり約 20 バイト。
##
## **fail-soft**: 書き込みに失敗しても警告とカウンタを残すだけで、ゲームプレイや画面遷移は絶対に止めない。
## 記録は「取れたら嬉しい」データであって、これのために来場者の体験を壊してはいけない。
##
## **log output 規約**: `LogBridge.info / warn` を使う (AGENTS.md「Cross-component Standards」)。
## 組み込み `Logger` クラスとの名前衝突で `Logger.info()` と直接は書けないが、**呼べないわけではない**
## (`LogBridge` が `/root/Logger` を解決する)。標準の出力関数はレベルを指定できず、診断画面の
## WARN 抽出が Godot 標準ログのテール頼み (0.5 秒ポーリング) になるため新規コードでは使わない。

extends RefCounted
class_name ResponsesWriter

const RESPONSES_DIRNAME: String = "responses"

## セッション通算の書き出し結果。**診断画面 (サービスモード) はログではなくここを見る。**
## `Logger` の保持は 400 行のリングバッファなので、来場者が回った日の夕方には朝の失敗が
## 押し出されて消える。それを根拠に「エラーはありません」と断言すると、診断画面が一番やっては
## いけない「嘘の ✓」になる (レビュー Medium-2)。カウンタなら溢れない。
static var write_ok_count: int = 0
static var write_fail_count: int = 0
## 最後に失敗した理由 (対処を出すために画面へそのまま見せる)。
static var last_write_error: String = ""

## data drop の category 名 (= `responses/` 直下の subfolder 名、SPEC §7.5.3)。
const CATEGORY_PLAY_RECORDS: String = "play_records"
const CATEGORY_SURVEYS: String = "surveys"

## 1 件のレコードを `responses/<category>/YYYY-MM-DD/` へ atomic 書き出しする。
##
## 共通フィールド (`type` / `source_pc` / `created_at` / `game_no`) は本関数が付与するので、呼び出し側は
## 固有フィールドだけを `fields` に渡す。これで「共通フィールドを付け忘れたレコード」が構造的に作れなくなる。
##
## category: [constant CATEGORY_PLAY_RECORDS] / [constant CATEGORY_SURVEYS]
## record_type: JSON の `type` 値 (`"play_record"` / `"survey"`)
## game_no: 対象ゲームの不変番号。**ゲームに紐づかないレコード (退出時の全体アンケート) は 0 以下**を渡す
##   → JSON 本体は `null` (「ゲームを指さない」を明示)、ファイル名は `0` (数値のまま名前に埋める) になる。
##   本体を 0 にしないのは、集計側が「0 番のゲーム」と読み違える余地を残さないため。
## fields: 固有フィールド (play_record なら start_time / end_time、survey なら rating / comment / trigger)
## 戻り値: 書き出せたら true。失敗しても例外は投げず false を返すだけ (呼び出し側は無視してよい)。
static func write_record(category: String, record_type: String, game_no: int, fields: Dictionary) -> bool:
	var ok := _write_record(category, record_type, game_no, fields)
	if ok:
		write_ok_count += 1
	return ok


## 失敗を記録して false を返す。**全ての失敗経路をここに通す**ことで、カウンタと最終エラーの
## 更新漏れが構造的に起きないようにする (return 文ごとに書くと必ずどこかで忘れる)。
static func _fail(message: String) -> bool:
	write_fail_count += 1
	last_write_error = message
	LogBridge.warn("[ResponsesWriter] " + message)
	return false


static func _write_record(category: String, record_type: String, game_no: int, fields: Dictionary) -> bool:
	if category.is_empty() or record_type.is_empty():
		return _fail("category / type が空のため書き出しを中止")

	var base_dir := PathManager.get_base_directory()
	if base_dir.is_empty():
		return _fail("base directory 不明のため書き出しを中止 (category=%s)" % category)

	var created_at := int(Time.get_unix_time_from_system())
	var payload := {
		"type": record_type,
		"source_pc": get_pc_name(),
		"created_at": created_at,
		# 0 以下 = ゲームに紐づかない (全体アンケート)。本体は null で明示する。
		"game_no": game_no if game_no > 0 else null,
	}
	# (レビュー Medium-2) 共通フィールドは**必ず**ライター側を勝たせる (overwrite=false)。
	# overwrite=true だと呼び出し側が fields に "type" や "created_at" を入れた瞬間に共通フィールドを
	# 黙って上書きでき、「共通フィールドはライターが SoT」という本クラスの契約が破れる。防ぎたいのは
	# 「付け忘れ」だけでなく「取り違え」も同じで、後者は静かに誤ったレコードを量産する分むしろ悪い。
	# 衝突は呼び出し側のバグなので警告して気づけるようにする (無視して続行 = レコードは正しい形で残る)。
	for key in fields.keys():
		if payload.has(key):
			LogBridge.warn("[ResponsesWriter] 共通フィールド \"%s\" は呼び出し側で指定できません (ライター側の値を使用): category=%s"
				% [key, category])
	payload.merge(fields, false)

	var dir_path := base_dir.path_join(RESPONSES_DIRNAME).path_join(category).path_join(date_folder(created_at))
	if not DirAccess.dir_exists_absolute(dir_path):
		var mk_err := DirAccess.make_dir_recursive_absolute(dir_path)
		if mk_err != OK:
			return _fail("日付フォルダの作成に失敗: path=%s err=%d" % [dir_path, mk_err])

	# ファイル名の番号部分は「紐づかない」を 0 で表す (本体の null と対。名前に null は書けないため)。
	var name_no := game_no if game_no > 0 else 0
	var final_path := dir_path.path_join("%d-%d-%s.json" % [created_at, name_no, _new_uuid()])
	var tmp_path := final_path + ".tmp"

	var json_str := JSON.stringify(payload)
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return _fail(".tmp を開けませんでした: path=%s err=%d" % [tmp_path, FileAccess.get_open_error()])
	f.store_string(json_str)
	# (レビュー Medium-1) 書けたことを確認してから rename する。
	# atomic write (.tmp → rename) が保証するのは「書きかけを読ませない」ことだけで、「書けたこと」は
	# 保証しない。ディスク満杯 / SMB 切断 / 権限で store_string が失敗しても rename 自体は成功するため、
	# 確認せずに rename すると**中身が空や途中の .json が正規のレコードとして残る**。
	# session_heartbeat.gd の同型パターンは get_error を見ていないが、あちらは 10 秒ごとに上書きされる
	# 使い捨てなので無害。こちらは 1 回きり・取り直し不可の不変レコードなので同じ手抜きはできない。
	var write_err := f.get_error()
	f.close()
	if write_err != OK:
		DirAccess.remove_absolute(tmp_path)
		return _fail(".tmp への書き込みに失敗: err=%d path=%s" % [write_err, tmp_path])

	# close() 時点で初めて表面化する失敗 (flush 時のディスク満杯等) を、実バイト数の照合で捕まえる。
	var expected_bytes := json_str.to_utf8_buffer().size()
	var verify := FileAccess.open(tmp_path, FileAccess.READ)
	if verify == null:
		DirAccess.remove_absolute(tmp_path)
		return _fail(".tmp を読み直せませんでした (書き込み検証不能): path=%s" % tmp_path)
	var actual_bytes := verify.get_length()
	verify.close()
	if actual_bytes != expected_bytes:
		DirAccess.remove_absolute(tmp_path)
		return _fail(".tmp のサイズが不一致 (期待 %d バイト / 実際 %d バイト)、破棄しました: path=%s"
			% [expected_bytes, actual_bytes, tmp_path])

	var rename_err := DirAccess.rename_absolute(tmp_path, final_path)
	if rename_err != OK:
		# 残骸を best-effort 掃除 (集計側は .tmp を無視する契約だが、放置すると溜まるため)。
		DirAccess.remove_absolute(tmp_path)
		return _fail(".tmp → .json の rename に失敗: err=%d path=%s" % [rename_err, final_path])

	return true


## レコードの `source_pc` に入れる PC 名。COMPUTERNAME (Windows) → HOSTNAME → "unknown"。
##
## logger.gd / session_heartbeat.gd に同 logic が既にあるが、それらの helper 共通化は別 PR scope
## (両者のコメントに同趣旨の注記あり)。本クラスはプレイ記録・アンケートの 2 ライターで共有する。
static func get_pc_name() -> String:
	var pc_name := OS.get_environment("COMPUTERNAME")
	if pc_name.is_empty():
		pc_name = OS.get_environment("HOSTNAME")
	if pc_name.is_empty():
		pc_name = "unknown"
	return pc_name


## UNIX 秒から `YYYY-MM-DD` の日付フォルダ名を作る (**ローカル時刻**基準)。
##
## public なのは、サービスモードの「記録の動作確認」が同じ導出を必要とするため。同じロジックを
## 各所に書くと、タイムゾーン補正の有無がズレて「フォルダは今日なのに集計は昨日を見ている」の
## ような追いにくい食い違いを生むので、導出はここ 1 箇所に集約する。
##
## `Time.get_datetime_dict_from_unix_time` は UTC を返すので、システムのタイムゾーン bias を足してから
## 変換する。UTC のままだと日本時間の朝 9 時より前が前日フォルダに落ち、「会期 1 日目のフォルダ」が
## 直感と 1 日ズレる (スタッフが手でフォルダを覗く運用があるため実害がある)。
static func date_folder(unix_ts: int) -> String:
	var tz := Time.get_time_zone_from_system()
	var bias_minutes := int(tz.get("bias", 0))
	var d := Time.get_datetime_dict_from_unix_time(unix_ts + bias_minutes * 60)
	return "%04d-%02d-%02d" % [int(d.get("year", 1970)), int(d.get("month", 1)), int(d.get("day", 1))]


## ファイル名衝突を避けるためのランダム 32 桁 hex。
##
## Godot に UUID の組み込みが無いため randi() 4 回 (= 128 bit) で代用する。用途は「同一秒に複数 PC が
## 書いても別ファイルになること」だけで、暗号強度も RFC 4122 準拠も要らない。乱数は Godot が起動時に
## 自動 seed する (4.x の既定) ため randomize() は呼ばない。
static func _new_uuid() -> String:
	return "%08x%08x%08x%08x" % [randi(), randi(), randi(), randi()]
