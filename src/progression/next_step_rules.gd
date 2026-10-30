class_name NextStepRules
extends RefCounted

## What the player should do next. Until the first brew every step names one place or
## button (NextStepGuide points at it) and walks the long way round, so the player learns
## the places: the recipe book, the shop, the brewery. After that only the stuck states
## get a step; the daily goals carry the rest.

enum Step { NONE, OPEN_RECIPES, PICK_RECIPE, LOAD_RECIPE, GO_TO_SHOP, BUY_MISSING, CLOSE_SHOP, OPEN_BREWERY, ADD_INGREDIENTS, START_BREW, BREW_MORE, WAIT_FERMENT }
enum View { BAR, BREWERY, SHOP }


## `kotikalja_page`: the open book shows the Kotikalja page, whose "Lataa resepti" is
## explained. `recipe_read`: that page has been opened. `bought_any` skips the recipe book
## for a player who found the shop on their own. `missing`: the recipe needs more than is
## owned. `can_brew` mirrors "Pane", so the step never names a button that refuses.
static func first_brew(view : View, library_open : bool, kotikalja_page : bool, recipe_read : bool, bought_any : bool, missing : bool, can_brew : bool) -> Step:
	if library_open and kotikalja_page and not bought_any:
		return Step.LOAD_RECIPE
	if not recipe_read and not bought_any:
		return Step.PICK_RECIPE if library_open else Step.OPEN_RECIPES
	if can_brew:
		return Step.OPEN_BREWERY if view == View.BAR else Step.START_BREW
	if missing:
		return Step.BUY_MISSING if view == View.SHOP else Step.GO_TO_SHOP
	match view:
		View.BREWERY:
			return Step.ADD_INGREDIENTS
		View.SHOP:
			return Step.CLOSE_SHOP
		_:
			return Step.OPEN_BREWERY


## An empty bar is the one state the goals do not explain.
static func after_first_brew(beer_on_serve : bool, fermenting : bool) -> Step:
	if beer_on_serve:
		return Step.NONE
	return Step.WAIT_FERMENT if fermenting else Step.BREW_MORE
