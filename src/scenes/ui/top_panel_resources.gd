class_name TopPanelResources
extends HBoxContainer


const DAY_STRING : String = "Päivä: %s"

## Long enough to read a "+X €" popup before it fades.
const POPUP_EFFECT_DURATION_SECONDS : float = 1.8
const POPUP_OFFSET : Vector2 = Vector2(80, 0)
const POPUP_FLOAT_DISTANCE : float = 35.0

## Near the raid threshold (RiskText.is_warning) the risk label turns red and pulses
## once on entry, on top of the audio tension drone.
const RISK_WARNING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches DailyGoalsPanel.GOAL_FAILING_COLOR
const RISK_WARNING_PULSE_SECONDS : float = 0.3


const LEVEL_FORMAT : String = "Taso: %d"
const LEVEL_TOOLTIP_FORMAT : String = "Taso %d\n%d/%d XP\n%d XP seuraavaan tasoon"

@onready var money_label : Label = $MoneyLabel
@onready var reputation_label : Label = $ReputationLabel
@onready var level_label : Label = $LevelBox/LevelLabel
@onready var level_progress_bar : ProgressBar = $LevelBox/LevelProgressBar
@onready var risk_label : Label = $RiskLabel
@onready var day_label : Label = $DayLabel
@onready var clock_ui : ClockUI = $ClockUITextureRect
var last_money: float = -1.0
var last_reputation : int = -1
var last_risk: int = -1
## Level only goes up and LevelUpWindow is its moment, so no popup: tracked only to
## skip rewriting the label.
var _last_level : int = -1
## The warning pulse fires only when risk crosses into the zone, not while it stays there.
var _risk_warning_active: bool = false


func _ready() -> void:
	# Scene-defined nodes get their tooltip script at runtime, so long tooltips wrap
	# via TooltipFactory instead of overflowing.
	level_progress_bar.set_script(TooltipProgressBar)
	level_label.set_script(TooltipLabel)
	level_label.mouse_filter = Control.MOUSE_FILTER_PASS
	reputation_label.set_script(TooltipLabel)
	reputation_label.mouse_filter = Control.MOUSE_FILTER_PASS
	risk_label.set_script(TooltipLabel)
	risk_label.mouse_filter = Control.MOUSE_FILTER_PASS
	money_label.set_script(LiveTooltipLabel)
	money_label.set(&"tooltip_source", _money_tooltip)
	money_label.mouse_filter = Control.MOUSE_FILTER_PASS
	# The day and the clock share one tooltip, built on hover so the time is current.
	day_label.set_script(LiveTooltipLabel)
	day_label.set(&"tooltip_source", _day_clock_tooltip)
	day_label.mouse_filter = Control.MOUSE_FILTER_PASS
	clock_ui.tooltip_source = _day_clock_tooltip
	clock_ui.mouse_filter = Control.MOUSE_FILTER_PASS

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	TimeManager.day_changed.connect(_on_day_changed)

	if BrewEngine.current_brewery != null:
		BrewEngine.current_brewery.emit_initial_values()
		_update_day_display(BrewEngine.current_brewery.current_day)


## The day and the level are only set on change, so a language
## switch resets them; the rest follows from brewery_state_changed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and BrewEngine.current_brewery != null:
		_last_level = -1
		_update_day_display(BrewEngine.current_brewery.current_day)
		_on_brewery_state_changed(BrewEngine.current_brewery)


func _on_day_changed(new_day: int) -> void:
	_update_day_display(new_day)


func _money_tooltip() -> String:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return ""
	return MoneyText.tooltip(brewery.money, brewery.money_today, brewery.money_recent_days)


func _day_clock_tooltip() -> String:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		return ""
	return DayClockText.tooltip(brewery.current_day, DemoRules.last_day(), TimeManager.get_day_progress(), TimeManager.get_seconds_left(), TimeManager.day_duration_seconds)


func _update_day_display(day_num: int) -> void:
	if day_label:
		day_label.text = tr(DAY_STRING) % str(day_num)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_update_money(brewery.money)
	_update_reputation(brewery.reputation)
	_update_level(brewery.run_level, brewery.run_xp)
	_update_risk(brewery)


func _update_money(money : float) -> void:
	if last_money != -1.0:
		# Snapped so float noise from repeated += and -= never shows as "+0.0 €".
		var change := snappedf(money - last_money, 0.1)
		if change != 0.0:
			_create_popup_effect(money_label, change, " €", false, 1)
	money_label.text = "%.1f €" % money
	last_money = money


