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
	ALKOHOLITON_LAGER
}

@export var style_name: String = "Uusi oluttyyli"
@export var style: Style = Style.KOTIKALJA

@export_group("Vaatimukset")
@export var required_yeast_id: int = 301 # Esim. 301=Lager, 302=Ale
@export var min_malt_weight: int = 3
## -1 = no specific malt required (matches purely on EBC/IBU/yeast/weight,
## the original behavior). Set on styles where a real-world recipe is
## defined by one specific malt, not just by the resulting color/bitterness
## it happens to produce — e.g. Hefeweizen/Witbier genuinely require wheat
## malt; brewing the right EBC/IBU with plain pale-ale malt and calling it
## a wheat beer isn't a real recipe, just a numeric coincidence. See
## BrewResolver.resolve_brew_style()'s malt_ids_used check.
@export var required_malt_id: int = -1
@export var preferred_hop_profile: HopData.FlavorProfile = HopData.FlavorProfile.NONE

@export_group("Alkoholi")
## Prosentteina, esim. 5.2 = 5.2 %. Kiinteä tyylikohtainen arvo, näytetään
## pulloissa/kuiteissa — ei enää vaikuta hintaan (ks.
## StylePricing.calculate_price_breakdown, jossa ei ole valmisteveroa).
@export var abv: float = 5.0

@export_group("Talous")
## Kerroin StylePricing.PROFIT_MARKUP_RATE:lle — monimutkaisemmat,
## työläämmät tyylit (IPA, Imperial Stout, Barleywine...) kannattavat
## enemmän per pullo kuin perusoluet. 1.0 = ei muutosta. Ei vaikuta jos
## fixed_price_per_bottle on asetettu.
@export var profit_margin_multiplier: float = 1.0
## Jos > 0, ohittaa raw_cost+kate-kaavan kokonaan ja tätä käytetään
## suoraan pullon listahintana (käsin tasapainotettu arvo). "Kate"
## lasketaan silloin suoraan tästä miinus raaka-ainekulut, ei toisin
## päin. 0 = käytä normaalia kaavaa (ks. BrewResolver.get_price_breakdown).
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

## Despite the "_days" naming (kept to avoid a mass rename across every
## beer style .tres file), these count TimeManager aging ticks, not
## calendar days — see TimeManager.AGING_TICK_SECONDS and _on_aging_tick().
## One tick is a fixed real-time interval, independent of in-game day
## length, so cellar aging progresses continuously instead of jumping once
## per day close.
@export_group("Kellarointi & Kypsytys")
@export var peak_days: int = 0
@export var shelf_life_days: int = 14
@export var aging_factor: float = 0.05


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
	return StringContainer.BITTERNESS_HINT_VERY_BITTER


func get_style_string() -> String:
	return get_style_string_from_style(style)


static func get_style_string_from_style(new_style : BeerStyle.Style) -> String:
	match new_style:
		Style.KOTIKALJA: return StringContainer.KOTIKALJA
		Style.BULKKILAGER: return StringContainer.BULKKILAGER
		Style.TUMMA_LAGER: return StringContainer.TUMMALAGER
		Style.PALE_ALE: return StringContainer.PALEALE
		Style.AMBER_ALE: return StringContainer.AMBERALE
		Style.IPA: return StringContainer.IPA
		Style.HELLES: return StringContainer.HELLES
		Style.VIENNA_LAGER: return StringContainer.VIENNALAGER
		Style.MARZEN: return StringContainer.MARZEN
		Style.BALTIC_PORTTERI: return StringContainer.BALTICPORTTERI
		Style.DOPPELBOCK: return StringContainer.DOPPELBOCK
		Style.HEFEWEIZEN: return StringContainer.HEFEWEIZEN
		Style.WITBIER: return StringContainer.WITBIER
		Style.SESSION_ALE: return StringContainer.SESSIONALE
		Style.SAISON: return StringContainer.SAISON
		Style.BELGIAN_DUBBEL: return StringContainer.BELGIANDUBBEL
		Style.BELGIAN_STRONG_DARK: return StringContainer.BELGIANSTRONGDARK
		Style.SCOTCH_ALE: return StringContainer.SCOTCHALE
		Style.BARLEYWINE: return StringContainer.BARLEYWINE
		Style.IMPERIAL_STOUT: return StringContainer.IMPERIALSTOUT
		Style.ALKOHOLITON_IPA: return StringContainer.ALKOHOLITONIPA
		Style.ALKOHOLITON_LAGER: return StringContainer.ALKOHOLITONLAGER
		_: return StringContainer.TUNTEMATON
