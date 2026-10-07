class_name AudioWiring
extends AudioPlayback

## This project's sounds: the one file to edit after copying the audio system. It picks
## the music per scene, maps the game's signals to sounds from its AudioBank and runs
## the LVV risk drone. The game's AudioManager autoload extends this.

const TENSION_DRONE_MAX_VOLUME_DB: float = -6.0
const TENSION_DRONE_MIN_VOLUME_DB: float = -80.0
## Automated test runs create this (gitignored) file to play silently. Players never have it.
const TEST_MUTE_FLAG_PATH: String = "res://dev/mute_audio.flag"
const MASTER_BUS: StringName = &"Master"

## Varied pitch so several glasses breaking in a row don't sound identical.
const SHATTER_PITCH_RANGE: Vector2 = Vector2(0.6, 0.85)
const FOOTSTEP_PITCH_RANGE: Vector2 = Vector2(0.85, 1.15)
const FOOTSTEP_VOLUME_DB: float = -10.0
## A whole group walking in would otherwise drum every frame.
const FOOTSTEP_MIN_GAP_MSEC: int = 60
const BABBLE_VOLUME_DB: float = -4.0
const BABBLE_PITCH_JITTER: float = 0.05
const POUR_VOLUME_DB: float = -3.0
## A group's serving burst runs the pour at 3x; full pitch would sound like a chipmunk.
const POUR_MAX_PITCH: float = 1.4
const TOAST_VOLUME_DB: float = -6.0

var bank: AudioBank = preload("res://src/resources/audio/audio_bank.tres")

var _tension_player: AudioStreamPlayer
var _last_money: float = -1.0
var _last_risk: int = -1
var _last_footstep_msec: int = -FOOTSTEP_MIN_GAP_MSEC
## Several toasts in one frame (a burst of unlocks) blip once.
var _last_toast_frame: int = -1


func _init() -> void:
	sfx_bus = &"SFX"
	music_bus = &"Music"
	click_stream = bank.sfx_ui_click


func _ready() -> void:
	super()
	_setup_tension_player()
	_connect_signals()
	get_tree().scene_changed.connect(_on_scene_changed)
	# The first scene is not current yet while autoloads run _ready().
	_on_scene_changed.call_deferred()
	if FileAccess.file_exists(TEST_MUTE_FLAG_PATH):
		# Deferred: SettingsManager starts after this autoload and applies the saved volumes.
		AudioServer.set_bus_mute.call_deferred(AudioServer.get_bus_index(MASTER_BUS), true)


## The main menu always loops its own track. Entering a run switches to the shuffled
## playlist, which keeps going across a restart from the game end window.
func _on_scene_changed() -> void:
	if get_tree().current_scene is MainMenu:
		play_music_loop(bank.menu_music)
	elif not is_playlist_playing():
		play_playlist(bank.music_tracks)


func _setup_tension_player() -> void:
	_tension_player = AudioStreamPlayer.new()
	_tension_player.bus = sfx_bus
	_tension_player.stream = bank.sfx_risk_tension_drone
	_tension_player.volume_db = TENSION_DRONE_MIN_VOLUME_DB
	add_child(_tension_player)


