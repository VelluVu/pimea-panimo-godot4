class_name KegWashWindow
extends Control

## The keg wash minigame. Clicking the dirty keg pile opens it: the dirty kegs come up one
## at a time, and each finished one goes back to the cellar as clean as it was left
## (GUISignals.keg_wash_finished). Valmis takes the keg as it is now; Lopeta pesu (or Esc)
## stops, and the keg on the table goes back to the pile unwashed. The game is paused
## meanwhile, and level-up cards wait until it closes.

const HEADER_TEXT : String = "TYNNYRIN PESU · %d/%d"
const HINT_TEXT : String = "Hankaa harjalla, huuhtele letkulla ja viimeistele suihkeella."
const CLEANLINESS_TEXT : String = "Puhtaus %d %%"
const FINISH_BUTTON_TEXT : String = "VALMIS"
const STOP_BUTTON_TEXT : String = "Lopeta pesu"

const BACKDROP_COLOR : Color = Color(0.03, 0.02, 0.04, 0.97)
const FINISH_BUTTON_RECT : Rect2 = Rect2(520, 318, 108, 28)
const CLEANLINESS_POSITION : Vector2 = Vector2(12, 326)
## A keg washed this little is not worth taking off the table yet.
const MIN_FINISH_CLEANLINESS : float = 0.05
## The finished keg stays in view this long before the next one.
const NEXT_KEG_DELAY : float = 1.2
const POPUP_ORIGIN : Vector2 = Vector2(320, 120)
## The hint keeps clear of Lopeta pesu at the top left.
const HINT_MARGIN : float = 96.0

## The one-shot sounds, played by the audio wiring through GUISignals.keg_wash_sound.
const SOUND_LOOSENED : StringName = &"loosened"
const SOUND_REMOVED : StringName = &"removed"
const SOUND_FLED : StringName = &"fled"
const SOUND_TOOL : StringName = &"tool"
const SOUND_DONE : StringName = &"done"

var _view : KegWashView
var _session : KegWashSession
var _rng : RandomNumberGenerator = RandomNumberGenerator.new()
var _header : Label
var _hint : Label
var _cleanliness_label : Label
var _finish_button : Button
var _stop_button : Button
var _popups : BrewDayPopups
var _keg_number : int = 0
var _keg_total : int = 0
var _mistake_wait : Dictionary = {} # KegWashSession.Mistake -> seconds
var _next_keg_wait : float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	_build()
	hide()
	GUISignals.keg_wash_requested.connect(open)


func open() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or visible or brewery.inventory.dirty_keg_count() == 0:
		return
	_keg_total = brewery.inventory.dirty_keg_count()
	_keg_number = 0
	show()
	move_to_front()
	PauseLock.hold(self)
	GUISignals.keg_wash_opened.emit()
	_next_keg()


func _close() -> void:
	_session = null
	_view.session = null
	_next_keg_wait = -1.0
	_popups.clear()
	hide()
	PauseLock.release(self)
	GUISignals.keg_wash_closed.emit()


func _next_keg() -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null or _keg_number >= _keg_total or brewery.inventory.dirty_keg_count() == 0:
		_close()
		return
	_keg_number += 1
	_header.text = tr(HEADER_TEXT) % [_keg_number, _keg_total]
	_session = KegWashSession.create(_rng)
	_session.spot_loosened.connect(func(spot : KegWashSpot) -> void:
		_view.flash(spot)
		GUISignals.keg_wash_sound.emit(SOUND_LOOSENED))
	_session.spot_removed.connect(func(spot : KegWashSpot) -> void:
		_view.flash(spot)
		GUISignals.keg_wash_sound.emit(SOUND_REMOVED))
	_session.critter_fled.connect(func(_spot : KegWashSpot) -> void: GUISignals.keg_wash_sound.emit(SOUND_FLED))
	_session.stain_cleared.connect(func(_stain : KegWashStain) -> void: GUISignals.keg_wash_sound.emit(SOUND_REMOVED))
	_session.mistake.connect(_on_mistake)
	_session.completed.connect(_on_completed)
	_view.session = _session
	_view.reset()
	_mistake_wait.clear()
	_finish_button.disabled = true
	_hint.show()


