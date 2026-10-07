extends SceneTree

## Headless playtest: starts a new run from the main menu and hands it to a bot.
## Started by playtest.py run; by hand:
## godot --headless --fixed-fps 60 --path <project> -s runner.gd -- --bot=<path> --strategy=greedy --out=<json>

var cfg: Dictionary = {"strategy": "greedy", "max_days": "16", "speed": "4", "out": "", "bot": ""}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			cfg[kv[0]] = kv[1]
	Engine.time_scale = float(cfg.speed)
	change_scene_to_file("res://src/scenes/ui/main_menu.tscn")
	_start.call_deferred()


func _start() -> void:
	for i: int in 20:
		await process_frame
	_press("Aloita peli")
	for i: int in 5:
		await process_frame
	_press("Aloita uusi peli")
	for i: int in 20:
		await process_frame

	var bot: Node = Node.new()
	bot.set_script(load(cfg.bot))
	bot.cfg = cfg
	bot.name = "PlaytestBot"
	root.add_child(bot)


func _press(text: String) -> void:
	for button: Node in root.find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			button.pressed.emit()
			return
