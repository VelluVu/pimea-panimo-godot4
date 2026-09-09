#AudioManager (Autoload)
extends Node

## Central audio playback. Never called directly by gameplay code — it only
## listens to the existing BrewerySignals/GUISignals/SpecialEventManager
## event bus, so brewing/customer/UI scripts stay audio-agnostic. Sounds
## themselves live in AudioBank (data), not here (logic).

const SFX_POOL_SIZE: int = 6
const MUSIC_BUS_NAME: StringName = &"Music"
const SFX_BUS_NAME: StringName = &"SFX"

const TENSION_DRONE_MAX_VOLUME_DB: float = -6.0
const TENSION_DRONE_MIN_VOLUME_DB: float = -80.0

@export var bank: AudioBank = preload("res://src/resources/audio/audio_bank.tres")

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_player_index: int = 0

var _music_player: AudioStreamPlayer
var _music_playlist: Array[AudioStream] = []
var _music_track_index: int = 0

var _tension_player: AudioStreamPlayer

var _last_money: int = -1
var _last_risk: int = -1


func _ready() -> void:
	_setup_sfx_pool()
	_setup_music_player()
	_setup_tension_player()
	_connect_signals()
	_start_music()


func _setup_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS_NAME
		add_child(player)
		_sfx_pool.append(player)


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS_NAME
	add_child(_music_player)
	_music_player.finished.connect(_on_music_track_finished)


func _setup_tension_player() -> void:
	_tension_player = AudioStreamPlayer.new()
	_tension_player.bus = SFX_BUS_NAME
	_tension_player.stream = bank.sfx_risk_tension_drone
	_tension_player.volume_db = TENSION_DRONE_MIN_VOLUME_DB
	add_child(_tension_player)


func _connect_signals() -> void:
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.avi_raid_triggered.connect(_on_avi_raid_triggered)
	SpecialEventManager.special_event_triggered.connect(_on_special_event_triggered)

	GUISignals.buy_ingredient.connect(_on_ui_action.unbind(2))
	GUISignals.sell_ingredient.connect(_on_ui_action.unbind(2))
	GUISignals.start_brewing.connect(_on_start_brewing)
	GUISignals.save_recipe_requested.connect(_on_ui_action)
	GUISignals.load_recipe_requested.connect(_on_ui_action.unbind(1))
	GUISignals.brewery_view_requested.connect(_on_ui_action)
	GUISignals.warehouse_view_opened.connect(_on_ui_action)
	GUISignals.recipe_library_requested.connect(_on_ui_action)
	GUISignals.options_requested.connect(_on_ui_action)


## Public API: fire-and-forget one-shot playback, round-robin across a small
## pool so overlapping sounds (e.g. two sales resolving close together)
## don't cut each other off the way a single shared AudioStreamPlayer would.
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := _acquire_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _acquire_sfx_player() -> AudioStreamPlayer:
	var player := _sfx_pool[_next_sfx_player_index]
	_next_sfx_player_index = (_next_sfx_player_index + 1) % _sfx_pool.size()
	return player


func _on_ui_action() -> void:
	play_sfx(bank.sfx_ui_click)


func _on_start_brewing() -> void:
	play_sfx(bank.sfx_brew_start)


func _on_style_discovered(_style: int) -> void:
	play_sfx(bank.sfx_style_discovered)


func _on_avi_raid_triggered(_confiscated_bottles: int, _fine_amount: int, _reputation_lost: int) -> void:
	play_sfx(bank.sfx_avi_alarm)


func _on_special_event_triggered(_event_data: SpecialEventData) -> void:
	play_sfx(bank.sfx_notification_ping)


func _on_brewery_state_changed(brewery: Brewery) -> void:
	if _last_money != -1 and brewery.money > _last_money:
		play_sfx(bank.sfx_coin_success)
	_last_money = brewery.money

	_update_tension(brewery.risk)


func _update_tension(risk: int) -> void:
	if risk == _last_risk:
		return
	_last_risk = risk

	var ratio := clampf(float(risk) / float(Brewery.AVI_RAID_THRESHOLD), 0.0, 1.0)
	_tension_player.volume_db = lerpf(TENSION_DRONE_MIN_VOLUME_DB, TENSION_DRONE_MAX_VOLUME_DB, ratio)

	if ratio > 0.0 and not _tension_player.playing:
		_tension_player.play()
	elif ratio <= 0.0 and _tension_player.playing:
		_tension_player.stop()


func _start_music() -> void:
	_music_playlist = bank.music_tracks.duplicate()
	_music_playlist.shuffle()
	_music_track_index = 0
	_play_current_track()


func _play_current_track() -> void:
	if _music_playlist.is_empty():
		return
	_music_player.stream = _music_playlist[_music_track_index]
	_music_player.play()


func _on_music_track_finished() -> void:
	if _music_playlist.is_empty():
		return
	_music_track_index = (_music_track_index + 1) % _music_playlist.size()
	_play_current_track()
