## データベース管理クラス
## SQLiteデータベースの接続、バージョン管理、ユーティリティを提供
## ゲームデータのクエリは GameRepository / StoreSectionRepository を使用

extends RefCounted
class_name DatabaseManager

var db: SQLite = null
var db_path: String = ""

# Launcher が想定する DB スキーマバージョン
# Manager 側 SchemaManager.cs の CurrentDbVersion と歩調を合わせること
# (v9, v10, v12 は backup_log 関連 / v13 は manager_sessions で Launcher は触らない /
#  v11 の surveys・play_records 新スキーマには Launcher が対応していたが、v23 で両テーブルごと撤去 (#297、下記) /
#  v14 は games.arguments の正規 migration 化のみで最終スキーマ不変・Launcher は arguments 対応済
#  v15/v17 は game_versions の UNIQUE INDEX 強化 (NOCASE 化含む)、v16 は backup_log CHECK 拡張、
#  v19 は backup_log DROP → いずれも Launcher が読まないテーブル / index のみで読み取り不変 /
#  v18 は developers.version_id FK + ON DELETE CASCADE 追加 / game_genres dead table 除去・
#  v20 は games.play_time に CHECK(1-3) 追加 → 制約追加のみで Launcher の読み取りクエリは不変 /
#  v21/v22 は intro_slides テーブル新設と duration_sec 削除 (#253)。Launcher は本テーブルを
#  IntroSlideRepository (手動ナビの初回説明) で読むため、ここで明示的に対応版数を v22 へ追従させる /
#  v23 は play_records/surveys/launcher_surveys を DROP (#297、JSON 直読みへピボット)。Launcher の
#  store_section_repository は popular/recently_played を play_records 非参照化済 (PR1) なので定数追従のみ /
#  v24 は games.game_no 追加 (#297 PR2)。プレイ記録・アンケート JSON がゲームを指す不変キーで、Launcher は
#  GameRepository (SELECT *) 経由で読み PlayRecordWriter が JSON に書く (アンケート側の writer は #35 で追加予定)。読み取り列が増える
#  ので定数追従だけでなく実利用あり。v24 未満の DB では game_no が無く -1 になり、書き出しは skip される
#  → v15〜v23 は定数追従、v24 は実利用
const CURRENT_DB_VERSION: int = 24

## データベースを開く。
##
## busy_timeout_ms: ロック競合時に待つ上限。既定 (10 秒) は「待ってでも確実に読む」用。
##   **来場者を待たせる瞬間に呼ぶ場合は短くすること** — ゲーム終了直後のように画面が固まって
##   見える局面で 10 秒待つくらいなら、既定値にフォールバックした方が体験を壊さない (レビュー M-3)。
## check_version: 版数チェックと migration 案内を走らせるか。設定値を 1 つ読むだけの用途では不要な
##   往復なので切れるようにしてある (SMB では 1 クエリ = 1 往復)。
func open(busy_timeout_ms: int = 10000, check_version: bool = true) -> bool:
	if db != null:
		return true

	db_path = PathManager.get_database_path()

	# データベースファイルが存在するか確認
	if not FileAccess.file_exists(db_path):
		push_error("[DatabaseManager] データベースファイルが見つかりません: " + db_path)
		return false

	# SQLiteインスタンスを作成
	db = SQLite.new()

	# データベースパスを設定
	db.path = db_path

	# データベースを開く（godot-sqliteのAPI）。失敗時 (パス不正・権限不足・ロック等) は
	# false が返る。db オブジェクト自体は非 null のままなので、戻り値で必ず判定する。
	if not db.open_db():
		push_error("[DatabaseManager] データベースを開けませんでした: " + db_path)
		db = null
		return false

	print("[DatabaseManager] データベースを開きました: ", db_path)

	# **busy_timeout を先に張る**。journal_mode の変更はロックを要求するため、先に待機列を確保
	# しておかないと、Manager がバックアップ等で DB を握っている瞬間にリトライ猶予ゼロで即失敗する。
	db.query("PRAGMA busy_timeout=%d;" % busy_timeout_ms)

	# SMB ネットワーク共有上での運用安全性のため DELETE モードを使用 (#103)。
	#
	# **戻り値の bool では判定できない** (レビュー M-1)。`PRAGMA journal_mode=X` は切り替えられなかった
	# 場合でもエラーにならず、**現在のモードを結果行として返して成功する**。bool を見るだけだと
	# 「DELETE に落ちていないのに OK と読む」silent pass になり、#103 の前提 (SMB 上で WAL を使わない)
	# が静かに崩れる。結果行の journal_mode を実際に読んで照合する。
	if db.query("PRAGMA journal_mode=DELETE;"):
		var jres := db.get_query_result()
		var mode := ""
		if jres and jres.size() > 0:
			mode = str(jres[0].get("journal_mode", "")).to_lower()
		if mode != "delete":
			LogBridge.warn("[DatabaseManager] journal_mode を DELETE にできませんでした (現在: %s)。他プロセスが DB を握っている可能性があります。SMB 上で WAL のまま運用すると共有越しの整合性が保証されません (#103)" % (mode if mode != "" else "不明"))
	else:
		LogBridge.warn("[DatabaseManager] PRAGMA journal_mode の実行自体に失敗しました。DB がロックされている可能性があります")

	# データベースのバージョンチェックとマイグレーション
	if check_version:
		_check_and_migrate_db()

	return true

