class_name ReputationBreakdownText
extends RefCounted

## The day recap's "where did reputation come from" suffix, e.g.
## " (asiakkaat +12, hiipuminen -4)".

const SOURCE_NAMES: Dictionary = {
	ReputationRules.Source.CUSTOMERS: "asiakkaat",
	ReputationRules.Source.GOALS: "tavoitteet",
	ReputationRules.Source.EVENTS: "tapahtumat",
	ReputationRules.Source.BREWING: "panimo",
	ReputationRules.Source.DECAY: "hiipuminen",
	ReputationRules.Source.LVV: "LVV",
	ReputationRules.Source.EARLY_CLOSE: "aikainen sulkeminen",
	ReputationRules.Source.OTHER: "muut",
}
const ENTRY_FORMAT: String = "%s %+d"
const SUFFIX_FORMAT: String = " (%s)"


## `totals` maps ReputationRules.Source to the summed change. Empty when nothing moved.
static func format(totals: Dictionary) -> String:
	var entries: PackedStringArray = []
	for source: int in SOURCE_NAMES:
		var amount: int = totals.get(source, 0)
		if amount != 0:
			entries.append(ENTRY_FORMAT % [SOURCE_NAMES[source], amount])
	if entries.is_empty():
		return ""
	return SUFFIX_FORMAT % ", ".join(entries)
