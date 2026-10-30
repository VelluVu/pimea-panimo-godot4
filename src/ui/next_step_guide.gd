class_name NextStepGuide
extends Node

## Answers "what now?": until the first brew it points the long way round (the recipe
## book's Kotikalja page, the shop and its "Osta puuttuvat", the brewery's "Täytä resepti",
## "Pane"), so the player learns the places; the goals panel shows the step as a line.
## While Aatu's tutorial is on (GuideParts) he says each step in the speech box, and after
## the first brew day talks through the goals, the recipe book and the upgrades.
## The rules are NextStepRules; GUI builds this and hands it the views.

## The brewery and shop spots start with their hover label; the arch and the till are
## below it.
const HOVER_LABEL_DROP : float = 24.0
## The shelf's hover label sits above the bottles; the arrow goes down to them.
const SHELF_TOP_DROP : float = 18.0
## The warehouse doorway in its hover label's coordinates: the label stays clear of the
## screen edge, left of the door.
const WAREHOUSE_DOOR_AREA : Rect2 = Rect2(87, -42, 43, 194)
## How long a talk line stays after Aatu has said it.
const TALK_CONTINUE_SECONDS : float = 4.0
## Under the bar's views, between the options button and the console.
const SPEECH_RECT : Rect2 = Rect2(36, 302, 524, 54)
## While Aatu talks, the open recipe book ends this far above him; its rows scroll.
const BOOK_GAP : float = 4.0

var _pointer : NextStepPointer
var _speech : GuideSpeechBox
var _goals_panel : DailyGoalsPanel
var _brewery_entrance : Control
var _shop_entrance : Control
var _recipe_shelf : Control
var _brewery_book : Control
var _warehouse : Control
var _upgrades_button : Control
var _recipe_library : RecipeLibraryWindow
var _brewing_view : BrewingView
var _shop_view : ShopView
var _preparation_panel : BrewPreparationPanel
var _brew_day_open : bool = false
var _refresh_queued : bool = false
## Runtime only: after a reload a player who already bought skips the book anyway.
var _recipe_read : bool = false
## The after-brew talk's line, or -1 when Aatu is not talking.
var _talk : int = -1
## Aatu's goodbye after "Ohita opastus" was switched on mid-tutorial.
var _forgetful : bool = false


## `places` holds the cellar spots: `brewery`, `shop`, `recipe_shelf`, `brewery_book`,
## `warehouse` and `upgrades`.
func setup(pointer : NextStepPointer, speech : GuideSpeechBox, goals_panel : DailyGoalsPanel, places : Dictionary, recipe_library : RecipeLibraryWindow, brewing_view : BrewingView, shop_view : ShopView, preparation_panel : BrewPreparationPanel) -> void:
	_pointer = pointer
	_speech = speech
	_goals_panel = goals_panel
	_brewery_entrance = places.brewery
	_shop_entrance = places.shop
	_recipe_shelf = places.recipe_shelf
	_brewery_book = places.brewery_book
	_warehouse = places.warehouse
	_upgrades_button = places.upgrades
	_recipe_library = recipe_library
	_brewing_view = brewing_view
	_shop_view = shop_view
	_preparation_panel = preparation_panel


func _ready() -> void:
	# The recipe book pauses the game while this walks through it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	BrewerySignals.brewery_state_changed.connect(_queue_refresh.unbind(1))
	BrewEngine.brewery_changed.connect(_on_brewery_changed)
	GUISignals.bar_view_entered.connect(_queue_refresh)
	GUISignals.bar_view_exited.connect(_queue_refresh)
	GUISignals.brew_day_opened.connect(_set_brew_day_open.bind(true))
	GUISignals.brew_day_closed.connect(_on_brew_day_closed)
	SettingsManager.option_changed.connect(_on_option_changed)
	_recipe_library.visibility_changed.connect(_queue_refresh)
	_recipe_library.page_changed.connect(_on_library_page_changed)
	_speech.next_pressed.connect(_on_speech_next)
	_speech.skipped.connect(_on_speech_skipped)
	_speech.line_typed.connect(_on_line_typed)
	_speech.hide()
	_queue_refresh()


