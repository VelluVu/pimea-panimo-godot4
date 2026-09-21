class_name DailyGoalsPanel
extends VBoxContainer

## Always-visible, background-free goal list, top-right under the resources bar.
## A pure display: picking, progress and resolution live in DailyGoalManager, and
## the status rules in GoalStatus. The daily label slots are index-aligned with
## DailyGoalManager.active_goals.

const ATTENTION_PULSE_SECONDS : float = 0.5
const ATTENTION_PULSE_COUNT : int = 3
const ATTENTION_PULSE_SCALE : Vector2 = Vector2(1.12, 1.12)

const DAILY_GOAL_LINE_FORMAT : String = "%s: %s"
## Shown from day one, regardless of tutorial state, so the win condition is visible early.
const DAY_GOAL_FORMAT : String = "Päivät: %d/%d"
const REPUTATION_GOAL_FORMAT : String = "Maine: %d/%d"

const MAIN_GOAL_HEADER_TEXT : String = "Päätavoite:"
const DAILY_GOALS_HEADER_TEXT : String = "Päivätavoitteet:"

const TUTORIAL_MALT_FORMAT : String = "Mallasta: %d/%d kg"
const TUTORIAL_YEAST_FORMAT : String = "Hiivaa: %d/1"
const TUTORIAL_BREW_FORMAT : String = "Kotikalja: %d/1"

const GOAL_MET_COLOR : Color = Color(0.6117647, 0.70980394, 0.41568628, 1) # matches ReputationLabel
const GOAL_PENDING_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # existing gold accent
const GOAL_FAILING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches RiskLabel

@onready var toggle_button : Button = $HeaderHBox/ToggleButton
@onready var goals_vbox : VBoxContainer = $GoalsVBox
@onready var main_goal_header_label : Label = $GoalsVBox/MainGoalHeaderLabel
@onready var day_goal_label : Label = $GoalsVBox/DayGoalLabel
@onready var reputation_goal_label : Label = $GoalsVBox/ReputationGoalLabel
@onready var daily_goals_header_label : Label = $GoalsVBox/DailyGoalsHeaderLabel
@onready var daily_goal_labels : Array[Label] = [
	$GoalsVBox/DailyGoalLabel0,
	$GoalsVBox/DailyGoalLabel1,
	$GoalsVBox/DailyGoalLabel2,
]
@onready var tutorial_malt_label : Label = $GoalsVBox/TutorialMaltLabel
@onready var tutorial_yeast_label : Label = $GoalsVBox/TutorialYeastLabel
@onready var tutorial_brew_label : Label = $GoalsVBox/TutorialBrewLabel

## Per-section toggles, separate from the panel-wide one, so a player can hide the
## main goal lines and keep only the daily goals (or the other way round).
var _main_goal_section : CollapsibleSection
var _daily_goals_section : CollapsibleSection
var _near_miss_pulses : Array[LabelPulse] = []
var _is_collapsed : bool = true


func _ready() -> void:
	main_goal_header_label.text = MAIN_GOAL_HEADER_TEXT
	daily_goals_header_label.text = DAILY_GOALS_HEADER_TEXT

	_main_goal_section = CollapsibleSection.new(goals_vbox, main_goal_header_label)
	_daily_goals_section = CollapsibleSection.new(goals_vbox, daily_goals_header_label)
	_main_goal_section.toggled.connect(_on_section_toggled)
	_daily_goals_section.toggled.connect(_on_section_toggled)
	for label : Label in daily_goal_labels:
		_near_miss_pulses.append(LabelPulse.new(label))

	toggle_button.pressed.connect(_on_toggle_pressed)
	BrewerySignals.brewery_state_changed.connect(_update_goals)
	TimeManager.day_changed.connect(_on_day_changed)
	DailyGoalManager.goal_progress_changed.connect(_update_daily_goals)

	# Starts collapsed: the screen is already dense, this is opt-in glance info.
	goals_vbox.visible = false
	toggle_button.text = CollapsibleSection.icon_for(_is_collapsed)
	_refresh()


