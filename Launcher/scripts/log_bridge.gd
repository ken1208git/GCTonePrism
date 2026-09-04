## Launcher 内から autoload `Logger` へレベル明示でログを出すための橋渡し。
##
## **なぜ要るか**: Godot 4 には組み込みの `Logger` クラスがあり、GDScript から `Logger.info()` と
## 書くと autoload ではなくそちらに解決されてしまう。そのため各所で `/root/Logger` を
## `get_node_or_null` して呼ぶ必要があるが、これを呼び出し側ごとに書くと (a) `RefCounted` や
## static 関数からは `get_node` が使えず結局 `print` に落ちる、(b) 「Logger は呼べない」という
## 誤った理解がコメントごとコピーされて広がる、の 2 つが起きる (実際に起きた)。
##
## `Engine.get_main_loop()` 経由で解決するので **Node でなくても・static からでも呼べる**。
##
## **なぜ `print` / `push_warning` のままにしないか** (AGENTS.md「Cross-component Standards」):
## それらは Godot 標準ログへ出た後、`Logger` の 0.5 秒ポーリングのテールで拾われて初めて
## セッションログに載る。つまり (1) レベルを指定できない (WARN/ERROR の選別を放棄する)、
## (2) 反映が遅れる、(3) 行が `[Godot]` prefix 付きになる、という 3 点で劣る。
## 診断画面が WARN を拾って表示する以上、レベルは呼び出し側が明示すべき。
##
## Logger 自体が居ない / 壊れている場合は標準出力へ落とす (ログのために機能を止めない)。
class_name LogBridge
extends RefCounted


## autoload の Logger を取り出す (見つからなければ null)。
static func _logger() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Logger")
	return null


static func info(message: String) -> void:
	var logger := _logger()
	if logger != null and logger.has_method("info"):
		logger.info(message)
	else:
		print(message)


static func warn(message: String) -> void:
	var logger := _logger()
	if logger != null and logger.has_method("warn"):
		logger.warn(message)
	else:
		push_warning(message)


static func error(message: String) -> void:
	var logger := _logger()
	if logger != null and logger.has_method("error"):
		logger.error(message)
	else:
		push_error(message)