func _on_brewery_changed(_brewery : Brewery) -> void:
	_recipe_read = false
	_talk = -1
	_queue_refresh()


func _on_library_page_changed(style : int) -> void:
	if style == BeerStyle.Style.KOTIKALJA:
		_recipe_read = true
	_queue_refresh()


func _set_brew_day_open(is_open : bool) -> void:
	_brew_day_open = is_open
	_queue_refresh()


func _on_brew_day_closed() -> void:
	_set_brew_day_open(false)


func _on_speech_next() -> void:
	if _forgetful:
		_forgetful = false
	elif _talk >= 0:
		_talk += 1
		if _talk >= CellarGuideText.Talk.size():
			_talk = -1
			GuideParts.finish(GuideParts.Part.TALK, BrewEngine.current_brewery)
	_queue_refresh()


## The talk moves on by itself a moment after each line; Jatka is for quick readers.
func _on_line_typed() -> void:
	_queue_refresh()
	if _talk < 0:
		return
	var line : int = _talk
	await get_tree().create_timer(TALK_CONTINUE_SECONDS, true).timeout
	if _talk == line and not _brew_day_open:
		_on_speech_next()


## "Ohita opas" turns the whole tutorial off, as "Ohita opastus" in Asetukset does, where it
## can be turned back on. The box goes first, or the setting's change would have Aatu say
## his "already told you" line to a player who just asked him to stop.
func _on_speech_skipped() -> void:
	_talk = -1
	_speech.hide()
	GuideParts.set_skipped(true)
	_queue_refresh()


func _on_option_changed(key : String, value : Variant) -> void:
	if key != SettingsManager.OPTION_SKIP_TUTORIAL:
		return
	if value and _speech.visible:
		_talk = -1
		_forgetful = true
	_queue_refresh()


## Deferred: the buttons update their disabled state from the same signals, in any order.
func _queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery == null:
		_show(NextStepRules.Step.NONE)
		return

	var inventory : Inventory = brewery.inventory
	if _first_brew_done(brewery):
		_show(NextStepRules.after_first_brew(not inventory.batches_on_serve().is_empty(), not inventory.fermenting.is_empty()))
		return

	var bought_any : bool = brewery.lifetime_malt_kg_bought > 0 or brewery.tutorial_bought_yeast
	# Both buy buttons follow the same recipe; the brewery's updates even while hidden.
	var missing : bool = not _brewing_view.buy_missing_button.disabled
	var can_brew : bool = not _preparation_panel.start_brew_button.disabled
	var kotikalja_page : bool = _recipe_library.selected_style == BeerStyle.Style.KOTIKALJA
	_show(NextStepRules.first_brew(_view(), _recipe_library.visible, kotikalja_page, _recipe_read, bought_any, missing, can_brew))


## One-way: a run past its first brew never sees the pointer again, even with empty kegs.
func _first_brew_done(brewery : Brewery) -> bool:
	return brewery.tutorial_brewed_kotikalja or not brewery.inventory.brew_batches.is_empty() or not brewery.inventory.fermenting.is_empty()


func _view() -> NextStepRules.View:
	if _shop_view.visible:
		return NextStepRules.View.SHOP
	if _brewing_view.visible:
		return NextStepRules.View.BREWERY
	return NextStepRules.View.BAR


func _show(step : NextStepRules.Step) -> void:
	_goals_panel.show_next_step(NextStepText.of(step))
	_show_speech(step)
	# The brew day has its own guide; "Ohita opastus" leaves the player free.
	# The pointer waits until Aatu has said his line (line_typed refreshes).
	if _brew_day_open or GuideParts.is_skipped() or (_speech.visible and _speech.is_typing()):
		_pointer.point_at(null, NextStepPointer.Style.FRAME)
	elif _talk >= 0:
		_point_at_talk(_talk)
	# The pointer belongs to Aatu's route: once "Ohita opas" ends it, nothing points.
	elif GuideParts.is_on(GuideParts.Part.CELLAR, BrewEngine.current_brewery):
		_point_at_step(step)
	else:
		_point_at_step(NextStepRules.Step.NONE)


