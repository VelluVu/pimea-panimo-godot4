class_name DailyGoalsPanel
extends VBoxContainer

## Always-visible, background-free "quest tracker" style goal list, top-right
## under the resources bar. Collapsible via the header arrow, matching
## DevConsole's ▼/▲ pattern.
##
## The three DailyGoalLabel slots below are a pure display of
## DailyGoalManager.active_goals/get_progress() (index-aligned) — all the
## actual goal logic (picking, progress tracking, success/failure
## resolution) lives in that autoload, not here. See its own class
## docstring for the full picture.

const ATTENTION_PULSE_SECONDS : float = 0.5
const ATTENTION_PULSE_COUNT : int = 3
const ATTENTION_PULSE_SCALE : Vector2 = Vector2(1.12, 1.12)

const COLLAPSE_ICON : String = "▼"
const EXPAND_ICON : String = "▲"

const DAILY_GOAL_LINE_FORMAT : String = "%s: %s"
## Persistent across the whole run, unlike everything else in this panel —
## deliberately shown regardless of tutorial state (see _update_goals())
## so the win condition is visible from the very first day, not just once
## daily goals kick in.
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

## "Just one more sale" nudge — pulses a goal's label once its progress
## crosses this fraction of target_amount without having met it yet. Only
## applies to "achieve" goals (see DailyGoalData); an "avoid" goal
## (UNHAPPY_CUSTOMERS_MAX) reads danger through color alone (see
## _update_daily_goals()) since pulsing "getting closer to failing" would
## send the wrong emotional signal.
const NEAR_MISS_PROGRESS_RATIO : float = 0.8
const NEAR_MISS_PULSE_SECONDS : float = 0.6

@onready var toggle_button : Button = $HeaderHBox/ToggleButton
@onready var goals_vbox : VBoxContainer = $GoalsVBox
@onready var main_goal_header_label : Label = $GoalsVBox/MainGoalHeaderLabel
@onready var day_goal_label : Label = $GoalsVBox/DayGoalLabel
@onready var reputation_goal_label : Label = $GoalsVBox/ReputationGoalLabel
@onready var daily_goals_header_label : Label = $GoalsVBox/DailyGoalsHeaderLabel
## Index-aligned with DailyGoalManager.active_goals — see the class
## docstring.
@onready var daily_goal_labels : Array[Label] = [
	$GoalsVBox/DailyGoalLabel0,
	$GoalsVBox/DailyGoalLabel1,
	$GoalsVBox/DailyGoalLabel2,
]
@onready var tutorial_malt_label : Label = $GoalsVBox/TutorialMaltLabel
@onready var tutorial_yeast_label : Label = $GoalsVBox/TutorialYeastLabel
@onready var tutorial_brew_label : Label = $GoalsVBox/TutorialBrewLabel

## Per-section collapse toggles (separate from the panel-wide one above) —
## built at runtime rather than in the scene, same approach BeerPatchPanel
## already uses for its destination-bar row, so a player can hide e.g. the
## main goal lines and keep only the daily goals visible (or vice versa)
## without the whole panel needing its own extra vertical space for both
## at once. Reuses COLLAPSE_ICON/EXPAND_ICON below.
var _main_goal_section_toggle : Button = null
var _daily_goals_section_toggle : Button = null
var _main_goal_section_collapsed : bool = false
var _daily_goals_section_collapsed : bool = false

var _is_collapsed : bool = true
var _pulse_tweens : Array[Tween] = [null, null, null]


func _ready() -> void:
	main_goal_header_label.text = MAIN_GOAL_HEADER_TEXT
	daily_goals_header_label.text = DAILY_GOALS_HEADER_TEXT

	_main_goal_section_toggle = _wrap_header_with_section_toggle(main_goal_header_label, _on_main_goal_section_toggle_pressed)
	_daily_goals_section_toggle = _wrap_header_with_section_toggle(daily_goals_header_label, _on_daily_goals_section_toggle_pressed)

	toggle_button.pressed.connect(_on_toggle_pressed)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	DailyGoalManager.goal_progress_changed.connect(_on_goal_progress_changed)

	# Starts collapsed — the screen is already dense, this is opt-in glance
	# info rather than something that needs to be ambiently visible.
	goals_vbox.visible = false
	toggle_button.text = EXPAND_ICON

	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


