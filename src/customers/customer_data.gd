class_name CustomerData
extends Resource


enum BarFightTrigger { RANDOM, NOT_ENOUGH_BEER, BOUGHT_MANY }

const DEFAULT_TITLE: String = "Asiakas"
const DEFAULT_NAMES: Array[String] = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]

@export_group("Customer Profile")
@export var customer_name: String = "Anonyymi"
@export var title: String = ""
@export var first_names: Array[String] = []
@export var min_quality: float = 0.5
## Tip generosity only: every customer pays the same fixed price for a style.
## See quality_tip_sensitivity.
@export var budget_multiplier: float = 1.0
@export var primary_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var secondary_style: BeerStyle.Style = BeerStyle.Style.KOTIKALJA
## Further styles liked as much as secondary_style. Unlike accepted_styles, every other
## style stays on the menu (the metalheads also like Baltic Porter).
@export var also_likes: Array[BeerStyle.Style] = []

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
## False for customers who stow the beer inside themselves (Lähettirobotti):
## the counter glass just vanishes when they leave.
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
## Shown when this customer leaves without buying: nothing in stock, or nothing that
## clears a strict requirement.
@export_multiline var dialogue_no_match: String = "Ei täällä ollu mitään minulle. Ehkä ensi kerralla."
## Said at the counter before the sale, naming the batch this customer will pick (%s is
## the style name).
@export_multiline var dialogue_preview_format: String = "Tuo %s kiinnostaisi..."
## Said at the counter before the sale when nothing suits this customer.
@export_multiline var dialogue_nothing_available: String = "Eipä taida olla mitään sopivaa..."

## A hard gate, not a preference. A batch outside a set bound is invisible to this
## customer however good it is, see SaleProcessor.find_best_batch().
@export_group("Tiukat vaatimukset")
## -1 = no limit. E.g. 5.0 rejects anything under 5% ABV (see Barbaari).
@export var min_required_abv: float = -1.0
## -1 = no limit. E.g. 0.5 accepts only alcohol-free beer (see Zgen).
@export var max_required_abv: float = -1.0
## -1 = no limit. Rejects styles with a fixed price above this (see Opiskelija, a broke
## student who leaves if everything in stock is over budget).
@export var max_required_price: float = -1.0
## Empty = no limit. Otherwise only these styles are visible to this customer (see the
## German tourists, who take any lager). Broader than requires_preference_match.
@export var accepted_styles: Array[BeerStyle.Style] = []

@export_group("Tippaus")
## Tip per quality point above min_quality, scaled by budget_multiplier. Zero or below
## means this customer never tips (see Opiskelija).
@export var quality_tip_sensitivity: float = 0.3

@export_group("Reputation Changes")
@export var rep_bad_quality: int = -3
@export var rep_primary_style: int = 5
@export var rep_secondary_style: int = 0
@export var rep_wrong_style: int = -1
## Reputation per quality point above min_quality, and a penalty per point below it.
## A connoisseur can be given a higher value.
@export var quality_reputation_sensitivity: float = 4.0

@export_group("Risk Changes")
@export var risk_bad_quality: int = 1
@export var risk_primary_style: int = 3
@export var risk_secondary_style: int = 1
@export var risk_wrong_style: int = 2
## Risk reduction per quality point above min_quality, and extra risk below it. Scaled
## separately from reputation.
@export var quality_risk_sensitivity: float = 2.0

@export_group("Saatavuus")
@export var min_reputation_to_appear: int = 0
## -1 = no limit. Requires having brewed this style in ANY past run (see
## MetaProgressManager.has_style()), on top of min_reputation_to_appear. Gives a style with
## no other pull a reason to be brewed once.
@export var required_discovered_style: int = -1
## Empty = no limit. Requires AchievementManager.is_unlocked() for this id, permanent
## across runs like required_discovered_style (see Lähettirobotti).
@export var required_achievement_id: String = ""