## Called from GuiAnnouncer when the first-brew hint banner ends: expands the panel
## if needed and pulses it, so a new player notices their tutorial checklist.
func draw_attention() -> void:
	if _is_collapsed:
		_on_toggle_pressed()

	await get_tree().process_frame
	# Pivot on the right edge: the panel is anchored flush to the window's right side,
	# so a centered pivot would push its right half off-screen on every pulse.
	pivot_offset = Vector2(size.x, size.y / 2.0)

	var attention_tween := create_tween().set_loops(ATTENTION_PULSE_COUNT)
	attention_tween.tween_property(self, "scale", ATTENTION_PULSE_SCALE, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	attention_tween.tween_property(self, "scale", Vector2.ONE, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	goals_vbox.visible = not _is_collapsed
	toggle_button.text = CollapsibleSection.icon_for(_is_collapsed)


func _on_section_toggled(_collapsed : bool) -> void:
	_refresh()


func _on_day_changed(_new_day : int) -> void:
	_refresh()


func _refresh() -> void:
	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


func _update_goals(brewery : Brewery) -> void:
	var show_tutorial : bool = not brewery.tutorial_complete()
	var daily_section_visible : bool = not _daily_goals_section.collapsed

	_update_run_goal(brewery)

	tutorial_malt_label.visible = show_tutorial and daily_section_visible
	tutorial_yeast_label.visible = show_tutorial and daily_section_visible
	tutorial_brew_label.visible = show_tutorial and daily_section_visible
	for label : Label in daily_goal_labels:
		label.visible = not show_tutorial and daily_section_visible

	if show_tutorial:
		_update_tutorial_goals(brewery)
	else:
		_update_daily_goals()


## The run's win condition (DayRules.SURVIVAL_DAY_TARGET, Brewery.SURVIVAL_MIN_REPUTATION).
func _update_run_goal(brewery : Brewery) -> void:
	var money_in_danger : bool = brewery.money <= 0.0
	var target_day : int = DayRules.SURVIVAL_DAY_TARGET
	var min_reputation : int = Brewery.SURVIVAL_MIN_REPUTATION

	day_goal_label.visible = not _main_goal_section.collapsed
	reputation_goal_label.visible = not _main_goal_section.collapsed
	_set_line(day_goal_label, DAY_GOAL_FORMAT % [brewery.current_day, target_day], GoalStatus.run_day(brewery.current_day, target_day, money_in_danger))
	_set_line(reputation_goal_label, REPUTATION_GOAL_FORMAT % [brewery.reputation, min_reputation], GoalStatus.run_reputation(brewery.reputation, min_reputation, money_in_danger))


func _update_tutorial_goals(brewery : Brewery) -> void:
	var malt_target : int = Brewery.TUTORIAL_MALT_TARGET_KG
	var malt_kg : int = mini(brewery.lifetime_malt_kg_bought, malt_target)
	_set_line(tutorial_malt_label, TUTORIAL_MALT_FORMAT % [malt_kg, malt_target], GoalStatus.from_met(malt_kg >= malt_target))
	_set_line(tutorial_yeast_label, TUTORIAL_YEAST_FORMAT % int(brewery.tutorial_bought_yeast), GoalStatus.from_met(brewery.tutorial_bought_yeast))
	_set_line(tutorial_brew_label, TUTORIAL_BREW_FORMAT % int(brewery.tutorial_brewed_kotikalja), GoalStatus.from_met(brewery.tutorial_brewed_kotikalja))


func _update_daily_goals() -> void:
	for i : int in daily_goal_labels.size():
		var label : Label = daily_goal_labels[i]
		var goal : DailyGoalData = DailyGoalManager.active_goals[i]
		if goal == null:
			label.visible = false
			_near_miss_pulses[i].set_active(false)
			continue

		var progress : int = DailyGoalManager.get_progress(i)
		var target : int = DailyGoalManager.get_effective_target(i)
		label.visible = not _daily_goals_section.collapsed
		_set_line(label, DAILY_GOAL_LINE_FORMAT % [goal.goal_name, goal.get_progress_text(progress, target)], GoalStatus.daily_goal(goal.goal_type, progress, target))
		_near_miss_pulses[i].set_active(GoalStatus.is_near_miss(goal.goal_type, progress, target))


func _set_line(label : Label, text : String, state : GoalStatus.State) -> void:
	label.text = text
	label.add_theme_color_override("font_color", _color_for(state))


func _color_for(state : GoalStatus.State) -> Color:
	match state:
		GoalStatus.State.MET:
			return GOAL_MET_COLOR
		GoalStatus.State.FAILING:
			return GOAL_FAILING_COLOR
		_:
			return GOAL_PENDING_COLOR
