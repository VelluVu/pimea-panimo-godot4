class_name CloseDayConfirmWindow
extends Panel

## Guards against silently losing an in-progress sale: closing the day while
## a customer is still walking in or at the counter used to advance the day
## immediately with no warning, cutting off a sale that hadn't resolved yet.

const TITLE_TEXT : String = "Asiakas on vielä baarissa"
const MESSAGE_TEXT : String = "Jos suljet nyt, asiakkaan kesken jäänyt kauppa peruuntuu."
const CONFIRM_TEXT : String = "Sulje silti"
const CANCEL_TEXT : String = "Peruuta"

@onready var title_label : Label = $MarginContainer/MainVBox/TitleLabel
@onready var message_label : Label = $MarginContainer/MainVBox/MessageLabel
@onready var confirm_button : Button = $MarginContainer/MainVBox/ButtonsHBox/ConfirmButton
@onready var cancel_button : Button = $MarginContainer/MainVBox/ButtonsHBox/CancelButton


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
	hide()