func _update_reputation(reputation : int) -> void:
	if last_reputation != -1 and reputation != last_reputation:
		_create_popup_effect(reputation_label, reputation - last_reputation, "", false)
	last_reputation = reputation

	# The bar shows the tier name; the exact value and the tier's details are in the tooltip.
	var tiers : Array[ReputationTier] = ReputationTiers.all()
	var tier : ReputationTier = ReputationTiers.tier_for(reputation, tiers)
	if tier == null:
		reputation_label.text = tr(ReputationTierText.VALUE_FORMAT) % reputation
		reputation_label.tooltip_text = ""
		return
	reputation_label.text = tr(tier.tier_name)
	reputation_label.tooltip_text = ReputationTierText.tooltip(reputation, tier, ReputationTiers.next_tier(reputation, tiers))


## The bar updates on every change: XP ticks up on each sale and brew, and the point
## is the constant "almost there" read between level-ups.
func _update_level(level : int, xp : int) -> void:
	if level != _last_level:
		_last_level = level
		level_label.text = tr(LEVEL_FORMAT) % level
	var xp_needed : int = Brewery.xp_required_for_level(level)
	level_progress_bar.value = float(xp) / float(xp_needed) if xp_needed > 0 else 0.0
	# The label and the thin bar under it share one tooltip.
	level_progress_bar.tooltip_text = tr(LEVEL_TOOLTIP_FORMAT) % [level, xp, xp_needed, maxi(0, xp_needed - xp)]
	level_label.tooltip_text = level_progress_bar.tooltip_text


func _update_risk(brewery : Brewery) -> void:
	var risk : int = brewery.risk
	var threshold : int = brewery.get_effective_raid_threshold()
	if last_risk != -1 and risk != last_risk:
		_create_popup_effect(risk_label, risk - last_risk, "", true)
	risk_label.text = RiskText.label(risk, threshold)
	risk_label.tooltip_text = _risk_tooltip(brewery, threshold)
	last_risk = risk

	if RiskText.is_warning(risk, threshold):
		risk_label.add_theme_color_override("font_color", RISK_WARNING_COLOR)
		if not _risk_warning_active:
			_risk_warning_active = true
			_pulse_risk_warning()
	else:
		risk_label.remove_theme_color_override("font_color")
		_risk_warning_active = false


func _risk_tooltip(brewery : Brewery, threshold : int) -> String:
	var base : int = Brewery.LVV_RAID_THRESHOLD
	var tier : ReputationTier = brewery.get_reputation_tier()
	var fame_penalty : int = tier.raid_threshold_penalty if tier != null else 0
	var escalation : float = InspectionService.raid_escalation(brewery.raid_count)
	return RiskText.tooltip(brewery.risk, threshold, base, brewery.stats.raid_threshold(base) - base, fame_penalty,
		brewery.raid_count, InspectionService.raid_limit(brewery),
		InspectionService.raid_fine(brewery.money, escalation), ReputationRules.raid_penalty(brewery.reputation, escalation))


## One-shot, unlike DailyGoalsPanel's looping near-miss pulse: it marks the crossing.
func _pulse_risk_warning() -> void:
	risk_label.pivot_offset = risk_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(risk_label, "scale", Vector2(1.3, 1.3), RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(risk_label, "scale", Vector2.ONE, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## `decimals` is 0 for reputation and risk, 1 for money (tracked to one decimal).
func _create_popup_effect(target_label: Label, amount: float, suffix: String, is_risk: bool, decimals: int = 0) -> void:
	var popup := Label.new()
	var magnitude_text : String = ("%.1f" % absf(amount)) if decimals > 0 else str(roundi(absf(amount)))
	# Rising risk is bad news, rising money and reputation good news.
	var good : bool = (amount > 0) != is_risk
	popup.text = ("+" if amount > 0 else "-") + magnitude_text + suffix
	popup.modulate = Color.GREEN if good else Color.RED

	target_label.add_child(popup)
	popup.position = POPUP_OFFSET

	var tween := create_tween().set_parallel(true)
	var target_color := popup.modulate
	target_color.a = 0.0
	tween.tween_property(popup, "position", popup.position + Vector2(0, -POPUP_FLOAT_DISTANCE), POPUP_EFFECT_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, POPUP_EFFECT_DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)