@export_group("Erikoiskäytös")
@export var randomizes_preference: bool = false
@export var primary_match_risk_multiplier: float = 1.0
## Like the strict ABV gate, but preference-based: a batch matching neither the primary
## nor the secondary style is invisible to this customer (see Agentti, an undercover
## inspector who only wants today's cover-story styles).
@export var requires_preference_match: bool = false
## Per-customer override of CustomerManager.NO_MATCH_* for leaving via
## dialogue_no_match. Agentti zeroes them, since nothing was ever offered to him.
@export var no_match_reputation_penalty: int = CustomerManager.NO_MATCH_REPUTATION_PENALTY
@export var no_match_risk_penalty: int = CustomerManager.NO_MATCH_RISK_PENALTY
## Only looks around: says dialogue_intro, then dialogue_nothing_available instead of a
## preview, and leaves with dialogue_no_match. No sale, penalty or unhappy customer
## (the LVV inspector's warning visit, see Brewery.LVV_INSPECTOR_VISIT_RISK).
@export var browses_only: bool = false
@export var min_bottles_per_visit: int = 1
@export var max_bottles_per_visit: int = 1
## What can start this customer's bar fight (see BarFightRules): any sale, not getting
## all the beer they came for, or buying at least bar_fight_min_bottles_bought.
@export var bar_fight_trigger: BarFightTrigger = BarFightTrigger.RANDOM
## For RANDOM, the chance per sale; otherwise the chance once the trigger is met.
@export var bar_fight_chance: float = 0.0
@export var bar_fight_min_bottles_bought: int = 0
@export var bar_fight_reputation_penalty: int = 0
@export var bar_fight_risk_penalty: int = 0
@export var bar_fight_max_bottles_broken: int = 0
## Incident narration, not something the customer says: shown as its own toast via
## BrewerySignals.bar_fight_triggered. Must contain one %d for the broken-bottle count.
@export_multiline var dialogue_bar_fight: String = ""
## A customer with this line minds the Reinheitsgebot: a batch whose spices broke it
## (BrewBatch.spice_bonus < 0) gets this line, rep_purity_law_broken and no tip,
## whatever its style or quality. Empty means the customer does not care.
@export_multiline var dialogue_purity_law_broken: String = ""
@export var rep_purity_law_broken: int = -3


func generate_display_name() -> String:
	if title == "" or first_names.is_empty():
		return tr(DEFAULT_TITLE) + " " + DEFAULT_NAMES.pick_random()
	return tr(title) + " " + first_names.pick_random()


## An accepted style that is not a favourite scores like the secondary one: a customer
## who only ever buys from accepted_styles should not call any of them the wrong style.
func get_preference_score(style: BeerStyle.Style) -> float:
	if style == primary_style:
		return 1.0
	elif style == secondary_style or also_likes.has(style) or accepted_styles.has(style):
		return 0.5
	return 0.0


## False when the batch fails a hard gate; such a batch is never considered, whatever
## its quality.
func meets_strict_requirements(beer_style: BeerStyle) -> bool:
	if min_required_abv >= 0.0 and beer_style.abv < min_required_abv:
		return false
	if max_required_abv >= 0.0 and beer_style.abv > max_required_abv:
		return false
	if max_required_price >= 0.0 and beer_style.fixed_price_per_bottle > max_required_price:
		return false
	if not accepted_styles.is_empty() and not accepted_styles.has(beer_style.style):
		return false
	if requires_preference_match and get_preference_score(beer_style.style) < 0.5:
		return false
	return true


## `styles` is the pool to draw from (the current run's active styles), passed
## in so this stays pure and unit-testable without any autoload.
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


## See SaleEvaluation. The caller passes `style_base_price`, so no autoload is needed.
func evaluate_brew_batch(batch: BrewBatch, style_base_price: float = 3.0) -> Dictionary:
	return SaleEvaluation.evaluate(self, batch, style_base_price)