func _show_speech(step : NextStepRules.Step) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	# The talk starts after the first brew, and again from the start after a reload.
	if _talk < 0 and not _forgetful and not _brew_day_open and GuideParts.is_on(GuideParts.Part.TALK, brewery):
		_talk = 0
	var line : String = CellarGuideText.of(step) if GuideParts.is_on(GuideParts.Part.CELLAR, brewery) else ""
	if _forgetful:
		line = CellarGuideText.FORGETFUL_TEXT
	elif _talk >= 0:
		line = CellarGuideText.talk(_talk as CellarGuideText.Talk)
	var speaking : bool = not _brew_day_open and not line.is_empty()
	_make_room_in_book(speaking)
	if not speaking:
		_speech.hide()
		_speech.forget_line()
		return
	_speech.position = SPEECH_RECT.position
	_speech.size = SPEECH_RECT.size
	_speech.say(line, _forgetful or _talk >= 0, not _forgetful)
	_speech.show()


func _make_room_in_book(speaking : bool) -> void:
	var book_bottom : float = _recipe_library.get_parent_area_size().y * _recipe_library.anchor_bottom
	_recipe_library.offset_bottom = minf(0.0, SPEECH_RECT.position.y - BOOK_GAP - book_bottom) if speaking else 0.0


func _point_at_talk(line : int) -> void:
	match line:
		CellarGuideText.Talk.GOALS:
			_pointer.point_at(_goals_panel, NextStepPointer.Style.FRAME)
		CellarGuideText.Talk.RECIPES:
			_pointer.point_at(_recipe_shelf, NextStepPointer.Style.ARROW_ABOVE, SHELF_TOP_DROP)
		CellarGuideText.Talk.UPGRADES:
			_pointer.point_at(_upgrades_button, NextStepPointer.Style.FRAME)
		CellarGuideText.Talk.BREWERY_BOOK:
			_pointer.point_at(_brewery_book, NextStepPointer.Style.ARROW_ABOVE, HOVER_LABEL_DROP)
		_:
			_pointer.point_at(null, NextStepPointer.Style.FRAME)


func _point_at_step(step : NextStepRules.Step) -> void:
	match step:
		NextStepRules.Step.OPEN_RECIPES:
			_pointer.point_at(_recipe_shelf, NextStepPointer.Style.ARROW_ABOVE, SHELF_TOP_DROP)
		NextStepRules.Step.PICK_RECIPE:
			_pointer.point_at(_recipe_library.index_button(BeerStyle.Style.KOTIKALJA), NextStepPointer.Style.FRAME)
		NextStepRules.Step.LOAD_RECIPE:
			_pointer.point_at(_recipe_library.load_button, NextStepPointer.Style.FRAME)
		NextStepRules.Step.GO_TO_SHOP:
			_pointer.point_at(_shop_entrance, NextStepPointer.Style.ARROW_ABOVE, HOVER_LABEL_DROP)
		NextStepRules.Step.BUY_MISSING:
			_pointer.point_at(_shop_view.buy_missing_button, NextStepPointer.Style.FRAME)
		NextStepRules.Step.CLOSE_SHOP:
			# Aatu shows where the bought goods are; closing the shop is the X beside them.
			_pointer.point_at(_warehouse, NextStepPointer.Style.FRAME_ARROW_LEFT, 0.0, WAREHOUSE_DOOR_AREA)
		NextStepRules.Step.OPEN_BREWERY:
			_pointer.point_at(_brewery_entrance, NextStepPointer.Style.ARROW_ABOVE, HOVER_LABEL_DROP)
		NextStepRules.Step.ADD_INGREDIENTS:
			_pointer.point_at(_brewing_view.fill_from_inventory_button, NextStepPointer.Style.FRAME)
		NextStepRules.Step.START_BREW:
			_pointer.point_at(_preparation_panel.start_brew_button, NextStepPointer.Style.FRAME)
		_:
			_pointer.point_at(null, NextStepPointer.Style.FRAME)
