class_name CustomerData
extends Resource


enum BarFightTrigger { RANDOM, NOT_ENOUGH_BEER, BOUGHT_MANY }

const DEFAULT_TITLE: String = "Asiakas"
const DEFAULT_NAMES: Array[String] = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]
## get_batch_preference() for a batch no taste tier takes.
const NOT_TO_TASTE: float = -1.0

@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var title: String = ""
@export var first_names: Array[String] = []
@export var min_quality: float = 0.5
## A connoisseur buys a beer below min_quality anyway and grumbles about it (see
## SaleEvaluation.BELOW_BAR_REPUTATION); everyone else refuses it.
@export var buys_below_bar: bool = false
## Tip generosity only: every customer pays a style's fixed price.
@export var budget_multiplier: float = 1.0
@export var primary_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var secondary_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA
## Liked as much as secondary_style. Unlike accepted_styles, other styles stay on the menu
## (the metalheads also like Baltic Porter).
@export var also_likes: Array[BeerStyle.Style] = []

## Taste tiers: a non-empty favourite_rules replaces the style fields above: favourite,
## second choice, last resort (sold with dialogue_wrong_style), else refused. The style
## fields stay as hints for the bots and the walk-in after a brew.
@export_group("Maku")
@export var favourite_rules: Array[TasteRule] = []
@export var second_rules: Array[TasteRule] = []
@export var last_resort_rules: Array[TasteRule] = []
## Each visit one style of favourite_rules becomes the favourite (roll_favourite()); the
## rest of the tier counts as the second choice.
@export var rolls_favourite: bool = false

@export_group("Ulkoasu")
@export var sprite_frames: SpriteFrames = null
@export var skin_base_color: Color = Color(0.918, 0.831, 0.667)
@export var hair_base_color: Color = Color(0.722, 0.435, 0.314)
@export var clothes_base_color: Color = Color(0.0, 0.6, 0.859)
@export var shoes_base_color: Color = Color(0.451, 0.243, 0.224)
@export var randomize_skin: bool = true
@export var randomize_hair: bool = true
@export var randomize_clothes: bool = true
@export var randomize_shoes: bool = true

@export_group("Movement Physics")
@export var stair_step_duration: float = 0.3
@export var floor_walk_speed: float = 120.0
## False for customers who stow the beer inside themselves (Lähettirobotti).
@export var carries_glass_out: bool = true

@export_group("Äänet")
## Pitch of the babble when this customer speaks: under 1 is deeper, over 1 higher.
@export var voice_pitch: float = 1.0
## False for customers who roll or fly instead of walking.
@export var makes_footsteps: bool = true
## Loops quietly wherever the customer goes (the drone's rotors), or null for none.
@export var ambient_loop: AudioStream = null

@export_group("Dialogues")
@export_multiline var dialogue_intro: String = "Moro. Oisko jotain juotavaa?"
@export_multiline var dialogue_success: String = "Kylläpä uppoo! Tässä rahat."
@export_multiline var dialogue_fallback: String = "No, tämäkin käy paremman puutteessa."
@export_multiline var dialogue_wrong_style: String = "Ei tää sitäkään ollu, mut menköön..."
@export_multiline var dialogue_reject: String = "Mitä helvettiä sä mulle myyt? Pitää tunkkis."
## Said leaving without buying: nothing in stock, or nothing clears a strict requirement.
@export_multiline var dialogue_no_match: String = "Ei täällä ollu mitään minulle. Ehkä ensi kerralla."
## Said before the sale, naming the batch picked (%s is the style name).
@export_multiline var dialogue_preview_format: String = "Tuo %s kiinnostaisi..."
## Said at the counter before the sale when nothing suits this customer.
@export_multiline var dialogue_nothing_available: String = "Eipä taida olla mitään sopivaa..."

## Hard gates, not preferences: a batch outside them is invisible to this customer.
@export_group("Tiukat vaatimukset")
## -1 = no limit. E.g. 5.0 rejects anything under 5% ABV (see Barbaari).
@export var min_required_abv: float = -1.0
## -1 = no limit. E.g. 0.5 accepts only alcohol-free beer (see Zgen).
@export var max_required_abv: float = -1.0
## -1 = no limit. Hides styles priced above this (Opiskelija, a broke student).
@export var max_required_price: float = -1.0
## Empty = no limit. Otherwise only these styles are visible (the German tourists take any
## lager). Broader than requires_preference_match.
@export var accepted_styles: Array[BeerStyle.Style] = []

