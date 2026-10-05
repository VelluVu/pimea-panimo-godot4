extends SceneTree

## Headless playtest: starts a new run from the main menu and hands it to a bot.
## Started by playtest.py run; by hand:
## godot --headless --fixed-fps 60 --path <project> -s runner.gd -- --bot=<path> --strategy=greedy --out=<json>
## --modifier picks the run modifier card: 0 (the plain one, default), 1, 2, random or bot.

var cfg: Dictionary = {"strategy": "greedy", "modifier": "0", "max_days": "16", "speed": "4", "out": "", "bot": ""}


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
	for i: int in 10:
		await process_frame
	var card_name: String = "Card%d" % (_modifier_index() + 1)
	var cards: Array[Node] = root.find_children(card_name, "", true, false)
	if cards.is_empty():
		push_error("PLAYTEST: modifier card not found")
		quit(2)
		return
	cards[0].pressed.emit()
	for i: int in 20:
		await process_frame

	var bot: Node = Node.new()
	bot.set_script(load(cfg.bot))
	bot.cfg = cfg
	bot.name = "PlaytestBot"
	root.add_child(bot)


## The modifier card to pick, 0-based: a fixed index, "random", or "bot" to let the
## bot script's choose_modifier() rank the offered modifiers for its strategy.
func _modifier_index() -> int:
	if cfg.modifier != "random" and cfg.modifier != "bot":
		return int(cfg.modifier)
	var windows: Array[Node] = root.find_children("ModifierSelectWindow", "", true, false).filter(func(w: Node) -> bool: return w.visible)
	if windows.is_empty():
		push_error("PLAYTEST: modifier window not found")
		return 0
	var offered: Array = windows[0].get("_offered_modifiers")
	if cfg.modifier == "random":
		return randi() % offered.size()
	return load(cfg.bot).choose_modifier(cfg.strategy, offered)


func _press(text: String) -> void:
	for button: Node in root.find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			button.pressed.emit()
			return
