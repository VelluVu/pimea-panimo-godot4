class_name BeerStyle
extends Resource


enum Style {
	KOTIKALJA,
	BULKKILAGER,
	TUMMA_LAGER,
	VAALEA_ALE,
	AMBER_ALE,
	IPA
}

@export var style_name: String = "Uusi oluttyyli"
@export var style: Style = Style.KOTIKALJA

@export_group("Vaatimukset")
@export var required_yeast_id: int = 301 # Esim. 301=Lager, 302=Ale
@export var min_malt_weight: int = 3

@export_group("EBC (Väri) Rajat")
@export var min_ebc: int = 0
@export var max_ebc: int = 999

@export_group("IBU (Katkeruus) Rajat")
@export var min_ibu: int = 0
@export var max_ibu: int = 999

@export_group("Palkkiot & Riskit")
@export var quality_multiplier: float = 1.0
@export var risk_change: int = 5
@export var reputation_change: int = 2


func get_style_string() -> String:
	match style:
		Style.KOTIKALJA: return StringContainer.KOTIKALJA
		Style.BULKKILAGER: return StringContainer.BULKKILAGER
		Style.TUMMA_LAGER: return StringContainer.TUMMALAGER
		Style.VAALEA_ALE: return StringContainer.VAALEAALE
		Style.AMBER_ALE: return StringContainer.AMBERALE
		Style.IPA: return StringContainer.IPA
		_: return StringContainer.TUNTEMATON


static func get_style_string_from_style(new_style : BeerStyle.Style) -> String:
	match new_style:
		Style.KOTIKALJA: return StringContainer.KOTIKALJA
		Style.BULKKILAGER: return StringContainer.BULKKILAGER
		Style.TUMMA_LAGER: return StringContainer.TUMMALAGER
		Style.VAALEA_ALE: return StringContainer.VAALEAALE
		Style.AMBER_ALE: return StringContainer.AMBERALE
		Style.IPA: return StringContainer.IPA
		_: return StringContainer.TUNTEMATON
