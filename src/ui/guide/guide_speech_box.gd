class_name GuideSpeechBox
extends Panel

## Vanha mestari Aatu's speech box: his portrait, the line typed out while his mouth
## moves, and the buttons. Lays itself out from its size: wide puts the buttons at the
## right, narrow (the strip beside the recipe book) stacks everything.

signal skipped
signal next_pressed
signal line_typed

const NAME_TEXT : String = "Vanha mestari Aatu"
const SKIP_BUTTON_TEXT : String = "Ohita opas"
const NEXT_BUTTON_TEXT : String = "Jatka"
const PORTRAIT : Texture2D = preload("res://assets/textures/characters/vanha_mestari_portrait_48.png")
const PORTRAIT_SIZE : Vector2 = Vector2(48, 48)
const PADDING : float = 4.0
const GAP : float = 4.0
const NAME_HEIGHT : float = 12.0
const BUTTON_WIDTH : float = 80.0
## Below this width the box stacks portrait, text and buttons.
const NARROW_WIDTH : float = 160.0
const NAME_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # the goals panel's gold
## Tighter lines, so three fit under the name in the bottom strip.
const LINE_SPACING : int = -4
const CHARACTERS_PER_SECOND : float = 45.0
## The mouth opens and shuts in whole steps while the line types.
const MOUTH_SECONDS : float = 0.12
## An old man's babble, a little lower than the papparainen customer's 0.8.
const VOICE_PITCH : float = 0.75
## A new babble about as each clip ends, while the line types.
const BABBLE_SECONDS : float = 0.8

var _portrait_frame : AtlasTexture = AtlasTexture.new()
var _portrait : TextureRect
var _name : Label
var _line : Label
var _next : Button
var _skip : Button
var _typed : float = 0.0
var _mouth_time : float = 0.0
var _babble_time : float = 0.0


func _ready() -> void:
	# The recipe book pauses the game while Aatu talks beside it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_portrait_frame.atlas = PORTRAIT
	_set_mouth(false)
	_portrait = TextureRect.new()
	_portrait.texture = _portrait_frame
	_portrait.size = PORTRAIT_SIZE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)

	_name = Label.new()
	_name.text = NAME_TEXT
	_name.modulate = NAME_COLOR
	add_child(_name)

	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_line.add_theme_constant_override("line_spacing", LINE_SPACING)
	add_child(_line)

	_next = _make_button(NEXT_BUTTON_TEXT, next_pressed)
	_next.hide()
	_skip = _make_button(SKIP_BUTTON_TEXT, skipped)
	resized.connect(_layout)
	_layout()
	set_process(false)


## A new line starts typing from the beginning; the same line again changes nothing.
## `can_continue` shows Jatka; `can_skip` false hides Ohita opas.
func say(text : String, can_continue : bool = false, can_skip : bool = true) -> void:
	_next.visible = can_continue
	_skip.visible = can_skip
	_layout()
	if text == _line.text:
		return
	_line.text = text
	_line.visible_characters = 0
	_typed = 0.0
	_mouth_time = 0.0
	_babble_time = 0.0
	GUISignals.guide_spoke.emit(VOICE_PITCH)
	set_process(true)


func is_typing() -> bool:
	return is_processing()


## Next time say() is given the same line, it types it again.
func forget_line() -> void:
	_line.text = ""


func _process(delta : float) -> void:
	_typed += delta * CHARACTERS_PER_SECOND
	_mouth_time += delta
	var total : int = _line.get_total_character_count()
	_line.visible_characters = mini(int(_typed), total)
	var talking : bool = _line.visible_characters < total
	_set_mouth(talking and int(_mouth_time / MOUTH_SECONDS) % 2 == 0)
	_babble_time += delta
	if talking and _babble_time >= BABBLE_SECONDS:
		_babble_time = 0.0
		GUISignals.guide_spoke.emit(VOICE_PITCH)
	if not talking:
		set_process(false)
		line_typed.emit()


func _layout() -> void:
	if _line == null:
		return
	var buttons : Array[Button] = []
	for button : Button in [_next, _skip]:
		if button.visible:
			buttons.append(button)
	var button_height : float = _skip.get_combined_minimum_size().y
	var stack_height : float = buttons.size() * button_height + maxf(0.0, buttons.size() - 1) * GAP
	if size.x < NARROW_WIDTH:
		_portrait.position = Vector2(((size.x - PORTRAIT_SIZE.x) / 2.0), PADDING).round()
		var text_top : float = PADDING + PORTRAIT_SIZE.y + GAP
		# The name wraps on two lines in the narrow strip.
		# Unclipped: clipping counts the line spacing too and drops the second line.
		var name_height : float = _name.get_line_height() * 2.0
		_name.clip_text = false
		_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_name.position = Vector2(PADDING, text_top)
		_name.size = Vector2(size.x - PADDING * 2.0, name_height)
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_line.position = Vector2(PADDING, text_top + name_height + GAP * 2.0)
		_line.size = Vector2(size.x - PADDING * 2.0, size.y - _line.position.y - stack_height - PADDING - GAP)
		var y : float = size.y - PADDING - stack_height
		for button : Button in buttons:
			button.position = Vector2(PADDING, y)
			button.size = Vector2(size.x - PADDING * 2.0, button_height)
			y += button_height + GAP
		return
	_portrait.position = Vector2(PADDING, ((size.y - PORTRAIT_SIZE.y) / 2.0)).round()
	var text_x : float = PADDING + PORTRAIT_SIZE.x + GAP * 2.0
	# The text ends before the buttons at the right edge.
	var text_width : float = size.x - text_x - BUTTON_WIDTH - PADDING - GAP * 2.0
	_name.clip_text = true
	_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name.position = Vector2(text_x, PADDING - 3.0)
	_name.size = Vector2(text_width, NAME_HEIGHT)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_line.position = Vector2(text_x, PADDING + NAME_HEIGHT - 2.0)
	_line.size = Vector2(text_width, size.y - _line.position.y - PADDING)
	var top : float = ((size.y - stack_height) / 2.0)
	for button : Button in buttons:
		button.position = Vector2(size.x - BUTTON_WIDTH - PADDING, top).round()
		button.size = Vector2(BUTTON_WIDTH, button_height)
		top += button_height + GAP


func _make_button(text : String, pressed_signal : Signal) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		GUISignals.menu_button_pressed.emit()
		pressed_signal.emit())
	add_child(button)
	return button


func _set_mouth(open : bool) -> void:
	_portrait_frame.region = Rect2(Vector2(PORTRAIT_SIZE.x if open else 0.0, 0.0), PORTRAIT_SIZE)
