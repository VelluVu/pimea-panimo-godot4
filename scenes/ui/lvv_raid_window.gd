class_name LvvRaidWindow
extends Panel


@onready var title_label : Label = $MarginContainer/MainVBox/TitleLabel
@onready var message_label : Label = $MarginContainer/MainVBox/MessageLabel
@onready var close_button : Button = $MarginContainer/MainVBox/CloseButton


func _ready() -> void:
	title_label.text = StringContainer.LVV_RAID_TITLE
	close_button.text = StringContainer.LVV_RAID_CLOSE_TEXT

	close_button.pressed.connect(_on_close_button_pressed)
	BrewerySignals.lvv_raid_triggered.connect(_on_lvv_raid_triggered)


func _on_lvv_raid_triggered(confiscated_bottles : int, fine_amount : float, reputation_lost : int) -> void:
	message_label.text = StringContainer.LVV_RAID_MESSAGE % [confiscated_bottles, fine_amount, reputation_lost]
	show()


func _on_close_button_pressed() -> void:
	hide()
