class_name LevelUpWindow
extends Panel

## The "pick a perk" popup on level-up, three cards per offer. Pauses the tree
## (PROCESS_MODE_ALWAYS, z_index 100) and applies the perk itself. Also shows Joulupukki's
## wrapped gifts as blind cards; NaughtyList opens the one picked.

const CARD_COUNT : int = 3
const TITLE_FORMAT : String = "Taso %d!"
const GIFT_TITLE : String = "Joulupukin paketit"
const GIFT_ICON : String = "📦"
const GIFT_HEADER_FORMAT : String = "Paketti %d"
const GIFT_DESCRIPTION : String = "Kääritty huolella. Jokin sisällä kolisee."

@onready var title_label : Label = %TitleLabel
@onready var cards_hbox : HBoxContainer = %CardsHBox

## Level-ups that came while a choice was open (one grant can cross two levels), so each
## still gets its pick.
var _pending_levels : Array[int] = []
var _offered_perks : Array[RunPerk] = []
var _card_buttons : Array[Button] = []
var _card_icon_labels : Array[Label] = []
var _card_header_labels : Array[Label] = []
var _card_description_labels : Array[Label] = []
## Joulupukki's gifts waiting to be picked, and whether the cards show them now.
var _gift_count : int = 0
var _showing_gifts : bool = false
## Windows over the game (game menu, brew day, keg wash): an offer waits hidden until all
## have closed. A set, since the menu can open over the brew day.
var _blockers : Dictionary = {} # StringName -> true


func _ready() -> void:
	for i in range(cards_hbox.get_child_count()):
		var card : Button = cards_hbox.get_child(i)
		_card_buttons.append(card)
		_card_icon_labels.append(card.get_node("CardVBox/IconLabel"))
		_card_header_labels.append(card.get_node("CardVBox/HeaderLabel"))
		_card_description_labels.append(card.get_node("CardVBox/DescriptionLabel"))
		card.pressed.connect(_on_card_pressed.bind(i))

	# No X: a perk must be picked, so the keyboard lands on the first card.
	FirstFocus.attach(self)
	BrewerySignals.level_up_reached.connect(_on_level_up_reached)
	BrewerySignals.christmas_gifts_offered.connect(_on_christmas_gifts_offered)
	BrewEngine.brewery_changed.connect(_on_brewery_changed)
	BrewerySignals.game_ended.connect(_on_game_ended)
	GUISignals.game_menu_requested.connect(_block.bind(&"menu"))
	GUISignals.game_menu_closed.connect(_unblock.bind(&"menu"))
	GUISignals.brew_day_opened.connect(_block.bind(&"brew_day"))
	GUISignals.brew_day_closed.connect(_unblock.bind(&"brew_day"))
	GUISignals.keg_wash_opened.connect(_block.bind(&"keg_wash"))
	GUISignals.keg_wash_closed.connect(_unblock.bind(&"keg_wash"))
	PauseLock.hold_while_visible(self)
	hide()


## The end screen wins over a level-up in the same tick; the level stays pending for a
## continued run.
func _on_level_up_reached(new_level : int) -> void:
	_pending_levels.append(new_level)
	var brewery := BrewEngine.current_brewery
	var run_has_ended : bool = brewery != null and brewery.game_has_ended
	if not visible and not run_has_ended and _blockers.is_empty() and _offered_perks.is_empty():
		_show_next_pending_level()


## Waits behind an open perk offer or a blocking window, like a level-up.
func _on_christmas_gifts_offered(gifts : Array) -> void:
	_gift_count = gifts.size()
	if not visible and _blockers.is_empty() and _offered_perks.is_empty() and not _is_run_over():
		_show_gifts()


## A loaded save brings back an unopened gift offer; a new run drops any old one.
func _on_brewery_changed(brewery : Brewery) -> void:
	_gift_count = 0
	if _showing_gifts:
		_showing_gifts = false
		hide()
	if brewery != null and not brewery.christmas_gifts.is_empty():
		_on_christmas_gifts_offered(brewery.christmas_gifts)


func _show_gifts() -> void:
	_showing_gifts = true
	title_label.text = tr(GIFT_TITLE)
	for i in range(_card_buttons.size()):
		_card_buttons[i].visible = i < _gift_count
		_card_icon_labels[i].text = GIFT_ICON
		_card_header_labels[i].text = tr(GIFT_HEADER_FORMAT) % (i + 1)
		_card_header_labels[i].remove_theme_color_override("font_color")
		_card_description_labels[i].text = tr(GIFT_DESCRIPTION)
	_show_over_popups()


func _on_game_ended(_ending_type : String) -> void:
	_offered_perks.clear()
	_gift_count = 0
	_showing_gifts = false
	if visible:
		hide()


func _block(blocker : StringName) -> void:
	_blockers[blocker] = true
	hide()


## Brings back the same cards, so opening the menu never rerolls an offer.
func _unblock(blocker : StringName) -> void:
	_blockers.erase(blocker)
	if not _blockers.is_empty():
		return
	if _showing_gifts:
		_show_over_popups()
	elif not _offered_perks.is_empty():
		_show_over_popups()
	elif _gift_count > 0 and not _is_run_over():
		_show_gifts()
	elif not _pending_levels.is_empty() and not _is_run_over():
		_show_next_pending_level()


func _is_run_over() -> bool:
	var brewery := BrewEngine.current_brewery
	return brewery != null and brewery.game_has_ended


func _show_next_pending_level() -> void:
	if _pending_levels.is_empty():
		return

	var level : int = _pending_levels[0]
	title_label.text = tr(TITLE_FORMAT) % level
	_offered_perks = PerkRegistry.get_random_perks(CARD_COUNT)

	for i in range(_card_buttons.size()):
		var has_perk : bool = i < _offered_perks.size()
		_card_buttons[i].visible = has_perk
		if not has_perk:
			continue

		var perk : RunPerk = _offered_perks[i]
		_card_icon_labels[i].text = perk.icon_placeholder
		_card_header_labels[i].text = perk.perk_name
		_card_header_labels[i].add_theme_color_override("font_color", perk.get_tier_color())

		_card_description_labels[i].text = "[%s]\n%s" % [perk.get_tier_label(), perk.get_description()]

	_show_over_popups()


## An open dropdown is its own window over any z_index, and its closing click reached the
## card under it, so close it first.
func _show_over_popups() -> void:
	for window : Window in get_viewport().get_embedded_subwindows():
		if window is Popup:
			window.hide()
	show()


func _on_card_pressed(index : int) -> void:
	if _showing_gifts:
		_open_gift(index)
		return
	if index >= _offered_perks.size():
		return

	var brewery := BrewEngine.current_brewery
	if brewery != null:
		brewery.apply_perk(_offered_perks[index])

	_offered_perks.clear()
	hide()
	_pending_levels.pop_front()
	_show_next_pending_level()
	if not visible and _gift_count > 0:
		_show_gifts()


func _open_gift(index : int) -> void:
	_gift_count = 0
	_showing_gifts = false
	hide()
	GUISignals.christmas_gift_chosen.emit(index)
	_show_next_pending_level()