@export_group("Tippaus")
## Chance of a tip before quality and taste, like a crit chance (SaleEvaluation.tip_chance()).
@export var tip_base_chance: float = SaleEvaluation.DEFAULT_TIP_BASE_CHANCE
## Tip per quality point above min_quality, scaled by budget_multiplier; 0 or below never
## tips (Opiskelija).
@export var quality_tip_sensitivity: float = 0.3

@export_group("Reputation Changes")
@export var rep_bad_quality: int = -3
@export var rep_primary_style: int = 5
@export var rep_secondary_style: int = 0
@export var rep_wrong_style: int = -1
## Reputation per quality point above min_quality, and a penalty per point below.
@export var quality_reputation_sensitivity: float = 4.0

@export_group("Risk Changes")
@export var risk_bad_quality: int = 1
@export var risk_primary_style: int = 3
@export var risk_secondary_style: int = 1
@export var risk_wrong_style: int = 2
## Risk cut per quality point above min_quality, and extra risk below.
@export var quality_risk_sensitivity: float = 2.0

@export_group("Saatavuus")
@export var min_reputation_to_appear: int = 0
## -1 = no limit. Needs this style brewed in any past run, on top of
## min_reputation_to_appear, so a style with no other pull gets brewed once.
@export var required_discovered_style: int = -1
## Empty = no limit. Needs this achievement, permanent like required_discovered_style.
@export var required_achievement_id: String = ""
## Odds against the other customers, 1.0 for the usual; 0 keeps them away. In busy_season
## busy_season_weight replaces it: Tarjoushaukka comes all year and more in Black Month,
## Kyborgi only in Cyber Week.
@export var appearance_weight: float = 1.0
@export var busy_season: SeasonRules.Season = SeasonRules.Season.NONE
@export var busy_season_weight: float = 1.0

@export_group("Erikoiskäytös")
@export var randomizes_preference: bool = false
## No taste of their own: picks random batches that clear min_quality, and every style
## counts as the favourite (see Perusasiakas). See BatchChoice.pick_batches().
@export var picks_at_random: bool = false
## With picks_at_random: buys 1 to this many styles a visit, min/max_bottles_per_visit of
## each.
@export var max_styles_per_visit: int = 1
@export var primary_match_risk_multiplier: float = 1.0
## A batch matching neither primary nor secondary style is invisible (Agentti only wants
## today's cover-story styles).
@export var requires_preference_match: bool = false
## Overrides CustomerManager.NO_MATCH_* for leaving with dialogue_no_match. Agentti zeroes
## them: nothing was offered to him.
@export var no_match_reputation_penalty: int = CustomerManager.NO_MATCH_REPUTATION_PENALTY
@export var no_match_risk_penalty: int = CustomerManager.NO_MATCH_RISK_PENALTY
## Only looks around and leaves: no sale, penalty or unhappy customer (the LVV inspector's
## warning visit).
@export var browses_only: bool = false
@export var min_bottles_per_visit: int = 1
@export var max_bottles_per_visit: int = 1
## What can start this customer's bar fight (BarFightRules): any sale, not getting all the
## beer wanted, or buying at least bar_fight_min_bottles_bought.
@export var bar_fight_trigger: BarFightTrigger = BarFightTrigger.RANDOM
## For RANDOM, the chance per sale; otherwise the chance once the trigger is met.
@export var bar_fight_chance: float = 0.0
@export var bar_fight_min_bottles_bought: int = 0
@export var bar_fight_reputation_penalty: int = 0
@export var bar_fight_risk_penalty: int = 0
@export var bar_fight_max_bottles_broken: int = 0
## Narration shown as a toast, not a spoken line. One %d for the broken bottles.
@export_multiline var dialogue_bar_fight: String = ""
## Set for a customer who minds the Reinheitsgebot: a batch whose spices broke it gets this
## line, rep_purity_law_broken and no tip. Empty = does not care.
@export_multiline var dialogue_purity_law_broken: String = ""
@export var rep_purity_law_broken: int = -3


