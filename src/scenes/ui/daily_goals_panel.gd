class_name DailyGoalsPanel
extends VBoxContainer

## The always-visible goal list under the resources bar. Display only: the goals live in
## DailyGoalManager, the status rules in GoalStatus; slots index-align with its goals.

const ATTENTION_PULSE_SECONDS : float = 0.5
const ATTENTION_PULSE_COUNT : int = 3
## Brightness, not scale: the pixel font blurs off whole sizes.
const ATTENTION_PULSE_COLOR : Color = Color(1.6, 1.6, 1.6)

const DAILY_GOAL_LINE_FORMAT : String = "%s: %s"
## The season goals are gone, so the day's goals are simply "Tavoitteet"; the count of
## goals still to come today rides on that one header.
const TITLE_TEXT : String = "Tavoitteet"
const TITLE_LEFT_FORMAT : String = "Tavoitteet (+%d tänään)"
const NO_GOALS_LEFT_TEXT : String = "Uusia tavoitteita huomenna."

const TUTORIAL_MALT_FORMAT : String = "Mallasta: %d/%d kg"
const TUTORIAL_YEAST_FORMAT : String = "Hiivaa: %d/1"
const TUTORIAL_BREW_FORMAT : String = "Kotikalja: %d/1"

const GOAL_MET_COLOR : Color = Color(0.6117647, 0.70980394, 0.41568628, 1) # matches ReputationLabel
const GOAL_PENDING_COLOR : Color = Color(0.9490196, 0.7882353, 0.41960785, 1) # existing gold accent
const GOAL_FAILING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches RiskLabel
const GOAL_WARNING_COLOR : Color = Color(0.96862745, 0.4627451, 0.13333334, 1) # Endesga orange
const NEXT_STEP_COLOR : Color = Color(0.9490196, 0.9254902, 0.84705883, 1) # icon-font cream
const LABEL_OUTLINE_COLOR : Color = Color(0.08235294, 0.0627451, 0.039215688, 1)
const LABEL_OUTLINE_SIZE : int = 3
## The tutorial lines' width, so a long step wraps inside the panel.
const NEXT_STEP_WIDTH : float = 160.0

@onready var title_label : Label = $HeaderHBox/TitleLabel
@onready var toggle_button : Button = $HeaderHBox/ToggleButton
@onready var goals_vbox : VBoxContainer = $GoalsVBox
@onready var daily_goal_labels : Array[Label] = [
	$GoalsVBox/DailyGoalLabel0,
	$GoalsVBox/DailyGoalLabel1,
	$GoalsVBox/DailyGoalLabel2,
]
@onready var tutorial_malt_label : Label = $GoalsVBox/TutorialMaltLabel
@onready var tutorial_yeast_label : Label = $GoalsVBox/TutorialYeastLabel
@onready var tutorial_brew_label : Label = $GoalsVBox/TutorialBrewLabel

var _near_miss_pulses : Array[LabelPulse] = []
var _is_collapsed : bool = true
var _next_step_label : Label


func _ready() -> void:
	for label : Label in daily_goal_labels:
		_near_miss_pulses.append(LabelPulse.new(label))

	_add_next_step_label()
	toggle_button.pressed.connect(_on_toggle_pressed)
	BrewerySignals.brewery_state_changed.connect(_update_goals)
	TimeManager.day_changed.connect(_on_day_changed)
	DailyGoalManager.goal_progress_changed.connect(_update_daily_goals)

	# Starts collapsed: the screen is already dense, this is opt-in glance info.
	goals_vbox.visible = false
	toggle_button.text = CollapsibleSection.icon_for(_is_collapsed)
	_refresh()


