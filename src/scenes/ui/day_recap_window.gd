class_name DayRecapWindow
extends Panel

## The end-of-day summary; shows and hides itself on the signal bus.

const RECAP_TITLE: String = "Päivän yhteenveto"
const CLOSE_BUTTON_TEXT: String = "Jatka"
const RECAP_MESSAGE_FORMAT: String = "Päivä %d alkoi.\n\nRahaa: %s\nMainetta: %+d%s\nLVV-riski nyt: %d%s\nAnnoksia myyty: %d\nUusia oluttyylejä: %s\nPäivätavoitteita saavutettu: %d"
const NO_NEW_STYLES_TEXT: String = "ei uusia"
const NIGHT_RISK_RELIEF_FORMAT: String = "(yöllä -%d)"

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var close_button: Button = %CloseButton

var _day_start_money: float = 0.0
var _day_start_reputation: int = 0
var _bottles_sold_today: int = 0
var _goals_rewarded_today: int = 0
var _styles_discovered_today: Array[String] = []
## ReputationRules.Source -> today's summed change, for the breakdown suffix.
var _reputation_by_source: Dictionary = {}
var _night_risk_relief: int = 0


func _ready() -> void:
	title_label.text = RECAP_TITLE
	close_button.text = CLOSE_BUTTON_TEXT
	# The new day waits while it is read, so an event offered meanwhile cannot run out unseen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	PauseLock.hold_while_visible(self)

	if BrewEngine.current_brewery:
		_day_start_money = BrewEngine.current_brewery.money
		_day_start_reputation = BrewEngine.current_brewery.reputation

	close_button.pressed.connect(_on_close_button_pressed)
	WindowCloseButton.attach(self, _on_close_button_pressed)
	TimeManager.day_changed.connect(_on_day_changed)
	BrewerySignals.bottles_sold.connect(_on_bottles_sold)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	DailyGoalManager.daily_goal_resolved.connect(_on_daily_goal_resolved)
	BrewerySignals.reputation_changed.connect(_on_reputation_changed)
	BrewerySignals.risk_decayed.connect(_on_risk_decayed)


func _on_bottles_sold(amount: int) -> void:
	_bottles_sold_today += amount


func _on_reputation_changed(amount: int, source: ReputationRules.Source) -> void:
	_reputation_by_source[source] = _reputation_by_source.get(source, 0) + amount


func _on_risk_decayed(amount: int) -> void:
	_night_risk_relief += amount


func _on_style_discovered(style: int) -> void:
	_styles_discovered_today.append(BeerStyle.get_style_string_from_style(style))


## Counts successes only; goals resolve all day, so the count can pass the slot count.
func _on_daily_goal_resolved(_goal_name : String, succeeded : bool, _money : int, _reputation : int, _xp : int, _risk : int) -> void:
	if succeeded:
		_goals_rewarded_today += 1


func _on_day_changed(new_day: int) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	var money_delta := snappedf(brewery.money - _day_start_money, 0.01)
	var reputation_delta := brewery.reputation - _day_start_reputation
	var risk_relief_text := " " + tr(NIGHT_RISK_RELIEF_FORMAT) % _night_risk_relief if _night_risk_relief > 0 else ""
	var discovered_text := ", ".join(_styles_discovered_today) if not _styles_discovered_today.is_empty() else tr(NO_NEW_STYLES_TEXT)

	message_label.text = tr(RECAP_MESSAGE_FORMAT) % [new_day, NumberText.signed_money(money_delta), reputation_delta, ReputationBreakdownText.format(_reputation_by_source), brewery.risk, risk_relief_text, _bottles_sold_today, discovered_text, _goals_rewarded_today]
	show()

	_day_start_money = brewery.money
	_day_start_reputation = brewery.reputation
	_bottles_sold_today = 0
	_goals_rewarded_today = 0
	_styles_discovered_today.clear()
	_reputation_by_source.clear()
	_night_risk_relief = 0


func _on_close_button_pressed() -> void:
	GUISignals.window_closed.emit()
	hide()


## Esc does what the X does, and is used up here so the game menu does not open over it.
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed(InputManager.ACTION_CANCEL):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()