## Reparents header_label into a new HBoxContainer alongside a small arrow
## Button, then puts that row back at header_label's original spot in
## goals_vbox — avoids hand-editing main.tscn's node tree for a two-button
## addition. Returns the new button so callers can flip its icon later.
func _wrap_header_with_section_toggle(header_label : Label, on_pressed : Callable) -> Button:
	var original_index := header_label.get_index()

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	goals_vbox.remove_child(header_label)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(header_label)

	var section_toggle := Button.new()
	section_toggle.custom_minimum_size = Vector2(16, 12)
	section_toggle.add_theme_font_size_override("font_size", 10)
	section_toggle.flat = true
	section_toggle.text = COLLAPSE_ICON
	section_toggle.pressed.connect(on_pressed)
	row.add_child(section_toggle)

	goals_vbox.add_child(row)
	goals_vbox.move_child(row, original_index)

	return section_toggle


func _on_toggle_pressed() -> void:
	_is_collapsed = not _is_collapsed
	goals_vbox.visible = not _is_collapsed
	toggle_button.text = EXPAND_ICON if _is_collapsed else COLLAPSE_ICON


func _on_main_goal_section_toggle_pressed() -> void:
	_main_goal_section_collapsed = not _main_goal_section_collapsed
	_main_goal_section_toggle.text = EXPAND_ICON if _main_goal_section_collapsed else COLLAPSE_ICON
	if BrewEngine.current_brewery != null:
		_update_run_goal(BrewEngine.current_brewery)


func _on_daily_goals_section_toggle_pressed() -> void:
	_daily_goals_section_collapsed = not _daily_goals_section_collapsed
	_daily_goals_section_toggle.text = EXPAND_ICON if _daily_goals_section_collapsed else COLLAPSE_ICON
	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


