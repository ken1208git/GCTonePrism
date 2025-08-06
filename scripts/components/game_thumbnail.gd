# このスクリプトは、一つのゲームサムネイル（game_thumbnail.tscn）の見た目と動作を管理します。
extends Panel

# --- 自作の関数 ---

# このサムネイルに、表示すべきゲームの情報を設定するための、専用の関数。
func set_game_data(game_data: Dictionary) -> void:
	# この関数が呼び出された瞬間に、子である%TextureRectを、確実に見つけ出す。
	var texture_rect: TextureRect = %TextureRect
	
	# ゲーム情報の中から、サムネイル画像のパスを取得する。
	var thumbnail_path: String = game_data.get("thumbnail_path", "")
	
	if thumbnail_path.is_empty():
		return

	var games_dir_path: String = Global.launcher_config.get("games_directory", "")
	var game_id: String = game_data.get("game_id", "")
	
	var full_path = games_dir_path.path_join(game_id).path_join(thumbnail_path)
	var global_path = ProjectSettings.globalize_path(full_path)
	
	var image = Image.new()
	var error = image.load(global_path)
	
	if error != OK:
		print("エラー: 画像ファイルの読み込みに失敗しました - ", global_path)
		return
	
	var image_texture = ImageTexture.create_from_image(image)
	
	# この時点では、texture_rectは、もはや絶対にNilではない。
	texture_rect.texture = image_texture
