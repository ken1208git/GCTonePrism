## ゲーム・製作者データのクエリを担当
## DatabaseManager のDBインスタンスを使ってデータを取得する

extends RefCounted
class_name GameRepository

var _db_manager: DatabaseManager

func _init(db_manager: DatabaseManager) -> void:
	_db_manager = db_manager

## すべてのゲーム情報を取得（表示対象のみ）
func get_all_games() -> Array[GameInfo]:
	if not _db_manager.is_open():
		if not _db_manager.open():
			return []

	var games: Array[GameInfo] = []
	var query = "SELECT * FROM games WHERE is_visible = 1 ORDER BY title ASC"  # (#328) すべてのゲームは名前順（display_order でなく title）。Manager 一覧と概ね揃える（かな/英字は一致、漢字は照合差あり＝CHANGELOG #328 の既知差）

	if _db_manager.db.query(query):
		var result_array = _db_manager.db.get_query_result()
		if result_array != null:
			for row in result_array:
				if row is Dictionary:
					var game = _create_game_info_from_row_dict(row)
					if game != null:
						game.developers = get_developers_by_game_id(game.game_id)
						games.append(game)
	else:
		push_error("[GameRepository] ゲーム情報の取得に失敗しました")

	return games

## 指定したゲームIDのゲーム情報を取得
func get_game_by_id(game_id: String) -> GameInfo:
	if not _db_manager.is_open():
		if not _db_manager.open():
			return null

	var query = "SELECT * FROM games WHERE game_id = ?"
	var bindings = [game_id]

	if _db_manager.db.query_with_bindings(query, bindings):
		var result_array = _db_manager.db.get_query_result()
		if result_array != null and result_array.size() > 0:
			var row = result_array[0]
			if row is Dictionary:
				var game = _create_game_info_from_row_dict(row)
				if game != null:
					game.developers = get_developers_by_game_id(game.game_id)
					return game
		else:
			print("[GameRepository] ゲームが見つかりませんでした: ", game_id)
	else:
		push_error("[GameRepository] ゲーム情報の取得に失敗しました: " + game_id)

	return null

## 指定したゲームIDの製作者情報を取得
## 優先順位: ① 現行バージョン (games.version) に紐付いた製作者 → ② version_id IS NULL の製作者
## Manager の通常追加/更新フローでは version_id 無しで保存されるため、
## 「現行バージョン用に明示登録された製作者が無ければ NULL 行を使う」フォールバックを行う
func get_developers_by_game_id(game_id: String) -> Array[DeveloperInfo]:
	if not _db_manager.is_open():
		if not _db_manager.open():
			return []

	var versioned_query = """
		SELECT d.id, d.game_id, d.last_name, d.first_name, d.grade
		FROM developers d
		JOIN game_versions gv ON d.version_id = gv.id
		JOIN games g ON g.game_id = gv.game_id AND g.version = gv.version
		WHERE d.game_id = ?
		ORDER BY d.id ASC
	"""
	var developers = _query_developers(versioned_query, [game_id], game_id)
	if not developers.is_empty():
		return developers

	var fallback_query = """
		SELECT id, game_id, last_name, first_name, grade
		FROM developers
		WHERE game_id = ? AND version_id IS NULL
		ORDER BY id ASC
	"""
	return _query_developers(fallback_query, [game_id], game_id)

func _query_developers(query: String, bindings: Array, game_id: String) -> Array[DeveloperInfo]:
	var developers: Array[DeveloperInfo] = []
	if _db_manager.db.query_with_bindings(query, bindings):
		var result_array = _db_manager.db.get_query_result()
		if result_array != null:
			for row in result_array:
				if row is Dictionary:
					var developer = DeveloperInfo.new()
					developer.id = _db_manager.safe_int(row.get("id"), -1)
					developer.game_id = str(row.get("game_id", ""))
					developer.last_name = str(row.get("last_name", ""))
					developer.first_name = str(row.get("first_name", ""))
					developer.grade = "" if row.get("grade") == null else str(row.get("grade")) # (#313) 真NULL→""正規化("<null>"→int 0→教員 誤表示防止)
					developers.append(developer)
	else:
		push_error("[GameRepository] 製作者情報の取得に失敗しました: " + game_id)
	return developers

## データベースの行からGameInfoを作成
func _create_game_info_from_row_dict(row: Dictionary) -> GameInfo:
	var game = GameInfo.new()

	game.game_id = str(row.get("game_id", ""))
	game.title = str(row.get("title", ""))
	# (#318/#312) Manager の WinForms TextBox は改行を CRLF (\r\n) で保存するが、Godot の Label は \r を
	# 独立した改行として描画するため CRLF が 2 行ぶんに見える（#318 の初回説明と同根）。#312 で説明文欄に
	# AcceptsReturn を付けて Enter 改行を解禁したため、ゲーム説明にも CRLF が入りうる。読み込み層で LF へ
	# 正規化しておけば game_info_display など説明文の全表示経路を一括で守れる。
	game.description = str(row.get("description", "")).replace("\r\n", "\n").replace("\r", "\n")
	game.thumbnail_path = str(row.get("thumbnail_path", ""))
	game.background_path = str(row.get("background_path", ""))
	game.executable_path = str(row.get("executable_path", ""))
	game.controls = str(row.get("controls", ""))
	game.key_mapping = str(row.get("key_mapping", ""))
	game.arguments = str(row.get("arguments", ""))

	game.release_year = _db_manager.safe_int(row.get("release_year"), -1)
	game.min_players = _db_manager.safe_int(row.get("min_players"), -1)
	game.max_players = _db_manager.safe_int(row.get("max_players"), -1)
	game.difficulty = _db_manager.safe_int(row.get("difficulty"), -1)
	game.play_time = _db_manager.safe_int(row.get("play_time"), -1)
	game.display_order = _db_manager.safe_int(row.get("display_order"), -1)
	game.supported_connection = _db_manager.safe_int(row.get("supported_connection"), 0)
	# (#297 PR2) SELECT * なので v24 以降の DB では自動的に含まれる。v24 未満 / 未採番は -1 のまま。
	game.game_no = _db_manager.safe_int(row.get("game_no"), -1)

	game.controller_support = _db_manager.safe_bool(row.get("controller_support"), false)
	game.is_visible = _db_manager.safe_bool(row.get("is_visible"), true)

	game.genre = _parse_genre("" if row.get("genre") == null else str(row.get("genre")))  # (#327) 真NULL→""("<null>"タグ防止)

	return game

## ジャンル文字列をパース（JSON形式またはカンマ区切り）
func _parse_genre(genre_str: String) -> Array[String]:
	if genre_str.is_empty():
		return []

	var json = JSON.new()
	var parse_result = json.parse(genre_str)
	if parse_result == OK:
		var parsed = json.data
		if parsed is Array:
			var result: Array[String] = []
			for item in parsed:
				if item is String:
					result.append(item)
			return result

	var genres: Array[String] = []
	var parts = genre_str.split(",")
	for part in parts:
		var trimmed = part.strip_edges()
		if not trimmed.is_empty():
			genres.append(trimmed)

	return genres
