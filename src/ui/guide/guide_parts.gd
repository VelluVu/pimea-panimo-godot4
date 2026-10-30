class_name GuideParts
extends RefCounted

## Which parts of Aatu's tutorial are still to come in this run. Every new game has the
## whole tutorial unless "Ohita opastus" is set in Asetukset, the only way to turn it off or
## on. A part seen through is remembered in the run's save (Brewery.guide_parts_done).

enum Part { CELLAR, BREW_DAY, TALK }


## The rule: the cellar route and the guided brew day belong before the run's first brew;
## the talk comes after it.
static func is_on_for(part : Part, skipped : bool, done : Array[int], has_brewed : bool) -> bool:
	if skipped or done.has(part):
		return false
	return has_brewed if part == Part.TALK else not has_brewed


static func is_on(part : Part, brewery : Brewery) -> bool:
	return brewery != null and is_on_for(part, is_skipped(), brewery.guide_parts_done, brewery.has_brewed)


static func finish(part : Part, brewery : Brewery) -> void:
	if brewery != null and not brewery.guide_parts_done.has(part):
		brewery.guide_parts_done.append(part)


static func is_skipped() -> bool:
	return SettingsManager.get_option(SettingsManager.OPTION_SKIP_TUTORIAL)


static func set_skipped(skip : bool) -> void:
	SettingsManager.set_option(SettingsManager.OPTION_SKIP_TUTORIAL, skip)
