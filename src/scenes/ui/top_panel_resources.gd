class_name TopPanelResources
extends HBoxContainer


const DAY_STRING : String = "Päivä: %s"

## Long enough to read a "+X €" popup before it fades.
const POPUP_EFFECT_DURATION_SECONDS : float = 1.8
## Gap after the label's text: a fixed offset put the popup inside long labels
## ("Kellarin salaisuus") and against the next one after short ones.
const POPUP_GAP : float = 4.0
const POPUP_FLOAT_DISTANCE : float = 35.0

## Near the raid threshold the risk label turns red and pulses once on entry.
const RISK_WARNING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches DailyGoalsPanel.GOAL_FAILING_COLOR
const RISK_WARNING_PULSE_SECONDS : float = 0.3
## Brightness, not scale: the pixel font blurs off whole sizes.
const RISK_WARNING_FLASH_COLOR : Color = Color(1.8, 1.8, 1.8)


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
## Level only rises and LevelUpWindow is its moment, so no popup; tracked to skip rewriting
## the label.
var _last_level : int = -1
## The warning pulse fires only when risk crosses into the zone, not while it stays there.
var _risk_warning_active: bool = false


func _ready() -> void:
	# Long tooltips wrap via TooltipFactory.
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


## The day and level are set only on change, so a language switch resets them.
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
	# Snapped so float noise from repeated += and -= never shows as "+0.0 €".
	var change : float = snappedf(money - last_money, 0.1) if last_money != -1.0 else 0.0
	money_label.text = "%.1f €" % money
	last_money = money
	if change != 0.0:
		_create_popup_effect(money_label, change, " €", false, 1)


func _update_reputation(reputation : int) -> void:
	var change : int = reputation - last_reputation if last_reputation != -1 else 0
	last_reputation = reputation

	# The bar shows the tier name; the exact value and the tier's details are in the tooltip.
	var tiers : Array[ReputationTier] = ReputationTiers.all()
	var tier : ReputationTier = ReputationTiers.tier_for(reputation, tiers)
	if tier == null:
		reputation_label.text = tr(ReputationTierText.VALUE_FORMAT) % reputation
		reputation_label.tooltip_text = ""
	else:
		reputation_label.text = tr(tier.tier_name)
		reputation_label.tooltip_text = ReputationTierText.tooltip(reputation, tier, ReputationTiers.next_tier(reputation, tiers))
	if change != 0:
		_create_popup_effect(reputation_label, change, "", false)


## Updates on every change: the XP bar is the constant "almost there" read.
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
	var change : int = risk - last_risk if last_risk != -1 else 0
	risk_label.text = RiskText.label(risk, threshold)
	risk_label.tooltip_text = _risk_tooltip(brewery, threshold)
	last_risk = risk
	if change != 0:
		_create_popup_effect(risk_label, change, "", true)

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
	var tween := create_tween()
	tween.tween_property(risk_label, "modulate", RISK_WARNING_FLASH_COLOR, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(risk_label, "modulate", Color.WHITE, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## `decimals` is 0 for reputation and risk, 1 for money (tracked to one decimal).
func _create_popup_effect(target_label: Label, amount: float, suffix: String, is_risk: bool, decimals: int = 0) -> void:
	var popup := Label.new()
	var magnitude_text : String = ("%.1f" % absf(amount)) if decimals > 0 else str(roundi(absf(amount)))
	# Rising risk is bad news, rising money and reputation good news.
	var good : bool = (amount > 0) != is_risk
	popup.text = ("+" if amount > 0 else "-") + magnitude_text + suffix
	popup.modulate = Color.GREEN if good else Color.RED

	target_label.add_child(popup)
	# The minimum size measures the new text now; size lags until the next layout pass.
	popup.position = Vector2(target_label.get_minimum_size().x + POPUP_GAP, 0.0)

	var tween := create_tween().set_parallel(true)
	var target_color := popup.modulate
	target_color.a = 0.0
	PixelStepTween.move_property(tween, popup, &"position", popup.position, popup.position + Vector2(0, -POPUP_FLOAT_DISTANCE), POPUP_EFFECT_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, POPUP_EFFECT_DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)
