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
	IMPERIAL_STOUT
}

@export var style_name: String = "Uusi oluttyyli"
@export var style: Style = Style.KOTIKALJA

@export_group("Vaatimukset")
@export var required_yeast_id: int = 301 # Esim. 301=Lager, 302=Ale
@export var min_malt_weight: int = 3
@export var preferred_hop_profile: HopData.FlavorProfile = HopData.FlavorProfile.NONE

@export_group("EBC (Väri) Rajat")
@export var min_ebc: int = 0
@export var max_ebc: int = 999

@export_group("IBU (Katkeruus) Rajat")
@export var min_ibu: int = 0
@export var max_ibu: int = 999

@export_group("Palkkiot & Riskit")
@export var original_quality: float = 1.0
@export var reputation_change: int = 2

@export_group("Kellarointi & Kypsytys")
@export var peak_days: int = 0 
@export var shelf_life_days: int = 14 
@export var aging_factor: float = 0.05 


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
		_: return StringContainer.TUNTEMATON
