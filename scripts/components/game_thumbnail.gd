# 一つのゲームサムネイル（game_thumbnail.tscn）の見た目と動作を管理する
# menu.gdから表示すべきゲームの情報（game_data）を受け取り
# 対応するサムネイル画像を表示する責任を持つ
extends Panel

# --- 自作の関数 ---

# このサムネイルに表示すべきゲームの情報を設定するための専用関数
# menu.gdのループ処理の中からサムネイルが作られるたびに呼び出される
func set_game_data(game_data: Dictionary) -> void:
	# このサムネイル部品（Panel）の子である画像表示用のノード（TextureRect）を確実に見つけ出す
	# `%`記法はこのシーン内でのユニークな名前を持つノードへの簡単なアクセス方法
	var texture_rect: TextureRect = %TextureRect
	
	# ゲームデータの中からサムネイル画像のファイル名（例: "thumbnail.png"）を取得する
	var thumbnail_filename: String = game_data.get("thumbnail_path", "")
	
	# もしファイル名が設定されていなければ何も表示できないのでここで処理を終了する
	if thumbnail_filename.is_empty():
		return

	# ゲームデータにはGlobal.gdがスキャン時に追加してくれた
	# そのゲームのフォルダへの絶対パス（例: "C:/.../Games/galaxy_striker"）が既に入っている
	# これを直接利用するのが最も安全で効率的
	var game_dir_path: String = game_data.get("game_directory_path", "")
	if game_dir_path.is_empty():
		# 万が一このパスがなければ画像を見つけられないので処理を中断する
		return
	
	# ゲームフォルダの絶対パスとサムネイルのファイル名を結合して
	# 画像ファイルへの完全な絶対パスを組み立てる
	var full_path = game_dir_path.path_join(thumbnail_filename)
	
	# 画像を読み込む前にそのパスにファイルが本当に存在するかを確認する（安全装置）
	if not FileAccess.file_exists(full_path):
		Global.log_message(Global.LogLevel.WARNING, "サムネイル画像が見つかりません - %s" % full_path)
		return
	
	# まず画像ファイルを生の「画像データ」としてメモリに読み込む
	var image = Image.new()
	var error = image.load(full_path)
	
	# もし何らかの理由で読み込みに失敗したら（ファイルが壊れているなど）
	if error != OK:
		Global.log_message(Global.LogLevel.ERROR, "サムネイル画像の読み込みに失敗しました - %s" % full_path)
		return
	
	# 読み込んだ生の画像データからGodotが画面に表示できる「テクスチャ」を作成する
	var image_texture = ImageTexture.create_from_image(image)
	
	# 最後に作成したテクスチャをTextureRectノードに設定して画面に表示する
	texture_rect.texture = image_texture
