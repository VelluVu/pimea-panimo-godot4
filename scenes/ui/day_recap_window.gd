class_name DayRecapWindow
extends Panel

## Self-contained end-of-day summary modal, matching the AviRaidWindow
## pattern: listens to the global signal bus directly and shows/hides
## itself, rather than being driven by gui.gd.

const RECAP_TITLE: String = "Päivän yhteenveto"
const CLOSE_BUTTON_TEXT: String = "Jatka"
const RECAP_MESSAGE_FORMAT: String = "Päivä %d alkoi.\n\nRahaa: %+d €\nMainetta: %+d\nAVI-riski nyt: %d\nPulloja myyty: %d\nUusia oluttyylejä: %s"
const NO_NEW_STYLES_TEXT: String = "ei uusia"

@onready var title_label: Label = $MarginContainer/MainVBox/TitleLabel
@onready var message_label: Label = $MarginContainer/MainVBox/MessageLabel
@onready var close_button: Button = $MarginContainer/MainVBox/CloseButton

var _day_start_money: int = 0
var _day_start_reputation: int = 0
var _bottles_sold_today: int = 0
var _styles_discovered_today: Array[String] = []


func _ready() -> void:
	title_label.text = RECAP_TITLE
	close_button.text = CLOSE_BUTTON_TEXT

	if BrewEngine.current_brewery:
		_day_start_money = BrewEngine.current_brewery.money
		_day_start_reputation = BrewEngine.current_brewery.reputation

	close_button.pressed.connect(_on_close_button_pressed)
	TimeManager.day_changed.connect(_on_day_changed)
	BrewerySignals.bottles_sold.connect(_on_bottles_sold)
	BrewerySignals.style_discovered.connect(_on_style_discovered)


func _on_bottles_sold(amount: int) -> void:
	_bottles_sold_today += amount


func _on_style_discovered(style: int) -> void:
	_styles_discovered_today.append(BeerStyle.get_style_string_from_style(style))


func _on_day_changed(new_day: int) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	var money_delta := brewery.money - _day_start_money
	var reputation_delta := brewery.reputation - _day_start_reputation
	var discovered_text := ", ".join(_styles_discovered_today) if not _styles_discovered_today.is_empty() else NO_NEW_STYLES_TEXT

	message_label.text = RECAP_MESSAGE_FORMAT % [new_day, money_delta, reputation_delta, brewery.risk, _bottles_sold_today, discovered_text]
	show()

	_day_start_money = brewery.money
	_day_start_reputation = brewery.reputation
	_bottles_sold_today = 0
	_styles_discovered_today.clear()


func _on_close_button_pressed() -> void:
	hide()