func generate_display_name() -> String:
	if title == "" or first_names.is_empty():
		return tr(DEFAULT_TITLE) + " " + DEFAULT_NAMES.pick_random()
	return tr(title) + " " + first_names.pick_random()


## An accepted style that is not a favourite counts as second choice, so an accepted_styles
## customer never calls one the wrong style.
func get_preference_score(style: BeerStyle.Style) -> float:
	if picks_at_random or style == primary_style:
		return 1.0
	elif style == secondary_style or also_likes.has(style) or accepted_styles.has(style):
		return 0.5
	return 0.0


func get_appearance_weight(season : SeasonRules.Season) -> float:
	if busy_season != SeasonRules.Season.NONE and SeasonRules.includes(season, busy_season):
		return busy_season_weight
	return appearance_weight


## False for a seasonal customer out of season: never picked, announced or walked in.
func comes_in(season : SeasonRules.Season) -> bool:
	return get_appearance_weight(season) > 0.0


func uses_taste_tiers() -> bool:
	return not favourite_rules.is_empty()


## Like get_preference_score() for one batch, so taste tiers can look at its spices, hops
## and strength. NOT_TO_TASTE when no tier takes it.
func get_batch_preference(batch : BrewBatch) -> float:
	if not uses_taste_tiers():
		return get_preference_score(batch.beer_style.style)
	if TasteRule.any_matches(favourite_rules, batch):
		return 0.5 if rolls_favourite and batch.beer_style.style != primary_style else 1.0
	if TasteRule.any_matches(second_rules, batch):
		return 0.5
	if TasteRule.any_matches(last_resort_rules, batch):
		return 0.0
	return NOT_TO_TASTE


## The strict gates plus the taste tiers: a batch outside every tier is never considered.
func accepts_batch(batch : BrewBatch) -> bool:
	return meets_strict_requirements(batch.beer_style, batch.get_abv()) and get_batch_preference(batch) > NOT_TO_TASTE


## Rolls this visit's favourite from favourite_rules' discovered styles (`discovered`, any
## season), or from all of them before any is found.
func roll_favourite(discovered : Array) -> void:
	if not rolls_favourite:
		return
	var pool : Array[BeerStyle.Style] = []
	for rule : TasteRule in favourite_rules:
		for style : BeerStyle.Style in rule.styles:
			if not pool.has(style):
				pool.append(style)
	var found : Array[BeerStyle.Style] = []
	found.assign(pool.filter(func(style : BeerStyle.Style) -> bool: return discovered.has(style)))
	if not found.is_empty():
		pool = found
	if not pool.is_empty():
		primary_style = pool.pick_random()


## False when the batch fails a hard gate. `abv` is the batch's own; negative uses the
## style's.
func meets_strict_requirements(beer_style: BeerStyle, abv: float = -1.0) -> bool:
	if abv < 0.0:
		abv = beer_style.abv
	if min_required_abv >= 0.0 and abv < min_required_abv:
		return false
	if max_required_abv >= 0.0 and abv > max_required_abv:
		return false
	if max_required_price >= 0.0 and beer_style.fixed_price_per_bottle > max_required_price:
		return false
	if not accepted_styles.is_empty() and not accepted_styles.has(beer_style.style):
		return false
	if requires_preference_match and get_preference_score(beer_style.style) < 0.5:
		return false
	return true


## `styles` is the pool to draw from (the run's styles), passed in for tests.
func reroll_preference(styles : Array[BeerStyle]) -> void:
	if not randomizes_preference:
		return

	if styles.size() < 2:
		return

	var shuffled_styles := styles.duplicate()
	shuffled_styles.shuffle()

	primary_style = shuffled_styles[0].style
	secondary_style = shuffled_styles[1].style


func minds_purity_law(batch: BrewBatch) -> bool:
	return not dialogue_purity_law_broken.is_empty() and batch.spice_bonus < 0.0


## See SaleEvaluation; `style_base_price` is passed in, so no autoload is needed.
## `tip_chance_bonus` is the perks' PerkStats.TIP_CHANCE.
func evaluate_brew_batch(batch: BrewBatch, style_base_price: float = 3.0, tip_roll: float = randf(), tip_chance_bonus: float = 0.0) -> Dictionary:
	return SaleEvaluation.evaluate(self, batch, style_base_price, tip_roll, tip_chance_bonus)
