class_name BeerStyle
extends Resource

const ANY_YEAST : int = -1
## match_priority() runs from ANY_RECIPE_PRIORITY (checked first) to LAST_PRIORITY.
const ANY_RECIPE_PRIORITY : int = -1
const LAST_PRIORITY : int = 2


enum Style {
	KOTIKALJA,
	BULKKILAGER,
	TUMMA_LAGER,
	PALE_ALE,
	AMBER_ALE,
	IPA,
	HELLES,
	VIENNA_LAGER,
	MARZEN,
	BALTIC_PORTTERI,
	DOPPELBOCK,
	HEFEWEIZEN,
	WITBIER,
	SESSION_ALE,
	SAISON,
	BELGIAN_DUBBEL,
	BELGIAN_STRONG_DARK,
	SCOTCH_ALE,
	BARLEYWINE,
	IMPERIAL_STOUT,
	ALKOHOLITON_IPA,
	ALKOHOLITON_LAGER,
	SAHTI,
	MAITOSTOUT,
	RAUCHBIER,
	ROGGENBIER,
	IRISH_DRY_STOUT,
	PILSNER,
	CZECH_PILSNER,
	KURPITSAOLUT,
	TEKOALYOLUT,
	LAKKASELTZERI,
}

@export var style_name: String = "Uusi oluttyyli"
@export var style: Style = Style.KOTIKALJA
## A few sentences for the recipe book; empty shows nothing.
@export_multiline var description: String = ""
## What the recipe book says of the style before it is discovered, without its name.
@export_multiline var locked_hint: String = ""
## Known in every new run with its default recipe in the book, like Kotikalja, so a
## seasonal style can be loaded without brewing it first.
@export var known_from_start: bool = false
## Known in a new run started in this season (Tekoälyolut in Cyber Week); NONE for never.
@export var known_in_season: SeasonRules.Season = SeasonRules.Season.NONE

@export_group("Vaatimukset")
## ANY_YEAST lets every yeast brew the style (Tekoälyolut takes any recipe).
@export var required_yeast_id: int = 301 # 301 = lager, 302 = ale
@export var min_malt_weight: int = 3
## -1 = any malt. Set where one malt defines the style (wheat in Hefeweizen and Witbier).
@export var required_malt_id: int = -1
## Spices that must all be on the table (juniper in Sahti); any of them is the style's
## flavour match.
@export var required_spice_ids: Array[int] = []
## Optional spices that each add BrewQuality.SPICE_MATCH_STEP when on the table.
@export var preferred_spice_ids: Array[int] = []
## German styles keep the Reinheitsgebot: any spice costs BrewQuality.PURITY_LAW_PENALTY.
@export var forbids_spices: bool = false
## These malts together make at least min_base_share of the grist (Märzen is mostly
## Münchenin). Empty = any grist.
@export var base_malt_ids: Array[int] = []
@export_range(0.0, 1.0, 0.05) var min_base_share: float = 0.0
## The malts beyond the base that give the style its character (Münchenin in a Helles,
## Carafa in a Dunkel): each in the grist adds BrewQuality.MALT_MATCH_STEP.
@export var preferred_malt_ids: Array[int] = []
## Late hops with any of these profiles earn the flavour bonus, see BrewQuality.
@export var preferred_hop_profiles: Array[HopData.FlavorProfile] = []
## Hop-forward ales: with only bittering hops (Magnum) there is no aroma, so the beer is
## not this style.
@export var requires_aroma_hop: bool = false
## When set, these are the only hops allowed and at least one must be in (a Czech pils
## is all Saaz); any other hop makes the batch some other style.
@export var only_hop_ids: Array[int] = []

@export_group("Alkoholi")
## The style's typical strength, for the book and events. A batch's real ABV comes from
## its grist (BrewBatch.abv), and must land inside min_abv-max_abv.
@export var abv: float = 5.0
@export var min_abv: float = 0.0
@export var max_abv: float = 99.0

@export_group("Resepti")
## The style's reference recipe (id -> amount): it seeds the default recipe and sets the
## cost price, and a test checks it brews this style.
@export var reference_recipe: Dictionary[int, int] = {}

## At or under this ABV a style is alcohol-free: the LVV has no interest in it.
const ALCOHOL_FREE_MAX_ABV: float = 0.5


func is_alcohol_free() -> bool:
	return abv <= ALCOHOL_FREE_MAX_ABV


## Checked in this order: styles defined by a required ingredient first, then those
## defined by their base malts, then the rest, so the most specific style wins.
## Lower is checked first. A style any yeast can brew (Tekoälyolut) goes before all, or a
## style with its own required ingredient would take the brews meant for it.
func match_priority() -> int:
	if required_yeast_id == ANY_YEAST:
		return ANY_RECIPE_PRIORITY
	if required_malt_id != BrewMixture.NO_REQUIRED_MALT or not required_spice_ids.is_empty() or not only_hop_ids.is_empty():
		return 0
	return 1 if not base_malt_ids.is_empty() else LAST_PRIORITY


func has_preferred_hop_profile(profile : HopData.FlavorProfile) -> bool:
	return profile != HopData.FlavorProfile.NONE and preferred_hop_profiles.has(profile)

@export_group("Talous")
## Scales the markup, so laborious styles earn more. Ignored with fixed_price_per_bottle.
@export var profit_margin_multiplier: float = 1.0
## Over 0, the hand-set list price instead of cost plus margin (StylePricing).
@export var fixed_price_per_bottle: float = 0.0

@export_group("EBC (Väri) Rajat")
@export var min_ebc: int = 0
@export var max_ebc: int = 999

@export_group("IBU (Katkeruus) Rajat")
@export var min_ibu: int = 0
@export var max_ibu: int = 999

