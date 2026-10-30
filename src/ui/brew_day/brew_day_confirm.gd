class_name BrewDayConfirm
extends Panel

## "Perutaanko keittopäivä?" over the brew day. Peru keitto ends the day with the table
## kept; Jatka (or the window's Esc) carries on.

signal cancel_confirmed
signal resume_requested

const CONFIRM_CANCEL_TEXT : String = "Perutaanko keittopäivä? Raaka-aineet jäävät pöydälle."
const CONFIRM_YES_TEXT : String = "Peru keitto"
const CONFIRM_NO_TEXT : String = "Jatka"
const PANEL_SIZE : Vector2 = Vector2(320, 88)
const SCREEN_SIZE : Vector2 = Vector2(640, 360)


func _ready() -> void:
	size = PANEL_SIZE
	position = ((SCREEN_SIZE - size) / 2.0).round()
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(box)
	var label := Label.new()
	label.text = CONFIRM_CANCEL_TEXT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var yes := Button.new()
	yes.text = CONFIRM_YES_TEXT
	yes.pressed.connect(func() -> void:
		GUISignals.menu_button_pressed.emit()
		cancel_confirmed.emit())
	row.add_child(yes)
	var no := Button.new()
	no.text = CONFIRM_NO_TEXT
	no.pressed.connect(resume_requested.emit)
	row.add_child(no)
	hide()
