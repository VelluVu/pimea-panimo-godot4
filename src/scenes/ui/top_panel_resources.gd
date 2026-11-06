class_name TopPanelResources
extends HBoxContainer


const DAY_STRING : String = "Päivä: %s"

## Long enough to read a "+X €" popup before it fades.
const POPUP_EFFECT_DURATION_SECONDS : float = 1.8
## Popups start under their plate and float down, so they never cover the next stat.
const POPUP_DROP : float = 6.0
const POPUP_FLOAT_DISTANCE : float = 30.0
const POPUP_META : StringName = &"top_bar_popup"

## Near the raid threshold the risk turns red, the siren lights and the plate pulses once.
const RISK_WARNING_COLOR : Color = Color(0.75686276, 0.3137255, 0.22745098, 1) # matches DailyGoalsPanel.GOAL_FAILING_COLOR
const RISK_WARNING_PULSE_SECONDS : float = 0.3
## Brightness, not scale: the pixel font blurs off whole sizes.
const RISK_WARNING_FLASH_COLOR : Color = Color(1.8, 1.8, 1.8)


## A brew's XP floats off the level, where the bar fills; the brew view has closed by
## then. Light blue like the sale XP popup in DialogWiring.
const XP_POPUP_FORMAT : String = "+%d XP"
const XP_POPUP_COLOR : Color = Color(0.4, 0.75, 1.0, 1)

const LEVEL_FORMAT : String = "Taso: %d"
const LEVEL_TOOLTIP_FORMAT : String = "Taso %d\n%d/%d XP\n%d XP seuraavaan tasoon"

## The clock on the cellar wall; its tooltip shows the time.
@export var clock_ui : ClockUI

@onready var money_chip : StatChip = $MoneyChip
@onready var reputation_chip : StatChip = $ReputationChip
@onready var risk_chip : StatChip = $RiskChip
@onready var level_chip : StatChip = $LevelChip
@onready var day_chip : StatChip = $DayChip
var last_money: float = -1.0
var last_reputation : int = -1
var last_risk: int = -1
## Level only rises and LevelUpWindow is its moment, so no popup; tracked to skip rewriting
## the label.
var _last_level : int = -1
## The warning pulse fires only when risk crosses into the zone, not while it stays there.
var _risk_warning_active: bool = false
var _brewery : Brewery = null


func _ready() -> void:
	money_chip.tooltip_source = _money_tooltip
	# Built on hover, so the time is current.
	day_chip.tooltip_source = _day_clock_tooltip
	clock_ui.tooltip_source = _clock_tooltip
	clock_ui.mouse_filter = Control.MOUSE_FILTER_PASS

	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.brew_xp_gained.connect(func(amount : int) -> void: _float_popup(level_chip, tr(XP_POPUP_FORMAT) % amount, XP_POPUP_COLOR))
	TimeManager.day_changed.connect(_on_day_changed)


## GUI calls this on every new run or loaded save.
func bind_brewery(brewery : Brewery) -> void:
	_brewery = brewery
	_brewery.emit_initial_values()
	_update_day_display(_brewery.current_day)


## The day and level are set only on change, so a language switch resets them.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _brewery != null:
		_last_level = -1
		_update_day_display(_brewery.current_day)
		_on_brewery_state_changed(_brewery)


func _on_day_changed(new_day: int) -> void:
	_update_day_display(new_day)


func _money_tooltip() -> String:
	if _brewery == null:
		return ""
	return MoneyText.tooltip(_brewery.money, _brewery.money_today, _brewery.money_recent_days)


## Only the time: the wall clock is read at a glance, the day label has the rest.
func _clock_tooltip() -> String:
	if _brewery == null:
		return ""
	return DayClockText.clock_time(TimeManager.get_day_progress())


func _day_clock_tooltip() -> String:
	if _brewery == null:
		return ""
	return DayClockText.tooltip(_brewery.current_day, DemoRules.last_day(), TimeManager.get_day_progress(), TimeManager.get_seconds_left(), TimeManager.day_duration_seconds)


func _update_day_display(day_num: int) -> void:
	if day_chip:
		day_chip.set_value(tr(DAY_STRING) % str(day_num))


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_update_money(brewery.money)
	_update_reputation(brewery.reputation)
	_update_level(brewery.run_level, brewery.run_xp)
	_update_risk(brewery)


func _update_money(money : float) -> void:
	# Snapped so float noise from repeated += and -= never shows as "+0,00 €".
	var change : float = snappedf(money - last_money, 0.01) if last_money != -1.0 else 0.0
	money_chip.set_value(NumberText.money(money))
	last_money = money
	if change != 0.0:
		_create_popup_effect(money_chip, change, " €", false, 2)


