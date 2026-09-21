class_name ModifierSelectWindow
extends Panel

## Lets the player pick this run's RunModifier instead of it being purely
## random — see RunModifierRegistry.get_run_start_modifiers(), which always
## offers normal/medium/hard in that fixed order. Purely a picker: it rolls
## and displays those modifiers and emits
## modifier_chosen when one is clicked, but never touches BrewEngine or
## scene transitions itself ("signal up, method down") — the host
## (MainMenu for "Aloita uusi peli", GameEndWindow for "Uusi yritys")
## is what actually starts the new game once it hears the choice.
## Reused as-is from both places via this shared scene.

signal modifier_chosen(modifier : RunModifier)

const TITLE_TEXT : String = "Valitse tämän kierroksen olosuhteet"
const ICON_FONT_SIZE : int = 40
const HEADER_FONT_SIZE : int = 18

## LeaderboardManager.get_entries() is already sorted best-score-first (see
## its own _insert_entry() docstring), so index 0 is always the current
## record — shown here at run *start* instead of only at run end, so a run
## has a concrete target from its first decision. Days-survived-from-a-
## busted/bankrupt run still reads fine here ("record" is just the best
## score on file, not necessarily a "survived" run).
const RECORD_FORMAT : String = "Ennätys: %d pistettä (päivä %d, %d annosta)"
const NO_RECORD_TEXT : String = "Ei vielä ennätystä. Tästä se lähtee."

@onready var title_label : Label = $MarginContainer/MainVBox/TitleLabel
@onready var record_label : Label = $MarginContainer/MainVBox/RecordLabel
@onready var cards_hbox : HBoxContainer = $MarginContainer/MainVBox/CardsHBox

## Populated by open(); index matches _card_buttons/cards_hbox children —
## _on_card_pressed(index) reads straight back into this, so the exact
## modifier clicked is always the one actually shown, not a re-roll.
var _offered_modifiers : Array[RunModifier] = []
var _card_buttons : Array[Button] = []
var _card_icon_labels : Array[Label] = []
var _card_header_labels : Array[Label] = []
var _card_description_labels : Array[Label] = []


func _ready() -> void:
	title_label.text = TITLE_TEXT

	for i in range(cards_hbox.get_child_count()):
		var card : Button = cards_hbox.get_child(i)
		_card_buttons.append(card)
		_card_icon_labels.append(card.get_node("CardVBox/IconLabel"))
		_card_header_labels.append(card.get_node("CardVBox/HeaderLabel"))
		_card_description_labels.append(card.get_node("CardVBox/DescriptionLabel"))
		card.pressed.connect(_on_card_pressed.bind(i))

	hide()


## Public entry point: rolls a fresh set of modifiers and shows the
## picker. Called by the host in place of what used to be a direct
## BrewEngine.start_new_game() call.
func open() -> void:
	_show_record()
	_offered_modifiers = RunModifierRegistry.get_run_start_modifiers()

	for i in range(_card_buttons.size()):
		var has_modifier : bool = i < _offered_modifiers.size()
		_card_buttons[i].visible = has_modifier
		if not has_modifier:
			continue

		var modifier : RunModifier = _offered_modifiers[i]
		_card_icon_labels[i].text = modifier.icon_placeholder
		_card_header_labels[i].text = modifier.modifier_name

		var stat_summary : String = modifier.get_stat_summary()
		_card_description_labels[i].text = modifier.description if stat_summary.is_empty() else modifier.description + "\n" + stat_summary

	show()


func _show_record() -> void:
	var entries : Array = LeaderboardManager.get_entries()
	if entries.is_empty():
		record_label.text = NO_RECORD_TEXT
		return

	var best : Dictionary = entries[0]
	record_label.text = RECORD_FORMAT % [best.get("score", 0), best.get("days_survived", 0), best.get("lifetime_bottles_sold", 0)]


func _on_card_pressed(index : int) -> void:
	if index >= _offered_modifiers.size():
		return

	var chosen : RunModifier = _offered_modifiers[index]
	hide()
	modifier_chosen.emit(chosen)
