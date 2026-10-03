class_name AchievementWiring
extends AchievementTracker

## This game's stats and the BrewerySignals that feed them: the one file to edit
## after copying the achievements system. The game's AchievementManager autoload
## extends this. CustomerRegistry gates customers on is_unlocked() (the robot
## needs STAT_BAR_SHIPMENTS 3, the drone STAT_LVV_BRIBES_SUCCEEDED 3).

## Once per shipment, whatever its bottle count.
const STAT_BAR_SHIPMENTS : StringName = &"bar_shipments"

## A succeeded RiskBribeEventData, the only LVV special event so far.
const STAT_LVV_BRIBES_SUCCEEDED : StringName = &"lvv_bribes_succeeded"

## Ratchet: hops whose min_reputation is within the current reputation. Only
## hops use min_reputation, and a raid's reputation drop never takes it back.
const STAT_HOPS_UNLOCKED : StringName = &"hops_unlocked"

## Reported by CustomerRegistry, which owns the customer eligibility rules.
const STAT_CUSTOMERS_UNLOCKED : StringName = &"customers_unlocked"

## Lifetime counters fed straight from BrewerySignals, one per event.
const STAT_BATCHES_BREWED : StringName = &"batches_brewed"
const STAT_BOTTLES_SOLD : StringName = &"bottles_sold"
## In cents, since tips arrive as fractions of a euro.
const STAT_TIPS_CENTS : StringName = &"tips_cents"
const STAT_GROUP_VISITS : StringName = &"group_visits"
const STAT_BAR_FIGHTS : StringName = &"bar_fights"
const STAT_RAIDS_EXPERIENCED : StringName = &"raids_experienced"
const STAT_RUNS_SURVIVED : StringName = &"runs_survived"
## Ratchets (highest ever seen), like STAT_HOPS_UNLOCKED.
const STAT_HIGHEST_MONEY : StringName = &"highest_money"
const STAT_HIGHEST_REPUTATION : StringName = &"highest_reputation"
const STAT_HIGHEST_LEVEL : StringName = &"highest_level"
## Brews whose spices suited the style, and brews that broke the Reinheitsgebot.
const STAT_SPICED_BREWS : StringName = &"spiced_brews"
const STAT_PURITY_LAW_BROKEN : StringName = &"purity_law_broken"

const ENDING_SURVIVED : String = "survived"

const ACHIEVEMENT_FOLDER_PATH : String = "res://src/resources/achievements/"


func _init() -> void:
	save_path = "user://achievements.cfg"


func _ready() -> void:
	super._ready()
	achievement_pool.assign(ResourceFolder.load_all(ACHIEVEMENT_FOLDER_PATH, AchievementData))
	BrewerySignals.keg_shipped_to_bar.connect(_on_keg_shipped_to_bar)
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	BrewerySignals.special_event_resolved.connect(_on_special_event_resolved)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	BrewerySignals.beer_brewed.connect(increment_stat.bind(STAT_BATCHES_BREWED, 1).unbind(1))
	BrewerySignals.bottles_sold.connect(func(amount : int) -> void: increment_stat(STAT_BOTTLES_SOLD, amount))
	BrewerySignals.sale_tip_gained.connect(_on_sale_tip_gained)
	BrewerySignals.group_visit_announced.connect(increment_stat.bind(STAT_GROUP_VISITS, 1).unbind(1))
	BrewerySignals.bar_fight_triggered.connect(increment_stat.bind(STAT_BAR_FIGHTS, 1).unbind(1))
	BrewerySignals.lvv_raid_triggered.connect(increment_stat.bind(STAT_RAIDS_EXPERIENCED, 1).unbind(3))
	BrewerySignals.level_up_reached.connect(func(level : int) -> void: set_stat_if_higher(STAT_HIGHEST_LEVEL, level))
	BrewerySignals.game_ended.connect(_on_game_ended)
	BrewerySignals.brew_spiced.connect(_on_brew_spiced)


## Called by CustomerRegistry, which alone knows when a customer's gates are all met.
func report_customer_unlocked() -> void:
	increment_stat(STAT_CUSTOMERS_UNLOCKED)


## One stat per style, so each style can have its own achievement (tyyli_*.tres).
static func style_stat_key(style : int) -> StringName:
	return StringName("style_discovered_%d" % style)


## Split out of _on_brewery_state_changed() so it can be tested with
## hand-built IngredientData, without the IngredientDatabase autoload.
static func count_unlocked_hops(ingredients : Array, reputation : int) -> int:
	var unlocked_hop_count : int = 0
	for ingredient : IngredientData in ingredients:
		if ingredient.type == IngredientData.IngredientType.HOP and ingredient.min_reputation <= reputation:
			unlocked_hop_count += 1
	return unlocked_hop_count


func _on_keg_shipped_to_bar(_style_name : String, _bar_name : String, _bottles : int, _payout : float, _risk_added : int) -> void:
	increment_stat(STAT_BAR_SHIPMENTS)


func _on_style_discovered(style : int) -> void:
	increment_stat(style_stat_key(style))


func _on_special_event_resolved(succeeded : bool, event_data : SpecialEventData) -> void:
	if succeeded and event_data is RiskBribeEventData:
		increment_stat(STAT_LVV_BRIBES_SUCCEEDED)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	set_stat_if_higher(STAT_HOPS_UNLOCKED, count_unlocked_hops(IngredientDatabase.database.values(), brewery.reputation))
	set_stat_if_higher(STAT_HIGHEST_MONEY, floori(brewery.money))
	set_stat_if_higher(STAT_HIGHEST_REPUTATION, brewery.reputation)


func _on_sale_tip_gained(amount : float) -> void:
	var cents : int = roundi(amount * 100.0)
	if cents > 0:
		increment_stat(STAT_TIPS_CENTS, cents)


func _on_brew_spiced(_style_name : String, spice_bonus : float) -> void:
	increment_stat(STAT_SPICED_BREWS if spice_bonus > 0.0 else STAT_PURITY_LAW_BROKEN)


func _on_game_ended(ending_type : String) -> void:
	if ending_type == ENDING_SURVIVED:
		increment_stat(STAT_RUNS_SURVIVED)