func _update_reputation(reputation : int) -> void:
	var change : int = reputation - last_reputation if last_reputation != -1 else 0
	last_reputation = reputation

	# The bar shows the tier name; the exact value and the tier's details are in the tooltip.
	var tiers : Array[ReputationTier] = ReputationTiers.all()
	var tier : ReputationTier = ReputationTiers.tier_for(reputation, tiers)
	if tier == null:
		reputation_chip.set_value(tr(ReputationTierText.VALUE_FORMAT) % reputation)
		reputation_chip.tooltip_text = ""
	else:
		reputation_chip.set_value(tr(tier.tier_name))
		reputation_chip.tooltip_text = ReputationTierText.tooltip(reputation, tier, ReputationTiers.next_tier(reputation, tiers))
	if change != 0:
		_create_popup_effect(reputation_chip, change, "", false)


## Updates on every change: the XP bar is the constant "almost there" read.
func _update_level(level : int, xp : int) -> void:
	if level != _last_level:
		_last_level = level
		level_chip.set_value(tr(LEVEL_FORMAT) % level)
	var xp_needed : int = Brewery.xp_required_for_level(level)
	level_chip.set_meter(float(xp) / float(xp_needed) if xp_needed > 0 else 0.0)
	level_chip.tooltip_text = tr(LEVEL_TOOLTIP_FORMAT) % [level, xp, xp_needed, maxi(0, xp_needed - xp)]


func _update_risk(brewery : Brewery) -> void:
	var risk : int = brewery.risk
	var threshold : int = brewery.get_effective_raid_threshold()
	var change : int = risk - last_risk if last_risk != -1 else 0
	# The number alone: the siren says what it is, the meter how close the raid is, and
	# the tooltip has the threshold.
	risk_chip.set_value(str(risk))
	risk_chip.set_meter(RiskText.fill(risk, threshold))
	risk_chip.tooltip_text = _risk_tooltip(brewery, threshold)
	last_risk = risk
	if change != 0:
		_create_popup_effect(risk_chip, change, "", true)

	var warning : bool = RiskText.is_warning(risk, threshold)
	risk_chip.set_icon(StatChip.TopBarIcon.SIREN_ON if warning else StatChip.TopBarIcon.SIREN_OFF)
	risk_chip.set_value_color(RISK_WARNING_COLOR if warning else Color(0, 0, 0, 0))
	if warning and not _risk_warning_active:
		_pulse_risk_warning()
	_risk_warning_active = warning


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
	tween.tween_property(risk_chip, "modulate", RISK_WARNING_FLASH_COLOR, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(risk_chip, "modulate", Color.WHITE, RISK_WARNING_PULSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## `decimals` is 0 for reputation and risk, 1 for money (tracked to one decimal).
func _create_popup_effect(chip: StatChip, amount: float, suffix: String, is_risk: bool, decimals: int = 0) -> void:
	var magnitude_text : String = NumberText.decimal(absf(amount), decimals) if decimals > 0 else str(roundi(absf(amount)))
	# Rising risk is bad news, rising money and reputation good news.
	var good : bool = (amount > 0) != is_risk
	_float_popup(chip, ("+" if amount > 0 else "-") + magnitude_text + suffix, Color.GREEN if good else Color.RED)


func _float_popup(chip : StatChip, text : String, color : Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.modulate = color
	popup.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# On the value label, lined up with the number it changes, starting under the plate.
	var label : Label = chip.value_label()
	# A cost and a sale often land together: each live popup pushes the new one a line lower.
	var live : int = label.get_children().filter(func(child : Node) -> bool: return child.has_meta(POPUP_META)).size()
	popup.set_meta(POPUP_META, true)
	label.add_child(popup)
	popup.position = Vector2(0.0, chip.size.y - label.position.y + POPUP_DROP + live * popup.get_line_height())

	var tween := create_tween().set_parallel(true)
	var target_color := popup.modulate
	target_color.a = 0.0
	# Downward: the bar sits at the top edge, so a rising popup left the screen.
	PixelStepTween.move_property(tween, popup, &"position", popup.position, popup.position + Vector2(0, POPUP_FLOAT_DISTANCE), POPUP_EFFECT_DURATION_SECONDS)
	tween.tween_property(popup, "modulate", target_color, POPUP_EFFECT_DURATION_SECONDS)
	tween.chain().tween_callback(popup.queue_free)