## When the first-brew hint ends: expands and pulses the panel so a new player sees it.
func draw_attention() -> void:
	if _is_collapsed:
		_on_toggle_pressed()

	var attention_tween := create_tween().set_loops(ATTENTION_PULSE_COUNT)
	attention_tween.tween_property(self, "modulate", ATTENTION_PULSE_COLOR, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	attention_tween.tween_property(self, "modulate", Color.WHITE, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The step is shown even while the goals are collapsed: it is the one line a lost player
## needs. Empty hides it.
func show_next_step(text : String) -> void:
	_next_step_label.text = text
	_next_step_label.visible = not text.is_empty()


## Under the "Tavoitteet" header, outside the collapsible goal list.
func _add_next_step_label() -> void:
	_next_step_label = Label.new()
	_next_step_label.name = "NextStepLabel"
	_next_step_label.custom_minimum_size.x = NEXT_STEP_WIDTH
	_next_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_step_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_step_label.add_theme_font_size_override(&"font_size", 16)
	_next_step_label.add_theme_color_override(&"font_color", NEXT_STEP_COLOR)
	_next_step_label.add_theme_color_override(&"font_outline_color", LABEL_OUTLINE_COLOR)
	_next_step_label.add_theme_constant_override(&"outline_size", LABEL_OUTLINE_SIZE)
	_next_step_label.visible = false
	add_child(_next_step_label)
	move_child(_next_step_label, goals_vbox.get_index())


func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	goals_vbox.visible = not _is_collapsed
	toggle_button.text = CollapsibleSection.icon_for(_is_collapsed)


func _on_day_changed(_new_day : int) -> void:
	_refresh()


func _refresh() -> void:
	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


func _update_goals(brewery : Brewery) -> void:
	var show_tutorial : bool = not brewery.tutorial_complete()
	tutorial_malt_label.visible = show_tutorial
	tutorial_yeast_label.visible = show_tutorial
	tutorial_brew_label.visible = show_tutorial
	for label : Label in daily_goal_labels:
		label.visible = not show_tutorial
	if show_tutorial:
		title_label.text = TITLE_TEXT

	if show_tutorial:
		_update_tutorial_goals(brewery)
	else:
		_update_daily_goals()


func _update_tutorial_goals(brewery : Brewery) -> void:
	var malt_target : int = Brewery.TUTORIAL_MALT_TARGET_KG
	var malt_kg : int = mini(brewery.lifetime_malt_kg_bought, malt_target)
	_set_line(tutorial_malt_label, tr(TUTORIAL_MALT_FORMAT) % [malt_kg, malt_target], GoalStatus.from_met(malt_kg >= malt_target))
	_set_line(tutorial_yeast_label, tr(TUTORIAL_YEAST_FORMAT) % int(brewery.tutorial_bought_yeast), GoalStatus.from_met(brewery.tutorial_bought_yeast))
	_set_line(tutorial_brew_label, tr(TUTORIAL_BREW_FORMAT) % int(brewery.tutorial_brewed_kotikalja), GoalStatus.from_met(brewery.tutorial_brewed_kotikalja))


func _update_daily_goals() -> void:
	var rolls_left : int = DailyGoalManager.get_rolls_left()
	title_label.text = TITLE_TEXT if rolls_left < 0 else tr(TITLE_LEFT_FORMAT) % rolls_left
	for i : int in daily_goal_labels.size():
		var label : Label = daily_goal_labels[i]
		var goal : DailyGoalData = DailyGoalManager.active_goals[i]
		if goal == null:
			label.visible = false
			_near_miss_pulses[i].set_active(false)
			continue

		var progress : int = DailyGoalManager.get_progress(i)
		var target : int = DailyGoalManager.get_effective_target(i)
		label.visible = true
		_set_line(label, DAILY_GOAL_LINE_FORMAT % [tr(goal.goal_name), goal.get_progress_text(progress, target)], GoalStatus.daily_goal(goal.goal_type, progress, target))
		_near_miss_pulses[i].set_active(GoalStatus.is_near_miss(goal.goal_type, progress, target))

	# With today's goals used up every slot is empty: say when new ones come.
	if rolls_left == 0 and DailyGoalManager.active_goals.all(func(goal : GoalData) -> bool: return goal == null):
		var first : Label = daily_goal_labels[0]
		first.visible = true
		_set_line(first, NO_GOALS_LEFT_TEXT, GoalStatus.State.PENDING)


func _set_line(label : Label, text : String, state : GoalStatus.State) -> void:
	label.text = text
	label.add_theme_color_override("font_color", _color_for(state))


func _color_for(state : GoalStatus.State) -> Color:
	match state:
		GoalStatus.State.MET:
			return GOAL_MET_COLOR
		GoalStatus.State.FAILING:
			return GOAL_FAILING_COLOR
		GoalStatus.State.WARNING:
			return GOAL_WARNING_COLOR
		_:
			return GOAL_PENDING_COLOR
