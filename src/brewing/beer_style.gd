class_name BeerStyle
extends Resource


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
}

@export var style_name: String = "Uusi oluttyyli"
@export var style: Style = Style.KOTIKALJA
## A few sentences for the recipe book; empty shows nothing.
@export_multiline var description: String = ""
## What the recipe book says of the style before it is discovered, without its name.
@export_multiline var locked_hint: String = ""

@export_group("Vaatimukset")
@export var required_yeast_id: int = 301 # Esim. 301=Lager, 302=Ale
@export var min_malt_weight: int = 3
## -1 = no specific malt; the style matches on EBC/IBU/yeast/weight alone. Set where a
## real recipe is defined by one malt (Hefeweizen and Witbier need wheat malt). See
## BrewMixture.fits().
@export var required_malt_id: int = -1
## Spices that must all be on the table, like required_malt_id (Sahti needs juniper,
## Witbier coriander and orange peel). Any of them counts as the style's flavour match
## in BrewQuality.
@export var required_spice_ids: Array[int] = []
## Optional spices that each add BrewQuality.SPICE_MATCH_STEP when on the table.
@export var preferred_spice_ids: Array[int] = []
## German styles keep the Reinheitsgebot: any spice costs BrewQuality.PURITY_LAW_PENALTY.
@export var forbids_spices: bool = false
## The grist's backbone: these malts together make at least min_base_share of the malt
## weight (Märzen is mostly Münchenin, Hefeweizen mostly wheat). Empty = any grist.
@export var base_malt_ids: Array[int] = []
@export_range(0.0, 1.0, 0.05) var min_base_share: float = 0.0
## The malts beyond the base that give the style its character (Münchenin in a Helles,
## Carafa in a Dunkel): each in the grist adds BrewQuality.MALT_MATCH_STEP.
@export var preferred_malt_ids: Array[int] = []
## Late hops with any of these profiles earn the flavour bonus, see BrewQuality.
@export var preferred_hop_profiles: Array[HopData.FlavorProfile] = []
## Hop-forward ales: brewed with only bittering hops (no flavour profile, like
## Magnum) the beer is not this style, since it has no hop aroma at all.
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
func match_priority() -> int:
	if required_malt_id != BrewMixture.NO_REQUIRED_MALT or not required_spice_ids.is_empty() or not only_hop_ids.is_empty():
		return 0
	return 1 if not base_malt_ids.is_empty() else 2


func has_preferred_hop_profile(profile : HopData.FlavorProfile) -> bool:
	return profile != HopData.FlavorProfile.NONE and preferred_hop_profiles.has(profile)

@export_group("Talous")
## Scales StylePricing.PROFIT_MARKUP_RATE, so laborious styles (IPA, Imperial Stout,
## Barleywine) earn more per bottle. Ignored when fixed_price_per_bottle is set.
@export var profit_margin_multiplier: float = 1.0
## If > 0, replaces the cost-plus-margin formula as the hand-balanced list price; profit
## is then price minus cost. 0 = use the formula (see StylePricing.price_breakdown).
@export var fixed_price_per_bottle: float = 0.0

@export_group("EBC (Väri) Rajat")
@export var min_ebc: int = 0
@export var max_ebc: int = 999

@export_group("IBU (Katkeruus) Rajat")
@export var min_ibu: int = 0
@export var max_ibu: int = 999

@export_group("Palkkiot & Riskit")
@export var original_quality: float = 1.0
@export var reputation_change: int = 2

## Despite "_days", these count TimeManager aging ticks (AGING_TICK_SECONDS of real
## time), so aging runs continuously; the name stayed to spare every style .tres.
@export_group("Kellarointi & Kypsytys")
@export var peak_days: int = 0
@export var shelf_life_days: int = 14
@export var aging_factor: float = 0.05
## Extra share of the price a batch earns once aged to its peak, growing with age, so
## an expensive cellar beer (Imperial Stout) pays most after long aging. 0 = never.
@export var aged_price_bonus: float = 0.0

@export_group("Keittopäivä")
## Mash step temperatures in °C, in order; one step is a single infusion.
@export var mash_steps: Array[int] = [65]
## How far from a step's temperature the mash still counts as right, in °C.
@export var mash_band: float = 2.0
## The hop additions of the boil, see HopAddition. Spices get their own mark whenever
## the recipe has any, so they are not listed here.
@export var hop_additions: Array[HopAddition.Kind] = [HopAddition.Kind.BITTERING]


## Coarse, bucketed color hint for RecipeLibraryWindow's locked-style rows
## — bucketed on the style's own EBC midpoint so a player gets a real
## signal ("vaalea"/"tumma"/...) without the exact min_ebc/max_ebc numbers
## the brewing puzzle is meant to withhold until discovery.
static func get_color_hint(ebc_low : int, ebc_high : int) -> String:
	var midpoint : float = (ebc_low + ebc_high) / 2.0
	if midpoint < 8.0: return StringContainer.COLOR_HINT_PALE
	if midpoint < 16.0: return StringContainer.COLOR_HINT_GOLDEN
	if midpoint < 30.0: return StringContainer.COLOR_HINT_AMBER
	if midpoint < 70.0: return StringContainer.COLOR_HINT_BROWN
	return StringContainer.COLOR_HINT_BLACK


## Same idea as get_color_hint(), bucketed on IBU midpoint instead.
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
		_: return UiText.of(StringContainer.TUNTEMATON)
