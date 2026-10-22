class_name ReputationBreakdownText
extends RefCounted

## The day recap's "where did reputation come from" suffix, e.g.
## " (asiakkaat +12, hiipuminen -4)".

const CUSTOMERS_TEXT: String = "asiakkaat"
const GOALS_TEXT: String = "tavoitteet"
const EVENTS_TEXT: String = "tapahtumat"
const BREWING_TEXT: String = "panimo"
const DECAY_TEXT: String = "hiipuminen"
const LVV_TEXT: String = "LVV"
const EARLY_CLOSE_TEXT: String = "aikainen sulkeminen"
const OTHER_TEXT: String = "muut"
## Separate constants, so the translation extractor finds the names.
const SOURCE_NAMES: Dictionary = {
	ReputationRules.Source.CUSTOMERS: CUSTOMERS_TEXT,
	ReputationRules.Source.GOALS: GOALS_TEXT,
	ReputationRules.Source.EVENTS: EVENTS_TEXT,
	ReputationRules.Source.BREWING: BREWING_TEXT,
	ReputationRules.Source.DECAY: DECAY_TEXT,
	ReputationRules.Source.LVV: LVV_TEXT,
	ReputationRules.Source.EARLY_CLOSE: EARLY_CLOSE_TEXT,
	ReputationRules.Source.OTHER: OTHER_TEXT,
}
const ENTRY_FORMAT: String = "%s %+d"
const SUFFIX_FORMAT: String = " (%s)"


## `totals` maps ReputationRules.Source to the summed change. Empty when nothing moved.
static func format(totals: Dictionary) -> String:
	var entries: PackedStringArray = []
	for source: int in SOURCE_NAMES:
		var amount: int = totals.get(source, 0)
		if amount != 0:
			entries.append(ENTRY_FORMAT % [UiText.of(SOURCE_NAMES[source]), amount])
	if entries.is_empty():
		return ""
	return SUFFIX_FORMAT % ", ".join(entries)
