class_name TopPanelResources
extends HBoxContainer


const DAY_STRING : String = "Päivä: %s"

## How long a "+X €"/"+X%" popup takes to float up and fade out — bumped up
## from the original 1.0s so the player has a bit more time to actually
## read it before it's gone.
const POPUP_EFFECT_DURATION_SECONDS : float = 1.8

## Below Brewery.LVV_RAID_THRESHOLD (100, an instant full-inventory wipe +
## fine with no other UI warning — see playtest_notes_2.txt's "AVI raid
## has no explicit warning" finding) — a distinct "last chance" zone that
## tints the risk label and pulses once on entry, on top of the existing
## audio tension drone (audio_manager.gd).
const RISK_WARNING_THRESHOLD : int = 75
const RISK_WARNING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches DailyGoalsPanel.GOAL_FAILING_COLOR
const RISK_WARNING_PULSE_SECONDS : float = 0.3

const MODIFIER_TAG_FORMAT : String = "🎲 %s"

const LEVEL_FORMAT : String = "Taso: %d"
const LEVEL_PROGRESS_TOOLTIP_FORMAT : String = "%d / %d XP seuraavaan tasoon"

@onready var money_label : Label = $MoneyLabel
@onready var reputation_label : Label = $ReputationLabel
@onready var level_label : Label = $LevelBox/LevelLabel
@onready var level_progress_bar : ProgressBar = $LevelBox/LevelProgressBar
@onready var risk_label : Label = $RiskLabel
@onready var day_label : Label = $DayLabel
@onready var modifier_tag_label : Label = $ModifierTagLabel
var last_money: float = -1.0
var last_reputation : int = -1
var last_risk: int = -1
## Unlike reputation/risk, level only ever goes up (see Brewery.add_xp())
## and there's no popup-worthy "+1" moment here — LevelUpWindow's own
## perk-pick popup already is that moment. Just tracked to skip a
## redundant label-text write when nothing changed.
var _last_level : int = -1
## Set once per run the first time _on_brewery_state_changed sees a
## Brewery — this run's modifier never changes after that, so there's
## nothing to keep updating (unlike money/reputation/risk above).
var _modifier_tag_shown : bool = false
## Tracks whether the warning tint is currently applied, so the one-time
## pulse only fires on the moment risk crosses upward into the warning
## zone — not on every subsequent state change while it stays there.
var _risk_warning_active: bool = false


func _ready() -> void:
	# Both are scene-defined nodes (see this scene's .tscn) — swap their
	# script at runtime instead of editing the .tscn, so their tooltip_text
	# (a run modifier's full description, or the XP-to-next-level readout)
	# wraps via TooltipFactory instead of overflowing on a long description.
	modifier_tag_label.set_script(TooltipLabel)
	level_progress_bar.set_script(TooltipProgressBar)

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	TimeManager.day_changed.connect(_on_day_changed)

	if BrewEngine.current_brewery != null:
		BrewEngine.current_brewery.emit_initial_values()
		_update_day_display(BrewEngine.current_brewery.current_day)


func _on_day_changed(new_day: int) -> void:
	_update_day_display(new_day)


func _update_day_display(day_num: int) -> void:
	if day_label:
		day_label.text = DAY_STRING % str(day_num)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	if not _modifier_tag_shown and brewery.run_modifier != null:
		_modifier_tag_shown = true
		modifier_tag_label.text = MODIFIER_TAG_FORMAT % brewery.run_modifier.modifier_name

		var stat_summary : String = brewery.run_modifier.get_stat_summary()
		modifier_tag_label.tooltip_text = brewery.run_modifier.description if stat_summary.is_empty() else brewery.run_modifier.description + "\n" + stat_summary

	var new_money: float = brewery.money

	if last_money != -1.0:
		# Snapped so accumulated float noise from repeated +=/-= never
		# reads as a spurious "+0.0 €" popup.
		var change := snappedf(new_money - last_money, 0.1)
		if change != 0.0:
			_create_popup_effect(money_label, change, " €", false, 1)

	money_label.text = "%.1f €" % new_money
	last_money = new_money
	
	var new_reputation : int = brewery.reputation
	
	if last_reputation != -1:
		var change = new_reputation - last_reputation
		if change != 0:
			_create_popup_effect(reputation_label, change, "", false)
	
	reputation_label.text = "Maine: " + str(new_reputation)
	last_reputation = new_reputation

	if brewery.run_level != _last_level:
		_last_level = brewery.run_level
		level_label.text = LEVEL_FORMAT % brewery.run_level

	# Unlike the level label above, this updates on every state change (not
	# just on a level-up) — XP itself ticks up on every sale/brew, and the
	# whole point of the bar is the constant "almost there" read between
	# level-ups, not just a snap the moment one happens.
	var xp_needed : int = Brewery.xp_required_for_level(brewery.run_level)
	level_progress_bar.value = float(brewery.run_xp) / float(xp_needed) if xp_needed > 0 else 0.0
	level_progress_bar.tooltip_text = LEVEL_PROGRESS_TOOLTIP_FORMAT % [brewery.run_xp, xp_needed]

	var new_risk: int = brewery.risk
	if last_risk != -1:
		var change = new_risk - last_risk
		if change != 0:
			_create_popup_effect(risk_label, change, "%", true)

	risk_label.text = "LVV Riski: " + str(new_risk) + "%"
	last_risk = new_risk

	if new_risk >= RISK_WARNING_THRESHOLD:
		risk_label.add_theme_color_override("font_color", RISK_WARNING_COLOR)
		if not _risk_warning_active:
			_risk_warning_active = true
			_pulse_risk_warning()
	else:
		risk_label.remove_theme_color_override("font_color")
		_risk_warning_active = false


## One-shot attention pulse the moment risk crosses into the warning
## zone — deliberately not looping (unlike DailyGoalsPanel's near-miss
## pulse) since this fires once per crossing, not for as long as a
## condition holds.
func _pulse_risk_warning() -> void:
	risk_label.pivot_offset = risk_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(risk_label, "scale", Vector2(1.3, 1.3), RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(risk_label, "scale", Vector2.ONE, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## `decimals` picks the display precision — 0 for whole-number stats
## (reputation, risk %), 1 for money (see Brewery.money's docstring on why
## it isn't a whole euro amount).
func _create_popup_effect(target_label: Label, amount: float, suffix: String, is_risk: bool, decimals: int = 0) -> void:
	var popup := Label.new()
	var magnitude_text : String = ("%.1f" % absf(amount)) if decimals > 0 else str(roundi(absf(amount)))

	if amount > 0:
		popup.text = "+" + magnitude_text + suffix
		popup.modulate = Color.RED if is_risk else Color.GREEN
	else:
		popup.text = "-" + magnitude_text + suffix
		popup.modulate = Color.GREEN if is_risk else Color.RED

	target_label.add_child(popup)
	popup.position = Vector2(80, 0)
	
	var tween := create_tween().set_parallel(true)
	var target_pos := popup.position + Vector2(0, -35)
	var target_color := popup.modulate
	target_color.a = 0.0
	
	tween.tween_property(popup, "position", target_pos, POPUP_EFFECT_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, POPUP_EFFECT_DURATION_SECONDS)
	
	tween.chain().tween_callback(popup.queue_free)
