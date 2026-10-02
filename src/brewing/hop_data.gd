class_name HopData
extends IngredientData


enum FlavorProfile { NONE, CITRUS, TROPICAL, PINE, NOBLE, EARTHY, JUNIPER }

@export var alpha_acids : int
@export var beta_acids : int
@export var flavor_profile : FlavorProfile = FlavorProfile.NONE


func get_stat_string() -> String:
	var base_stats := tr(StringContainer.HOP_STAT_STRING) % [alpha_acids, beta_acids]

	if flavor_profile == FlavorProfile.NONE:
		return base_stats

	return base_stats + "\n" + tr(StringContainer.HOP_FLAVOR_STRING) % get_flavor_profile_display_name(flavor_profile)


static func get_flavor_profile_display_name(profile: FlavorProfile) -> String:
	match profile:
		FlavorProfile.CITRUS: return UiText.of(StringContainer.HOP_FLAVOR_CITRUS)
		FlavorProfile.TROPICAL: return UiText.of(StringContainer.HOP_FLAVOR_TROPICAL)
		FlavorProfile.PINE: return UiText.of(StringContainer.HOP_FLAVOR_PINE)
		FlavorProfile.NOBLE: return UiText.of(StringContainer.HOP_FLAVOR_NOBLE)
		FlavorProfile.EARTHY: return UiText.of(StringContainer.HOP_FLAVOR_EARTHY)
		FlavorProfile.JUNIPER: return UiText.of(StringContainer.HOP_FLAVOR_JUNIPER)
		_: return ""
