class_name DialogWiring
extends Node

## THE FILE TO EDIT WHEN THIS SYSTEM MOVES TO ANOTHER PROJECT. It is the only place in
## this folder that knows the project: it connects the project's own signals to
## DialogView's interface and holds the project's popup wording. Everything else in the
## folder works unchanged. DialogView adds this as a child, so the connections go away
## with it.

const XP_POPUP_OFFSET : Vector2 = Vector2(0.0, -50.0)
const XP_POPUP_COLOR : Color = Color(0.949, 0.788, 0.42, 1) # same gold as BrewPreparationPanel
const XP_POPUP_FORMAT : String = "+%d XP"

## Popups sit well below the speech bubble so they read as coming from the customer:
## XP highest, reputation just under it, the tip beside them.
const REPUTATION_POPUP_OFFSET : Vector2 = Vector2(0.0, -25.0)
const REPUTATION_POPUP_FORMAT : String = "%+d Mainetta"

const TIP_POPUP_OFFSET : Vector2 = Vector2(40.0, -50.0)
const TIP_POPUP_COLOR : Color = Color.GREEN
const TIP_POPUP_FORMAT : String = "Tippi +%.1f €"
## A big or critical tip turns gold, like the treasure it is. Too wide to sit beside the
## XP popup, it gets its own row above it.
const LOUD_TIP_POPUP_COLOR : Color = Color(1.0, 0.84, 0.0, 1)
const LOUD_TIP_POPUP_OFFSET : Vector2 = Vector2(0.0, -80.0)

var _dialog : DialogView


func _ready() -> void:
	_dialog = get_parent() as DialogView
	BrewerySignals.dialogue_pushed.connect(_on_dialogue_pushed)
	BrewerySignals.customer_evicted.connect(_dialog.close_bubble)
	BrewerySignals.xp_popup_requested.connect(_on_xp_popup_requested)
	BrewerySignals.reputation_popup_requested.connect(_on_reputation_popup_requested)
	BrewerySignals.tip_popup_requested.connect(_on_tip_popup_requested)


## Special lines are shown elsewhere (the special event window), not as a bubble.
func _on_dialogue_pushed(text : String, is_special : bool, slot : int, speaker_pos : Vector2, display_time : float, fade_time : float) -> void:
	if not is_special:
		_dialog.show_bubble(text, slot, speaker_pos, display_time, fade_time)


func _on_xp_popup_requested(amount : int, character_pos : Vector2, tier : PopupTierRules.Tier) -> void:
	var emphasis : DialogView.Emphasis = _emphasis(tier)
	_dialog.show_popup(tr(XP_POPUP_FORMAT) % amount, XP_POPUP_COLOR, character_pos + _scaled(XP_POPUP_OFFSET, emphasis), emphasis)


func _on_reputation_popup_requested(amount : int, character_pos : Vector2, tier : PopupTierRules.Tier) -> void:
	var emphasis : DialogView.Emphasis = _emphasis(tier)
	_dialog.show_popup(tr(REPUTATION_POPUP_FORMAT) % amount, Color.GREEN if amount > 0 else Color.RED, character_pos + _scaled(REPUTATION_POPUP_OFFSET, emphasis), emphasis)


func _on_tip_popup_requested(amount : float, character_pos : Vector2, tier : PopupTierRules.Tier) -> void:
	var emphasis : DialogView.Emphasis = _emphasis(tier)
	if emphasis == DialogView.Emphasis.NORMAL:
		_dialog.show_popup(tr(TIP_POPUP_FORMAT) % amount, TIP_POPUP_COLOR, character_pos + TIP_POPUP_OFFSET)
	else:
		_dialog.show_popup(tr(TIP_POPUP_FORMAT) % amount, LOUD_TIP_POPUP_COLOR, character_pos + _scaled(LOUD_TIP_POPUP_OFFSET, emphasis), emphasis)


## Bigger text needs more room between the rows.
static func _scaled(offset : Vector2, emphasis : DialogView.Emphasis) -> Vector2:
	return offset * DialogView.POPUP_FONT_SCALES[emphasis]


static func _emphasis(tier : PopupTierRules.Tier) -> DialogView.Emphasis:
	match tier:
		PopupTierRules.Tier.CRITICAL:
			return DialogView.Emphasis.CRITICAL
		PopupTierRules.Tier.BIG:
			return DialogView.Emphasis.BIG
		_:
			return DialogView.Emphasis.NORMAL
