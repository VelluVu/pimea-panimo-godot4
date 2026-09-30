class_name AudioPlayback
extends Node

## Sound effects, music and UI clicks. Sound effects share a small pool so overlapping
## ones don't cut each other off; music is either one looping track or a shuffled
## playlist. Both keep playing while the tree is paused, since menus pause it. The
## project picks the buses, the click and what to play in its wiring subclass.

var sfx_bus: StringName = &"SFX"
var music_bus: StringName = &"Music"
var sfx_pool_size: int = 6
var click_stream: AudioStream
## Every button that enters the tree plays the click when pressed, so none is left silent.
var click_all_buttons: bool = true

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_player_index: int = 0

var _music_player: AudioStreamPlayer
var _playlist: Array[AudioStream] = []
var _playlist_index: int = 0
var _looping: bool = false

var _click_pending: bool = false
## The frame a sound other than the click last played, so the click can give way to it.
var _specific_sfx_frame: int = -1


func _ready() -> void:
	for i in range(sfx_pool_size):
		# A sound that is playing when a window pauses the tree would freeze until it
		# closes, which silences the click of every button that opens one.
		_sfx_pool.append(_add_player(sfx_bus))
	_music_player = _add_player(music_bus)
	_music_player.finished.connect(_on_music_finished)
	if click_all_buttons:
		get_tree().node_added.connect(_on_node_added)


## One-shot sound. A click requested in the same frame gives way to it.
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	_specific_sfx_frame = Engine.get_process_frames()
	_play_stream(stream, volume_db)


## Deferred to the end of the frame: one press can ask twice (the button and the signal
## it sends), and a more specific sound in the same frame replaces the click.
func play_click() -> void:
	if _click_pending:
		return
	_click_pending = true
	_flush_click.call_deferred()


## Loops one track. Keeps going, without restarting, if it is already the looping track.
func play_music_loop(stream: AudioStream) -> void:
	if _looping and _music_player.stream == stream and _music_player.playing:
		return
	_looping = true
	_music_player.stream = stream
	_music_player.play()


## Plays the tracks in a shuffled order, over and over.
func play_playlist(tracks: Array[AudioStream]) -> void:
	_looping = false
	_playlist = tracks.duplicate()
	_playlist.shuffle()
	_playlist_index = 0
	_play_playlist_track()


func is_playlist_playing() -> bool:
	return not _looping and _music_player.playing


func _add_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _play_stream(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := _sfx_pool[_next_sfx_player_index]
	_next_sfx_player_index = (_next_sfx_player_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _flush_click() -> void:
	_click_pending = false
	if _specific_sfx_frame != Engine.get_process_frames():
		_play_stream(click_stream)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play_click)


func _play_playlist_track() -> void:
	if _playlist.is_empty():
		return
	_music_player.stream = _playlist[_playlist_index]
	_music_player.play()


func _on_music_finished() -> void:
	if _looping:
		_music_player.play()
		return
	if _playlist.is_empty():
		return
	_playlist_index = (_playlist_index + 1) % _playlist.size()
	_play_playlist_track()