func _process(delta : float) -> void:
	if not visible:
		return
	for kind : Variant in _mistake_wait.keys():
		_mistake_wait[kind] -= delta
	if _session != null:
		var cleanliness : float = _session.cleanliness()
		_cleanliness_label.text = tr(CLEANLINESS_TEXT) % roundi(cleanliness * 100.0)
		_finish_button.disabled = _session.is_completed or cleanliness < MIN_FINISH_CLEANLINESS
	if _next_keg_wait >= 0.0:
		_next_keg_wait -= delta
		if _next_keg_wait < 0.0:
			_next_keg()


## Keys stop here, so Esc closes the wash instead of opening the game menu over it.
func _input(event : InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed(InputManager.ACTION_CANCEL):
		_close()


func _on_mistake(kind : KegWashSession.Mistake) -> void:
	if float(_mistake_wait.get(kind, 0.0)) > 0.0:
		return
	_mistake_wait[kind] = KegWashLines.MISTAKE_COOLDOWN
	_popups.show_line(KegWashLines.mistake_text(kind), BrewDayPopups.BAD_COLOR)


func _on_completed() -> void:
	_popups.show_call(KegWashLines.FINISHED_TEXT, BrewDayPopups.GOOD_COLOR)
	GUISignals.keg_wash_sound.emit(SOUND_DONE)
	_take_keg(KegRules.CLEAN)


func _on_finish_pressed() -> void:
	if _session == null or _session.is_completed:
		return
	_take_keg(_session.cleanliness())


## The keg on the table is done: it goes back to the cellar this clean.
func _take_keg(cleanliness : float) -> void:
	GUISignals.keg_wash_finished.emit(cleanliness)
	_finish_button.disabled = true
	_next_keg_wait = NEXT_KEG_DELAY
	if _session != null and not _session.is_completed:
		_session.is_completed = true


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_view = KegWashView.new()
	add_child(_view)
	_view.tool_changed.connect(func(tool : KegWashView.Tool) -> void:
		if tool != KegWashView.Tool.NONE:
			_hint.hide()
		GUISignals.keg_wash_sound.emit(SOUND_TOOL))

	_header = Label.new()
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_header.position.y = 6
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)

	_hint = Label.new()
	_hint.text = HINT_TEXT
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Wraps, so the label never grows wider than the screen and slides off centre.
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.position = Vector2(HINT_MARGIN, 22)
	_hint.size = Vector2(640 - 2.0 * HINT_MARGIN, 0)
	_hint.modulate = ThermoColumn.DIM_COLOR
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_cleanliness_label = Label.new()
	_cleanliness_label.position = CLEANLINESS_POSITION
	_cleanliness_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cleanliness_label)

	_finish_button = Button.new()
	_finish_button.text = FINISH_BUTTON_TEXT
	_finish_button.position = FINISH_BUTTON_RECT.position
	_finish_button.size = FINISH_BUTTON_RECT.size
	_finish_button.focus_mode = Control.FOCUS_NONE
	_finish_button.pressed.connect(_on_finish_pressed)
	add_child(_finish_button)

	_stop_button = Button.new()
	_stop_button.text = STOP_BUTTON_TEXT
	_stop_button.position = Vector2(8, 6)
	_stop_button.focus_mode = Control.FOCUS_NONE
	_stop_button.pressed.connect(func() -> void:
		GUISignals.menu_button_pressed.emit()
		_close())
	add_child(_stop_button)

	_popups = BrewDayPopups.new()
	add_child(_popups)
	_popups.origin = POPUP_ORIGIN
	_popups.bounds = Rect2(8, 0, 624, 360)
