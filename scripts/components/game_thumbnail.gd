# このスクリプトは、一つのゲームサムネイル（game_thumbnail.tscn）の見た目と動作を管理します。
extends Panel

# --- 自作の関数 ---

# このサムネイルに、表示すべきゲームの情報を設定するための、専用の関数。
func set_game_data(game_data: Dictionary) -> void:
	# この関数が呼び出された瞬間に、子である%TextureRectを、確実に見つけ出す。
	var texture_rect: TextureRect = %TextureRect
	
	# ゲーム情報の中から、サムネイル画像のパスを取得する。
	var thumbnail_path: String = game_data.get("thumbnail_path", "")
	
	# もし、パスが空っぽなら、ここで処理を終了する。
	if thumbnail_path.is_empty():
		return

	# ゲームのベースとなるディレクトリのパスを、configファイルから取得する。
	var games_dir_path: String = Global.launcher_config.get("games_directory", "")
	
	# ゲームのID（=フォルダ名）を取得する。
	var game_id: String = game_data.get("game_id", "")
	
	# すべてを連結して、画像ファイルへの、Godotの内部パスを組み立てる。
	var full_path = games_dir_path.path_join(game_id).path_join(thumbnail_path)
	
	# Image.load()は、"res://"から始まるパスを、正しく解釈できる。
	var image = Image.new()
	var error = image.load(full_path)
	
	# もし、読み込みに失敗したら（ファイルが存在しない、など）
	if error != OK:
		print("エラー: 画像ファイルの読み込みに失敗しました - ", full_path)
		return
	
	# 読み込んだ生の画像データから、Godotが画面に表示できるテクスチャを作成する。
	var image_texture = ImageTexture.create_from_image(image)
	
	# 作成したテクスチャを、TextureRectに設定する。
	texture_rect.texture = image_texture
