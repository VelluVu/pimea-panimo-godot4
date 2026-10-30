class_name LvvRaidWindow
extends Panel


@onready var title_label : Label = %TitleLabel
@onready var message_label : Label = %MessageLabel
@onready var close_button : Button = %CloseButton


func _ready() -> void:
	title_label.text = StringContainer.LVV_RAID_TITLE
	close_button.text = StringContainer.LVV_RAID_CLOSE_TEXT

	close_button.pressed.connect(_on_close_button_pressed)
	WindowCloseButton.attach(self, _on_close_button_pressed)
	# The recap waits for the raid squad to leave, not the raid itself.
	BrewerySignals.lvv_raid_recap_ready.connect(_on_lvv_raid_recap_ready)


func _on_lvv_raid_recap_ready(confiscated_bottles : int, fine_amount : float, reputation_lost : int) -> void:
	message_label.text = tr(StringContainer.LVV_RAID_MESSAGE) % [confiscated_bottles, NumberText.money(fine_amount), reputation_lost]
	show()


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


## Esc does what the X does, and is used up here so the game menu does not open over it.
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
