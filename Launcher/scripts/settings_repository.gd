## (#297 PR3 / #35) `settings` テーブル (key TEXT PRIMARY KEY, value TEXT) の読み取り。
##
## **Launcher が settings を読むのはこれが初めて**。従来はゲーム情報とストア設定しか読んでおらず、
## Manager 側の設定は Launcher の挙動に影響しなかった。アンケートの on/off トグル (#35) で初めて
## 「Manager の設定が Launcher の振る舞いを変える」経路ができるため、その入口として新設する。
##
## **読み取りは都度行い、キャッシュしない**のが要点。起動時に読んでキャッシュすると、Manager で
## トグルを切り替えても各キオスクを再起動するまで反映されない (#263 の「設定変更の Launcher 反映には
## 再起動が要る」問題)。アンケートのトグルは「ピーク時に今すぐ止めたい」ために存在するので、
## 再起動が要る時点で機能の意味がほぼ消える。DB 接続は既に開いているため、アンケートを出す直前に
## 小さな SELECT を 1 回投げるだけで済み、切り替えが全キオスクへ即座に効く。
##
## 書き込みは行わない (SPEC §6.5「Launcher は SQLite に直接書き込まない」)。

extends RefCounted
class_name SettingsRepository

var _db_manager: DatabaseManager


func _init(db_manager: DatabaseManager) -> void:
	_db_manager = db_manager


## 設定値を文字列で取得する。キーが無い / DB を開けない場合は default_value。
func get_string(key: String, default_value: String = "") -> String:
	if not _db_manager.is_open():
		if not _db_manager.open():
			LogBridge.warn("[SettingsRepository] DB を開けないため既定値を使用: key=" + key)
			return default_value

	if not _db_manager.db.query_with_bindings("SELECT value FROM settings WHERE key = ?", [key]):
		LogBridge.warn("[SettingsRepository] 設定の取得に失敗、既定値を使用: key=" + key)
		return default_value

	var result = _db_manager.db.get_query_result()
	if result == null or result.size() == 0:
		return default_value

	var row = result[0]
	if row is Dictionary:
		var v = row.get("value")
		return default_value if v == null else str(v)
	return default_value


## 設定値を真偽値で取得する。
##
## **bool 設定の正本は `"true"` / `"false"`**。Manager は `SettingsRepository.SetString` でこの形で書く
## (`SettingsPage.SaveSurveyToggle` / `BackupAuto_Changed`)。`"1"` / `"0"` も受けるのは手編集や
## 外部ツールへの保険で、Manager がその形で書くわけではない (以前このコメントは逆を書いていた)。
## 大文字小文字は無視する。**Manager 側の読みも同じ規則に揃えてある** — 揃っていないと
## 「Manager では ON、Launcher では OFF」という切り分け不能な食い違いになる。解釈できない値は
## **既定値にフォールバックする** (false に倒さない)。アンケートのトグルのように「既定は ON」の
## 設定で、値が壊れているというだけで黙って機能が消えるのを避けるため。
func get_bool(key: String, default_value: bool) -> bool:
	var raw := get_string(key, "").strip_edges().to_lower()
	if raw.is_empty():
		return default_value
	if raw == "1" or raw == "true":
		return true
	if raw == "0" or raw == "false":
		return false
	LogBridge.warn("[SettingsRepository] 真偽値として解釈できない設定値、既定値を使用: key=%s value=%s" % [key, raw])
	return default_value
