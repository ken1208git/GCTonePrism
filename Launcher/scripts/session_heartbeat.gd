## (#179 PR3b) Launcher LAN-wide session tracking 機構の heartbeat 出力 module。
##
## 学校 LAN 上で `toneprism.db` を SMB 共有運用するため、Manager が編集中に
## Launcher が SQLite read を継続すると file lock / WAL 競合で「DB を
## 開けません」error や Manager INSERT stall を起こす path がある。
## Manager 側 (PR #184) で `manager_sessions` table 経由の同時起動検出は
## 完成済だが、SPEC §6.5 で「Launcher は SQLite に直接 write しない」
## 原則があるため Launcher 側は JSON drop folder 方式で session を
## 通知する: 本 module が 10 秒周期で `<base>/responses/launcher_sessions/
## <pc_name>.json` に heartbeat JSON を atomic write、Manager 側
## `LauncherSessionService` が on-demand polling で読込 → 検出時は
## `SessionConflictDialog` で「他 PC で Launcher 稼働中」と警告。
##
## 設計詳細:
## - heartbeat 周期: 10 秒 (Manager `manager_sessions` と統一、SPEC §3.8.7)
## - atomic write: `<pc_name>.json.tmp` 仮書込 → rename
## - cleanup: `NOTIFICATION_PREDELETE` で self JSON 削除 (clean shutdown 即時反映)、
##   削除失敗 / crash 時は Manager 側 30 秒 stale timeout で fail-safe
## - fail-soft: 全 write 失敗で `push_warning` trail のみ、Launcher 起動 / ゲームプレイは止めない
##
## **log output 規約** (#85 移行待ち):
## - INFO: `print(...)` (= logger.gd L168 `_classify_godot_line` で「その他 → INFO」分類)
## - WARN: `push_warning(...)` (= 同 L169 「WARNING:/USER WARNING: → WARN」分類)
##
## 直接 `Logger.info/warn(...)` を呼べないのは Godot 4 の built-in `Logger` class と
## autoload `Logger` の名前衝突で GDScript パーサーが built-in に解決して static method
## lookup に失敗するため (logger.gd L10 同根問題)。#85 で Launcher 統一ログ基盤の
## sweep が完了したら本 module も明示 API に移行予定。
##
## 詳細仕様: SPECIFICATION.md §3.8.7 参照。
extends Node

const HEARTBEAT_INTERVAL_SECONDS: float = 10.0
const SESSIONS_SUBDIR: String = "responses/launcher_sessions"

var _session_file_path: String = ""
var _tmp_file_path: String = ""
var _pc_name: String = ""
var _started_at_unix_ms: int = 0
var _pid: int = 0
var _launcher_version: String = ""
var _timer: Timer = null
var _initialized: bool = false
var _init_failed: bool = false


func _ready() -> void:
	_initialize()


func _initialize() -> void:
	var base_dir = PathManager.get_base_directory()
	if base_dir.is_empty():
		push_warning("[SessionHeartbeat] base directory 不明、heartbeat 機構 disable")
		_init_failed = true
		return

	var sessions_dir = base_dir.path_join(SESSIONS_SUBDIR)
	if not DirAccess.dir_exists_absolute(sessions_dir):
		var err = DirAccess.make_dir_recursive_absolute(sessions_dir)
		if err != OK:
			push_warning("[SessionHeartbeat] sessions directory 作成失敗 (heartbeat 機構 disable): " + sessions_dir + ", err=" + str(err))
			_init_failed = true
			return

	# (#179 PR3b round 3 M-1) `_get_pc_name()` 結果を filename にする前に必ず sanitize する。
	# Windows NetBIOS computer name 規約では invalid path char は通常入らないが、
	# (a) `COMPUTERNAME` env var に malformed 値が injection される CI / testing path、
	# (b) HOSTNAME fallback (Linux/macOS) で `:` 等が許容される path、
	# が FileAccess.open silent 失敗 → 検出不能 になる drift を予防。
	# logger.gd:213-219 `_sanitize_filename` と同 logic (= sibling 整合性、helper 共通化は別 PR scope)。
	_pc_name = _get_pc_name()
	var safe_pc_name = _sanitize_filename(_pc_name)
	_session_file_path = sessions_dir.path_join(safe_pc_name + ".json")
	_tmp_file_path = _session_file_path + ".tmp"
	_started_at_unix_ms = int(Time.get_unix_time_from_system() * 1000)
	_pid = OS.get_process_id()
	_launcher_version = Version.get_version_number()

	# 初回 heartbeat write
	_write_session_json()

	# **ポーズ中も動かす** (レビュー H-1)。Timer は既定 (PROCESS_MODE_INHERIT) だと
	# `get_tree().paused` で止まるため、ダイアログ表示中は heartbeat が出なくなる。
	# Manager 側の生存判定は 60 秒 (`LauncherSessionService.StaleTimeoutSeconds`) なのに対し、
	# アンケートは無操作 90 秒 / 進捗なし 300 秒まで表示され続ける = **生きているキオスクが
	# Manager のダッシュボードから消える**。当日スタッフが「落ちた台」を見に走ることになる。
	# ポーズはあくまで画面の話で、プロセスは動いているのだから heartbeat は止めてはいけない。
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Timer 起動 (10 秒周期、autostart、繰り返し)
	_timer = Timer.new()
	# 親が ALWAYS でも明示しておく (このノードだけ切り出されたときに静かに止まらないように)。
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.wait_time = HEARTBEAT_INTERVAL_SECONDS
	_timer.autostart = true
	_timer.one_shot = false
	_timer.timeout.connect(_on_heartbeat_tick)
	add_child(_timer)

	_initialized = true
	print("[SessionHeartbeat] session 登録: pc=" + _pc_name + " pid=" + str(_pid) + " ver=" + _launcher_version + " path=" + _session_file_path)


