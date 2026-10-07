class_name LegacySaveText
extends RefCounted

## Text fixes for saves written by older builds that would otherwise fail to load at
## all, so they cannot wait for SaveSlot's _migrate(), which runs after loading.

## Run modifier cards were removed: a save still links its card's .tres, and a missing
## [ext_resource] makes Godot reject the whole file.
const REMOVED_MODIFIER_FOLDER : String = "res://src/resources/run_modifiers/"
const REMOVED_MODIFIER_PROPERTY : String = "run_modifier = "


static func needs_cleanup(text : String) -> bool:
	return text.contains(REMOVED_MODIFIER_FOLDER)


static func cleaned(text : String) -> String:
	var kept : PackedStringArray = []
	for line : String in text.split("\n"):
		if line.begins_with("[ext_resource") and line.contains(REMOVED_MODIFIER_FOLDER):
			continue
		if line.begins_with(REMOVED_MODIFIER_PROPERTY):
			continue
		kept.append(line)
	return "\n".join(kept)
