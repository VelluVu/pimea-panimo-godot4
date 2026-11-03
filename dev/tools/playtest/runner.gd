extends SceneTree

## Headless playtest: starts a new run from the main menu and hands it to a bot.
## Started by playtest.py run; by hand:
## godot --headless --fixed-fps 60 --path <project> -s runner.gd -- --bot=<path> --strategy=greedy --out=<json>
## --season=<name> plays a season whatever the date says, as the console's cheats force it.

## Named season -> [SeasonRules.Season, winter]. Winter starts on 9 November, so it runs
## under Black Month and Cyber Week as it does on the calendar.
const SEASONS: Dictionary = {
	"none": [SeasonRules.Season.NONE, false],
	"halloween": [SeasonRules.Season.HALLOWEEN, false],
	"black_month": [SeasonRules.Season.BLACK_MONTH, true],
	"cyber_week": [SeasonRules.Season.CYBER_WEEK, true],
	"christmas": [SeasonRules.Season.CHRISTMAS, true],
	"winter": [SeasonRules.Season.NONE, true],
}

const GAME_SCENE: String = "res://src/scenes/main.tscn"
## A minute at 60 fps; a slow start still gets its bot.
const GAME_SCENE_WAIT_FRAMES: int = 3600

var cfg: Dictionary = {"strategy": "greedy", "max_days": "16", "speed": "4", "out": "", "bot": "", "season": "auto"}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			cfg[kv[0]] = kv[1]
	Engine.time_scale = float(cfg.speed)
	# Before the run starts, so season-known styles and seasonal customers are in from day one.
	if SEASONS.has(cfg.season):
		SeasonRules.force(SEASONS[cfg.season][0])
		SeasonRules.force_winter(SEASONS[cfg.season][1])
	elif cfg.season != "auto":
		push_error("Unknown --season=%s, playing the calendar's" % cfg.season)
	change_scene_to_file("res://src/scenes/ui/main_menu.tscn")
	_start.call_deferred()


func _start() -> void:
	for i: int in 20:
		await process_frame
	_press("Aloita peli")
	for i: int in 5:
		await process_frame
	_press("Aloita uusi peli")
	# Wait until the cellar is in place behind the fade before adding the bot.
	for i: int in GAME_SCENE_WAIT_FRAMES:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == GAME_SCENE:
			break
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