## Called once from GUI._show_first_brew_hint()/_on_first_brew_hint_state_changed()
## right as the first-brew hint banner finishes — this panel starts
## collapsed and opt-in (see _ready()'s comment above), which is fine once
## a player already knows it's there, but a brand-new player has no reason
## to have found the toggle arrow yet, and this is exactly where their
## tutorial checklist lives. Expands it if needed and pulses it a few
## times so the eye actually lands here instead of just being told
## verbally to go look for it.
func draw_attention() -> void:
	if _is_collapsed:
		_on_toggle_pressed()

	await get_tree().process_frame
	# Pivot on the right edge (size.x), not the center — this panel is
	# right-anchored flush against the edge of the game window (see
	# anchor_left/anchor_right = 1 in the scene), so a centered pivot would
	# push its right half past the window boundary every pulse. Pivoting on
	# the right edge instead keeps that edge fixed and grows only leftward,
	# into the middle of the screen.
	pivot_offset = Vector2(size.x, size.y / 2.0)

	var attention_tween := create_tween().set_loops(ATTENTION_PULSE_COUNT)
	attention_tween.tween_property(self, "scale", ATTENTION_PULSE_SCALE, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	attention_tween.tween_property(self, "scale", Vector2.ONE, ATTENTION_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_update_goals(brewery)


func _on_day_changed(_new_day : int) -> void:
	if BrewEngine.current_brewery != null:
		_update_goals(BrewEngine.current_brewery)


## DailyGoalManager fires this for every progress tick and every slot
## reassignment — brewery is always live by the time any of that can happen
## (goals don't exist pre-tutorial), so no null guard needed here the way
## _on_day_changed() above needs one.
func _on_goal_progress_changed() -> void:
	_update_daily_goals()


func _update_goals(brewery : Brewery) -> void:
	var show_tutorial : bool = not brewery.tutorial_complete()

	_update_run_goal(brewery)

	var section_visible : bool = not _daily_goals_section_collapsed
	tutorial_malt_label.visible = show_tutorial and section_visible
	tutorial_yeast_label.visible = show_tutorial and section_visible
	tutorial_brew_label.visible = show_tutorial and section_visible
	for label : Label in daily_goal_labels:
		label.visible = not show_tutorial and section_visible

	# Always on, unlike the section it introduces — the tutorial checklist
	# (malt/yeast/brew) is itself this run's "today's goals" before the
	# real daily goals exist yet, so the header belongs above it too, not
	# just once tutorial_complete() flips true.

	if show_tutorial:
		_update_tutorial_goals(brewery)
	else:
		_update_daily_goals()


## Shown from day one regardless of tutorial state — this is the run's
## actual win condition (DayRules.SURVIVAL_DAY_TARGET / Brewery.
## SURVIVAL_MIN_REPUTATION, see DayRules.survival_reached()),
## which previously had nothing on screen telling the player it existed
## until they cleared or missed it. Two independently-colored lines, same
## "each stat judges itself" shape _update_daily_goals() already uses for
## bottles/risk, rather than one line sharing a single combined color.
func _update_run_goal(brewery : Brewery) -> void:
	var target_day : int = DayRules.SURVIVAL_DAY_TARGET
	var min_reputation : int = Brewery.SURVIVAL_MIN_REPUTATION
	var money_in_danger : bool = brewery.money <= 0.0

	day_goal_label.visible = not _main_goal_section_collapsed
	reputation_goal_label.visible = not _main_goal_section_collapsed

	day_goal_label.text = DAY_GOAL_FORMAT % [brewery.current_day, target_day]
	if brewery.current_day >= target_day:
		day_goal_label.add_theme_color_override("font_color", GOAL_MET_COLOR)
	elif money_in_danger:
		day_goal_label.add_theme_color_override("font_color", GOAL_FAILING_COLOR)
	else:
		day_goal_label.add_theme_color_override("font_color", GOAL_PENDING_COLOR)

	reputation_goal_label.text = REPUTATION_GOAL_FORMAT % [brewery.reputation, min_reputation]
	if money_in_danger:
		reputation_goal_label.add_theme_color_override("font_color", GOAL_FAILING_COLOR)
	elif brewery.reputation >= min_reputation:
		reputation_goal_label.add_theme_color_override("font_color", GOAL_MET_COLOR)
	else:
		reputation_goal_label.add_theme_color_override("font_color", GOAL_PENDING_COLOR)


func _update_tutorial_goals(brewery : Brewery) -> void:
	var malt_kg : int = min(brewery.lifetime_malt_kg_bought, Brewery.TUTORIAL_MALT_TARGET_KG)
	var malt_met : bool = brewery.lifetime_malt_kg_bought >= Brewery.TUTORIAL_MALT_TARGET_KG
	tutorial_malt_label.text = TUTORIAL_MALT_FORMAT % [malt_kg, Brewery.TUTORIAL_MALT_TARGET_KG]
	tutorial_malt_label.add_theme_color_override("font_color", GOAL_MET_COLOR if malt_met else GOAL_PENDING_COLOR)

	tutorial_yeast_label.text = TUTORIAL_YEAST_FORMAT % (1 if brewery.tutorial_bought_yeast else 0)
	tutorial_yeast_label.add_theme_color_override("font_color", GOAL_MET_COLOR if brewery.tutorial_bought_yeast else GOAL_PENDING_COLOR)

	tutorial_brew_label.text = TUTORIAL_BREW_FORMAT % (1 if brewery.tutorial_brewed_kotikalja else 0)
	tutorial_brew_label.add_theme_color_override("font_color", GOAL_MET_COLOR if brewery.tutorial_brewed_kotikalja else GOAL_PENDING_COLOR)


func _update_daily_goals() -> void:
	for i in range(daily_goal_labels.size()):
		var label : Label = daily_goal_labels[i]
		var goal : DailyGoalData = DailyGoalManager.active_goals[i]

		if goal == null:
			label.visible = false
			_stop_pulse(i)
			continue

		label.visible = not _daily_goals_section_collapsed
		var progress : int = DailyGoalManager.get_progress(i)
		var target : int = DailyGoalManager.get_effective_target(i)
		label.text = DAILY_GOAL_LINE_FORMAT % [goal.goal_name, goal.get_progress_text(progress, target)]

		var ratio : float = float(progress) / float(maxi(1, target))

		if goal.goal_type == DailyGoalData.GoalType.UNHAPPY_CUSTOMERS_MAX:
			# Avoid-type: color reads as a danger meter (closer to the limit
			# = more urgent), not "progress toward success" — no pulse, see
			# NEAR_MISS_PROGRESS_RATIO's own docstring for why.
			label.add_theme_color_override("font_color", GOAL_FAILING_COLOR if ratio >= 1.0 else GOAL_PENDING_COLOR)
			_stop_pulse(i)
			continue

		var met : bool = ratio >= 1.0
		label.add_theme_color_override("font_color", GOAL_MET_COLOR if met else GOAL_PENDING_COLOR)

		var is_near_miss : bool = not met and ratio >= NEAR_MISS_PROGRESS_RATIO
		if is_near_miss and _pulse_tweens[i] == null:
			_start_pulse(i)
		elif not is_near_miss and _pulse_tweens[i] != null:
			_stop_pulse(i)


func _start_pulse(i : int) -> void:
	var label : Label = daily_goal_labels[i]
	label.pivot_offset = label.size / 2.0
	_pulse_tweens[i] = create_tween().set_loops()
	_pulse_tweens[i].tween_property(label, "scale", Vector2(1.15, 1.15), NEAR_MISS_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tweens[i].tween_property(label, "scale", Vector2.ONE, NEAR_MISS_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse(i : int) -> void:
	if _pulse_tweens[i]:
		_pulse_tweens[i].kill()
		_pulse_tweens[i] = null
	daily_goal_labels[i].scale = Vector2.ONE
