class_name CloseDayConfirmWindow
extends Panel

## Asks before closing the day while a customer is walking in or at the counter, whose sale
## would be cut off.

const TITLE_TEXT : String = "Asiakas on vielä baarissa"
const MESSAGE_TEXT : String = "Jos suljet nyt, asiakkaan kesken jäänyt kauppa peruuntuu."
const CONFIRM_TEXT : String = "Sulje silti"
const CANCEL_TEXT : String = "Peruuta"

@onready var title_label : Label = %TitleLabel
@onready var message_label : Label = %MessageLabel
@onready var confirm_button : Button = %ConfirmButton
@onready var cancel_button : Button = %CancelButton


func _ready() -> void:
	title_label.text = TITLE_TEXT
	message_label.text = MESSAGE_TEXT
	confirm_button.text = CONFIRM_TEXT
	cancel_button.text = CANCEL_TEXT

	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)


func _on_confirm_button_pressed() -> void:
	hide()
	GUISignals.close_day_requested.emit()


func _on_cancel_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()