func _on_heartbeat_tick() -> void:
	_write_session_json()


func _write_session_json() -> void:
	if _init_failed:
		return
	var now_ms = int(Time.get_unix_time_from_system() * 1000)
	var data = {
		"pc_name": _pc_name,
		"started_at_unix_ms": _started_at_unix_ms,
		"last_heartbeat_at_unix_ms": now_ms,
		"pid": _pid,
		"launcher_version": _launcher_version,
	}
	var json_str = JSON.stringify(data)

	# atomic write: .tmp に書込 → rename で atomic 反映
	var f = FileAccess.open(_tmp_file_path, FileAccess.WRITE)
	if f == null:
		push_warning("[SessionHeartbeat] heartbeat write 失敗 (open .tmp): path=" + _tmp_file_path + " err=" + str(FileAccess.get_open_error()))
		return
	f.store_string(json_str)
	f.close()

	var rename_err = DirAccess.rename_absolute(_tmp_file_path, _session_file_path)
	if rename_err != OK:
		push_warning("[SessionHeartbeat] heartbeat rename 失敗 (.tmp → .json): err=" + str(rename_err))
		# .tmp 残骸を best-effort 削除 (= 次回 heartbeat で再 write されるが残骸は掃除しておく)
		DirAccess.remove_absolute(_tmp_file_path)


func _notification(what: int) -> void:
	# NOTIFICATION_PREDELETE: ゲーム終了直前、autoload 解放 phase で発火。
	# WM_CLOSE_REQUEST は AppManager で intercept されうるため、cleanup は
	# PREDELETE のみで実装 (logger.gd の同型 pattern を踏襲、SPEC §3.8.7)。
	if what == NOTIFICATION_PREDELETE:
		if _initialized and not _session_file_path.is_empty():
			if FileAccess.file_exists(_session_file_path):
				var err = DirAccess.remove_absolute(_session_file_path)
				if err != OK:
					push_warning("[SessionHeartbeat] self session file 削除失敗 (Manager 側 30 秒 stale で fallback): path=" + _session_file_path + " err=" + str(err))
				else:
					print("[SessionHeartbeat] self session file 削除 (clean exit): pc=" + _pc_name)


func _get_pc_name() -> String:
	# COMPUTERNAME (Windows) → HOSTNAME (Linux/macOS) → "unknown" fallback。
	# logger.gd:204-210 と同 logic、helper 共通化は別 PR scope。
	var pc_name = OS.get_environment("COMPUTERNAME")
	if pc_name.is_empty():
		pc_name = OS.get_environment("HOSTNAME")
	if pc_name.is_empty():
		pc_name = "unknown"
	return pc_name


# (#179 PR3b round 3 M-1) filename safety 用 sanitize、logger.gd:213-219 と同 logic。
# Windows で path として禁止される文字を `_` 置換、helper 共通化 (= 両者で 1 関数化) は別 PR scope。
func _sanitize_filename(name: String) -> String:
	var invalid = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
	var result = name
	for c in invalid:
		result = result.replace(c, "_")
	return result