## データベースを閉じる
func close() -> void:
	if db != null:
		db.close_db()
		db = null
		print("[DatabaseManager] データベースを閉じました")

## データベースが開いているか確認
func is_open() -> bool:
	return db != null

## データベースのバージョンを取得
func _get_db_version() -> int:
	if db == null:
		return 0

	# PRAGMA user_version を取得
	db.query("PRAGMA user_version")
	var result = db.get_query_result()

	if result != null and result.size() > 0:
		# 結果の形式に合わせて取得（辞書または配列）
		var row = result[0]
		if row is Dictionary:
			var ver = row.get("user_version", 0)
			return int(ver) if ver != null else 0
		elif row is Array and row.size() > 0:
			var ver = row[0]
			return int(ver) if ver != null else 0

	return 0

## データベースのバージョンを設定
func _set_db_version(version: int) -> void:
	if db == null:
		return

	db.query("PRAGMA user_version = %d" % version)
	print("[DatabaseManager] データベースバージョンを %d に更新しました" % version)

## データベースのバージョンチェックとマイグレーションを実行
func _check_and_migrate_db() -> void:
	var current_version = _get_db_version()
	print("[DatabaseManager] 現在のDBバージョン: %d, Launcher期待バージョン: %d" % [current_version, CURRENT_DB_VERSION])

	# バージョンが0の場合（新規作成時など）、本来はManagerで初期化すべきだが、
	# 万が一の場合はManagerに任せる方針とする（Launcherは基本Read-Onlyに近い）
	if current_version == 0:
		print("[DatabaseManager] Warning: DBバージョンが0です。Managerによる初期化が必要な可能性があります。")
		return

	# バージョンが新しい場合（将来のバージョン）
	if current_version > CURRENT_DB_VERSION:
		push_warning("[DatabaseManager] DBバージョン(%d)がLauncherの対応バージョン(%d)より新しいです。一部機能が正常に動作しない可能性があります。" % [current_version, CURRENT_DB_VERSION])
		return

	# マイグレーションが必要な場合（古いバージョン）
	if current_version < CURRENT_DB_VERSION:
		push_warning("[DatabaseManager] Warning: DBバージョン(%d)が古いです。Managerを起動してDBを更新することをお勧めします。" % current_version)

## 値を安全にintに変換する（null対策）
func safe_int(val, default_val: int = 0) -> int:
	if val == null:
		return default_val
	return int(val)

## 値を安全にboolに変換する（null対策）
func safe_bool(val, default_val: bool = false) -> bool:
	if val == null:
		return default_val
	# 数値（0 or 1）として扱われる場合が多いため、int経由で変換
	return bool(int(val))