func _connect_signals() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.style_discovered.connect(play_sfx.bind(bank.sfx_style_discovered).unbind(1))
	BrewerySignals.lvv_raid_triggered.connect(play_sfx.bind(bank.sfx_lvv_alarm).unbind(3))
	SpecialEventManager.special_event_triggered.connect(play_sfx.bind(bank.sfx_notification_ping).unbind(1))
	MetaProgressManager.talent_purchased.connect(play_sfx.bind(bank.sfx_talent_purchased).unbind(1))
	GUISignals.start_brewing.connect(play_sfx.bind(bank.sfx_brew_start))
	BrewerySignals.customer_stepped.connect(_on_customer_stepped)
	BrewerySignals.customer_spoke.connect(_on_customer_spoke)
	BrewerySignals.beer_poured.connect(func(at: Vector2, speed_scale: float) -> void: play_sfx_at(bank.sfx_pour, at, POUR_VOLUME_DB, minf(speed_scale, POUR_MAX_PITCH)))
	BrewerySignals.group_visit_announced.connect(play_sfx.bind(bank.sfx_group_banner).unbind(1))
	GUISignals.toast_shown.connect(_on_toast_shown)
	GUISignals.day_event_banner_shown.connect(_on_day_event_banner_shown)
	# Not placed in the world: like the popup it belongs to, it should be heard at once.
	BrewerySignals.critical_gain_shown.connect(play_sfx.bind(bank.sfx_critical_gain).unbind(1))
	BrewerySignals.glass_shattered.connect(func() -> void: play_sfx(bank.sfx_glass_shatter, 0.0, randf_range(SHATTER_PITCH_RANGE.x, SHATTER_PITCH_RANGE.y)))

	# Buttons click on their own; these also cover keyboard shortcuts that open things.
	for ui_signal: Signal in [
		GUISignals.save_recipe_requested,
		GUISignals.brewery_view_requested,
		GUISignals.warehouse_view_opened,
		GUISignals.recipe_library_requested,
		GUISignals.options_requested,
		GUISignals.options_closed,
		GUISignals.leaderboard_requested,
		GUISignals.leaderboard_closed,
		GUISignals.menu_button_pressed,
		GUISignals.olutoppi_requested,
		GUISignals.olutoppi_closed,
		GUISignals.achievements_requested,
		GUISignals.achievements_closed,
		GUISignals.game_menu_requested,
		GUISignals.game_menu_closed,
		GUISignals.run_effects_requested,
		GUISignals.receipt_log_requested,
		GUISignals.customer_book_requested,
		GUISignals.window_closed,
		GUISignals.tab_switched,
	]:
		ui_signal.connect(play_click)
	GUISignals.load_recipe_requested.connect(play_click.unbind(1))
	for amount_signal: Signal in [
		GUISignals.buy_ingredient,
		GUISignals.sell_ingredient,
		GUISignals.add_ingredient_to_brew_preparation,
		GUISignals.remove_ingredients_from_brew_preparation,
	]:
		amount_signal.connect(play_click.unbind(2))


func _on_customer_stepped(at: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_footstep_msec < FOOTSTEP_MIN_GAP_MSEC:
		return
	_last_footstep_msec = now
	play_sfx_at(bank.sfx_footstep, at, FOOTSTEP_VOLUME_DB, randf_range(FOOTSTEP_PITCH_RANGE.x, FOOTSTEP_PITCH_RANGE.y))


func _on_customer_spoke(at: Vector2, voice_pitch: float) -> void:
	if bank.sfx_babbles.is_empty():
		return
	var pitch: float = voice_pitch * randf_range(1.0 - BABBLE_PITCH_JITTER, 1.0 + BABBLE_PITCH_JITTER)
	play_sfx_at(bank.sfx_babbles.pick_random(), at, BABBLE_VOLUME_DB, pitch)


func _on_toast_shown() -> void:
	var frame: int = Engine.get_process_frames()
	if frame != _last_toast_frame:
		_last_toast_frame = frame
		play_sfx(bank.sfx_toast, TOAST_VOLUME_DB)


func _on_day_event_banner_shown(event: DayEventData) -> void:
	play_sfx(event.announcement_sound if event.announcement_sound != null else bank.sfx_day_event)


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if _last_money != -1 and brewery.money > _last_money:
		play_sfx(bank.sfx_coin_success)
	_last_money = brewery.money
	_update_tension(brewery.risk)


## The drone fades in with the LVV risk, reaching full volume at the raid threshold.
func _update_tension(risk: int) -> void:
	if risk == _last_risk:
		return
	_last_risk = risk

	var raid_threshold: int = Brewery.LVV_RAID_THRESHOLD
	var brewery := BrewEngine.current_brewery
	if brewery != null:
		raid_threshold = brewery.get_effective_raid_threshold()
	var ratio := clampf(float(risk) / float(raid_threshold), 0.0, 1.0)
	_tension_player.volume_db = lerpf(TENSION_DRONE_MIN_VOLUME_DB, TENSION_DRONE_MAX_VOLUME_DB, ratio)

	if ratio > 0.0 and not _tension_player.playing:
		_tension_player.play()
	elif ratio <= 0.0 and _tension_player.playing:
		_tension_player.stop()
