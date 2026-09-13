class_name LevelUpWindow
extends Panel

## Mid-run "you leveled up, pick a perk" popup — see Brewery.add_xp()/
## apply_perk() and RunPerk. Shares ModifierSelectWindow's card-picker
## shape exactly: icon + header + description, click to choose, three
## choices per offer.
##
## Deliberately does NOT pause the tree — unlike GameEndWindow (the run
## is over) or ModifierSelectWindow-during-restart (still "between runs"),
## a level-up is a small mid-play beat; customers/timers keep going behind
## it, same as AviRaidWindow/SpecialEventManager's popups.
##
## Applies the chosen perk directly to BrewEngine.current_brewery itself
## (like SaleReceiptLogWindow already reaches into brewery state
## directly) rather than emitting the choice upward — nothing else needs
## to react to which perk was picked, so there's no orchestrator this
## needs to report back to.

const CARD_COUNT : int = 3
const TITLE_FORMAT : String = "Taso %d!"

@onready var title_label : Label = $MarginContainer/MainVBox/TitleLabel
@onready var cards_hbox : HBoxContainer = $MarginContainer/MainVBox/CardsHBox

## Queued level-ups that arrived while a choice was already on screen —
## add_xp()'s while-loop can in principle fire level_up_reached more than
## once in a single frame (a huge XP grant crossing two thresholds), and
## the player should still get to pick for each one, not just the last.
var _pending_levels : Array[int] = []
var _offered_perks : Array[RunPerk] = []
var _card_buttons : Array[Button] = []
var _card_icon_labels : Array[Label] = []
var _card_header_labels : Array[Label] = []
var _card_description_labels : Array[Label] = []


func _ready() -> void:
	for i in range(cards_hbox.get_child_count()):
		var card : Button = cards_hbox.get_child(i)
		_card_buttons.append(card)
		_card_icon_labels.append(card.get_node("CardVBox/IconLabel"))
		_card_header_labels.append(card.get_node("CardVBox/HeaderLabel"))
		_card_description_labels.append(card.get_node("CardVBox/DescriptionLabel"))
		card.pressed.connect(_on_card_pressed.bind(i))

	BrewerySignals.level_up_reached.connect(_on_level_up_reached)
	hide()


func _on_level_up_reached(new_level : int) -> void:
	_pending_levels.append(new_level)
	if not visible:
		_show_next_pending_level()


func _show_next_pending_level() -> void:
	if _pending_levels.is_empty():
		return

	var level : int = _pending_levels[0]
	title_label.text = TITLE_FORMAT % level
	_offered_perks = PerkRegistry.get_random_perks(CARD_COUNT)

	for i in range(_card_buttons.size()):
		var has_perk : bool = i < _offered_perks.size()
		_card_buttons[i].visible = has_perk
		if not has_perk:
			continue

		var perk : RunPerk = _offered_perks[i]
		_card_icon_labels[i].text = perk.icon_placeholder
		_card_header_labels[i].text = perk.perk_name

		var stat_summary : String = perk.get_stat_summary()
		_card_description_labels[i].text = perk.description if stat_summary.is_empty() else perk.description + "\n" + stat_summary

	show()


func _on_card_pressed(index : int) -> void:
	if index >= _offered_perks.size():
		return

	var brewery := BrewEngine.current_brewery
	if brewery != null:
		brewery.apply_perk(_offered_perks[index])

	hide()
	_pending_levels.pop_front()
	_show_next_pending_level()