@export_group("Laatu")
## 0 to 1 stands in for the colour, bitterness and strength precision, so a style with
## near-open windows (Tekoälyolut) is no worse at the edges; negative scores them as usual.
@export_range(-1.0, 1.0, 0.05) var fixed_precision: float = -1.0

@export_group("Palkkiot & Riskit")
@export var original_quality: float = 1.0
@export var reputation_change: int = 2

## The "_days" fields count aging ticks (AGING_TICK_SECONDS), not days; renaming them
## would touch every style .tres.
@export_group("Kellarointi & Kypsytys")
@export var peak_days: int = 0
@export var shelf_life_days: int = 14
@export var aging_factor: float = 0.05
## Extra share of the price at the aged peak, so a cellar beer pays most after aging.
## 0 = never.
@export var aged_price_bonus: float = 0.0

@export_group("Keittopäivä")
## Mash step temperatures in °C, in order; one step is a single infusion.
@export var mash_steps: Array[int] = [65]
## How far from a step's temperature the mash still counts as right, in °C.
@export var mash_band: float = 2.0
## The boil's hop additions (HopAddition); spices get their own mark when the recipe has
## any.
@export var hop_additions: Array[HopAddition.Kind] = [HopAddition.Kind.BITTERING]


## A coarse colour word for locked styles in the recipe book, from the EBC midpoint, so
## the exact window stays hidden until discovery.
static func get_color_hint(ebc_low : int, ebc_high : int) -> String:
	var midpoint : float = (ebc_low + ebc_high) / 2.0
	if midpoint < 8.0: return StringContainer.COLOR_HINT_PALE
	if midpoint < 16.0: return StringContainer.COLOR_HINT_GOLDEN
	if midpoint < 30.0: return StringContainer.COLOR_HINT_AMBER
	if midpoint < 70.0: return StringContainer.COLOR_HINT_BROWN
	return StringContainer.COLOR_HINT_BLACK


## Like get_color_hint(), from the IBU midpoint.
static func get_bitterness_hint(ibu_low : int, ibu_high : int) -> String:
	var midpoint : float = (ibu_low + ibu_high) / 2.0
	if midpoint < 15.0: return StringContainer.BITTERNESS_HINT_MILD
	if midpoint < 30.0: return StringContainer.BITTERNESS_HINT_BALANCED
	if midpoint < 50.0: return StringContainer.BITTERNESS_HINT_BITTER
	return UiText.of(StringContainer.BITTERNESS_HINT_VERY_BITTER)


func get_style_string() -> String:
	return get_style_string_from_style(style)


static func get_style_string_from_style(new_style : BeerStyle.Style) -> String:
	match new_style:
		Style.KOTIKALJA: return UiText.of(StringContainer.KOTIKALJA)
		Style.BULKKILAGER: return UiText.of(StringContainer.BULKKILAGER)
		Style.TUMMA_LAGER: return UiText.of(StringContainer.TUMMALAGER)
		Style.PALE_ALE: return UiText.of(StringContainer.PALEALE)
		Style.AMBER_ALE: return UiText.of(StringContainer.AMBERALE)
		Style.IPA: return UiText.of(StringContainer.IPA)
		Style.HELLES: return UiText.of(StringContainer.HELLES)
		Style.VIENNA_LAGER: return UiText.of(StringContainer.VIENNALAGER)
		Style.MARZEN: return UiText.of(StringContainer.MARZEN)
		Style.BALTIC_PORTTERI: return UiText.of(StringContainer.BALTICPORTTERI)
		Style.DOPPELBOCK: return UiText.of(StringContainer.DOPPELBOCK)
		Style.HEFEWEIZEN: return UiText.of(StringContainer.HEFEWEIZEN)
		Style.WITBIER: return UiText.of(StringContainer.WITBIER)
		Style.SESSION_ALE: return UiText.of(StringContainer.SESSIONALE)
		Style.SAISON: return UiText.of(StringContainer.SAISON)
		Style.BELGIAN_DUBBEL: return UiText.of(StringContainer.BELGIANDUBBEL)
		Style.BELGIAN_STRONG_DARK: return UiText.of(StringContainer.BELGIANSTRONGDARK)
		Style.SCOTCH_ALE: return UiText.of(StringContainer.SCOTCHALE)
		Style.BARLEYWINE: return UiText.of(StringContainer.BARLEYWINE)
		Style.IMPERIAL_STOUT: return UiText.of(StringContainer.IMPERIALSTOUT)
		Style.ALKOHOLITON_IPA: return UiText.of(StringContainer.ALKOHOLITONIPA)
		Style.ALKOHOLITON_LAGER: return UiText.of(StringContainer.ALKOHOLITONLAGER)
		Style.SAHTI: return UiText.of(StringContainer.SAHTI)
		Style.MAITOSTOUT: return UiText.of(StringContainer.MAITOSTOUT)
		Style.RAUCHBIER: return UiText.of(StringContainer.RAUCHBIER)
		Style.ROGGENBIER: return UiText.of(StringContainer.ROGGENBIER)
		Style.IRISH_DRY_STOUT: return UiText.of(StringContainer.IRISH_DRY_STOUT)
		Style.PILSNER: return UiText.of(StringContainer.PILSNER)
		Style.CZECH_PILSNER: return UiText.of(StringContainer.CZECH_PILSNER)
		Style.KURPITSAOLUT: return UiText.of(StringContainer.KURPITSAOLUT)
		Style.TEKOALYOLUT: return UiText.of(StringContainer.TEKOALYOLUT)
		Style.LAKKASELTZERI: return UiText.of(StringContainer.LAKKASELTZERI)
		_: return UiText.of(StringContainer.TUNTEMATON)
