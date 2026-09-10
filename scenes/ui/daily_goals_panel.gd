class_name DailyGoalsPanel
extends VBoxContainer

## Always-visible, background-free "quest tracker" style goal list, top-right
## under the resources bar. Collapsible via the header arrow, matching
## DevConsole's ▼/▲ pattern. Targets are intentionally fixed for this first
## pass rather than randomized/scaled — tuning difficulty needs playtesting
## data this project doesn't have yet.

const BOTTLES_TARGET : int = 10
const RISK_LIMIT : int = 50

## Bottles is the "active selling" goal (harder — needs a full day of sales),
## risk is the "stay careful" goal (passive — just don't overreach), so it
## pays out less. Read by CustomerManager (instant reward) and TimeManager
## (day-end reward) as well as this panel.
const BOTTLES_GOAL_REWARD_MONEY : int = 20
const BOTTLES_GOAL_REWARD_REPUTATION : int = 5
const RISK_GOAL_REWARD_MONEY : int = 10
const RISK_GOAL_REWARD_REPUTATION : int = 2

const NEAR_MISS_BOTTLES_THRESHOLD : int = 2
const NEAR_MISS_PULSE_SECONDS : float = 0.6

const COLLAPSE_ICON : String = "▼"
const EXPAND_ICON : String = "▲"

const BOTTLES_GOAL_FORMAT : String = "Pulloja: %d/%d"
const RISK_GOAL_FORMAT : String = "Riski: %d/%d"

const TUTORIAL_MALT_FORMAT : String = "Mallasta: %d/%d kg"
const TUTORIAL_YEAST_FORMAT : String = "Hiivaa: %d/1"
const TUTORIAL_BREW_FORMAT : String = "Kotikalja: %d/1"

const GOAL_MET_COLOR : Color = Color(0.6117647, 0.70980394, 0.41568628, 1) # matches ReputationLabel
const GOAL_PENDING_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # existing gold accent
const GOAL_FAILING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches RiskLabel

@onready var toggle_button : Button = $HeaderHBox/ToggleButton
@onready var goals_vbox : VBoxContainer = $GoalsVBox
@onready var bottles_goal_label : Label = $GoalsVBox/BottlesGoalLabel
@onready var risk_goal_label : Label = $GoalsVBox/RiskGoalLabel
@onready var tutorial_malt_label : Label = $GoalsVBox/TutorialMaltLabel
@onready var tutorial_yeast_label : Label = $GoalsVBox/TutorialYeastLabel
@onready var tutorial_brew_label : Label = $GoalsVBox/TutorialBrewLabel

var _is_collapsed : bool = true
var _bottles_pulse_tween : Tween


func _ready() -> void:
	toggle_button.pressed.connect(_on_toggle_pressed)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	TimeManager.day_changed.connect(_on_day_changed)

	# Starts collapsed — the screen is already dense, this is opt-in glance
	# info rather than something that needs to be ambiently visible.
	goals_vbox.visible = false
	toggle_button.text = EXPAND_ICON

	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	goals_vbox.visible = not _is_collapsed
	toggle_button.text = EXPAND_ICON if _is_collapsed else COLLAPSE_ICON


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_update_goals(brewery)


func _on_day_changed(_new_day : int) -> void:
	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


func _update_goals(brewery : Brewery) -> void:
	var show_tutorial : bool = not brewery.tutorial_complete()

	tutorial_malt_label.visible = show_tutorial
	tutorial_yeast_label.visible = show_tutorial
	tutorial_brew_label.visible = show_tutorial
	bottles_goal_label.visible = not show_tutorial
	risk_goal_label.visible = not show_tutorial

	if show_tutorial:
		_update_tutorial_goals(brewery)
	else:
		_update_daily_goals(brewery)


func _update_tutorial_goals(brewery : Brewery) -> void:
	var malt_kg : int = min(brewery.lifetime_malt_kg_bought, Brewery.TUTORIAL_MALT_TARGET_KG)
	var malt_met : bool = brewery.lifetime_malt_kg_bought >= Brewery.TUTORIAL_MALT_TARGET_KG
	tutorial_malt_label.text = TUTORIAL_MALT_FORMAT % [malt_kg, Brewery.TUTORIAL_MALT_TARGET_KG]
	tutorial_malt_label.add_theme_color_override("font_color", GOAL_MET_COLOR if malt_met else GOAL_PENDING_COLOR)

	tutorial_yeast_label.text = TUTORIAL_YEAST_FORMAT % (1 if brewery.tutorial_bought_yeast else 0)
	tutorial_yeast_label.add_theme_color_override("font_color", GOAL_MET_COLOR if brewery.tutorial_bought_yeast else GOAL_PENDING_COLOR)

	tutorial_brew_label.text = TUTORIAL_BREW_FORMAT % (1 if brewery.tutorial_brewed_kotikalja else 0)
	tutorial_brew_label.add_theme_color_override("font_color", GOAL_MET_COLOR if brewery.tutorial_brewed_kotikalja else GOAL_PENDING_COLOR)


func _update_daily_goals(brewery : Brewery) -> void:
	var bottles_remaining : int = BOTTLES_TARGET - brewery.bottles_sold_today
	var bottles_met : bool = bottles_remaining <= 0
	bottles_goal_label.text = BOTTLES_GOAL_FORMAT % [brewery.bottles_sold_today, BOTTLES_TARGET]
	bottles_goal_label.add_theme_color_override("font_color", GOAL_MET_COLOR if bottles_met else GOAL_PENDING_COLOR)

	var is_near_miss : bool = not bottles_met and bottles_remaining <= NEAR_MISS_BOTTLES_THRESHOLD
	if is_near_miss and _bottles_pulse_tween == null:
		_start_bottles_pulse()
	elif not is_near_miss and _bottles_pulse_tween != null:
		_stop_bottles_pulse()

	var risk_met : bool = brewery.risk < RISK_LIMIT
	risk_goal_label.text = RISK_GOAL_FORMAT % [RISK_LIMIT, brewery.risk]
	risk_goal_label.add_theme_color_override("font_color", GOAL_MET_COLOR if risk_met else GOAL_FAILING_COLOR)


## Subtle "just one more sale" nudge — pulses the bottles goal label while
## within NEAR_MISS_BOTTLES_THRESHOLD of the target and not yet met.
func _start_bottles_pulse() -> void:
	bottles_goal_label.pivot_offset = bottles_goal_label.size / 2.0
	_bottles_pulse_tween = create_tween().set_loops()
	_bottles_pulse_tween.tween_property(bottles_goal_label, "scale", Vector2(1.15, 1.15), NEAR_MISS_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bottles_pulse_tween.tween_property(bottles_goal_label, "scale", Vector2.ONE, NEAR_MISS_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_bottles_pulse() -> void:
	if _bottles_pulse_tween:
		_bottles_pulse_tween.kill()
		_bottles_pulse_tween = null
	bottles_goal_label.scale = Vector2.ONE
