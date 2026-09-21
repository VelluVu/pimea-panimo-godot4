class_name DayRecapWindow
extends Panel

## Self-contained end-of-day summary modal, matching the LvvRaidWindow
## pattern: listens to the global signal bus directly and shows/hides
## itself, rather than being driven by gui.gd.

const RECAP_TITLE: String = "Päivän yhteenveto"
const CLOSE_BUTTON_TEXT: String = "Jatka"
const RECAP_MESSAGE_FORMAT: String = "Päivä %d alkoi.\n\nRahaa: %+.1f €\nMainetta: %+d\nLVV-riski nyt: %d\nAnnoksia myyty: %d\nUusia oluttyylejä: %s\nPäivätavoitteita saavutettu: %d"
const NO_NEW_STYLES_TEXT: String = "ei uusia"

@onready var title_label: Label = $MarginContainer/MainVBox/TitleLabel
@onready var message_label: Label = $MarginContainer/MainVBox/MessageLabel
@onready var close_button: Button = $MarginContainer/MainVBox/CloseButton

var _day_start_money: float = 0.0
var _day_start_reputation: int = 0
var _bottles_sold_today: int = 0
var _goals_rewarded_today: int = 0
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
	DailyGoalManager.daily_goal_resolved.connect(_on_daily_goal_resolved)


func _on_bottles_sold(amount: int) -> void:
	_bottles_sold_today += amount


func _on_style_discovered(style: int) -> void:
	_styles_discovered_today.append(BeerStyle.get_style_string_from_style(style))


## Only successes count toward the recap line — a failed goal still fires
## daily_goal_resolved (see DailyGoalManager), it just shouldn't read as an
## achievement. Goals resolve continuously through the day (reactively) as
## well as right at this same day boundary (DailyGoalManager's own
## day_changed handler resolving whatever's still pending), so a busy day
## can rack up more than the ACTIVE_GOAL_COUNT=3 concurrent slots by the
## time this recap shows — no cap here, unlike the old fixed 2-goal count.
func _on_daily_goal_resolved(_goal_name : String, succeeded : bool, _money : int, _reputation : int, _xp : int, _risk : int) -> void:
	if succeeded:
		_goals_rewarded_today += 1


func _on_day_changed(new_day: int) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	var money_delta := snappedf(brewery.money - _day_start_money, 0.1)
	var reputation_delta := brewery.reputation - _day_start_reputation
	var discovered_text := ", ".join(_styles_discovered_today) if not _styles_discovered_today.is_empty() else NO_NEW_STYLES_TEXT

	message_label.text = RECAP_MESSAGE_FORMAT % [new_day, money_delta, reputation_delta, brewery.risk, _bottles_sold_today, discovered_text, _goals_rewarded_today]
	show()

	_day_start_money = brewery.money
	_day_start_reputation = brewery.reputation
	_bottles_sold_today = 0
	_goals_rewarded_today = 0
	_styles_discovered_today.clear()


func _on_close_button_pressed() -> void:
	hide()
