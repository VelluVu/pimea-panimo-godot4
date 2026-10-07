class_name MoneyText
extends RefCounted

## The top bar's money tooltip: the money, today's net with its income and its costs per
## MoneyLedger.Source, yesterday's net and the last days' trend.

const VALUE_FORMAT : String = "Rahaa %.1f €"
const TODAY_FORMAT : String = "Tänään %+.1f €"
const YESTERDAY_FORMAT : String = "Eilen %+.1f €"
const RECENT_DAYS_FORMAT : String = "Viime päivät: %s"
const PART_FORMAT : String = "%s %+.1f €"
const LINE_INDENT : String = "  "

const SALES_NAME : String = "myynti"
const TIPS_NAME : String = "tipit"
const SHIPMENTS_NAME : String = "tukku ja viennit"
const INGREDIENTS_NAME : String = "ainekset"
const BREWING_NAME : String = "pullotus"
const BILLS_NAME : String = "laskut"
const UPGRADES_NAME : String = "parannukset"
const LVV_NAME : String = "LVV"
const EVENTS_NAME : String = "tapahtumat"
const GOALS_NAME : String = "tavoitteet"
const OTHER_NAME : String = "muut"


## `today` is MoneyLedger.Source -> float, `recent_days` the closed days, oldest first.
static func tooltip(money : float, today : Dictionary, recent_days : Array[float]) -> String:
	var lines : PackedStringArray = [UiText.of(VALUE_FORMAT) % money, UiText.of(TODAY_FORMAT) % MoneyLedger.net(today)]
	var income : PackedStringArray = _parts(today, true)
	if not income.is_empty():
		lines.append(LINE_INDENT + ", ".join(income))
	var costs : PackedStringArray = _parts(today, false)
	if not costs.is_empty():
		lines.append(LINE_INDENT + ", ".join(costs))
	if not recent_days.is_empty():
		lines.append(UiText.of(YESTERDAY_FORMAT) % recent_days[-1])
	if recent_days.size() > 1:
		var days : PackedStringArray = []
		for amount : float in recent_days:
			days.append("%+d" % roundi(amount))
		lines.append(UiText.of(RECENT_DAYS_FORMAT) % "  ".join(days))
	return "\n".join(lines)


static func source_name(source : MoneyLedger.Source) -> String:
	match source:
		MoneyLedger.Source.SALES:
			return UiText.of(SALES_NAME)
		MoneyLedger.Source.TIPS:
			return UiText.of(TIPS_NAME)
		MoneyLedger.Source.SHIPMENTS:
			return UiText.of(SHIPMENTS_NAME)
		MoneyLedger.Source.INGREDIENTS:
			return UiText.of(INGREDIENTS_NAME)
		MoneyLedger.Source.BREWING:
			return UiText.of(BREWING_NAME)
		MoneyLedger.Source.BILLS:
			return UiText.of(BILLS_NAME)
		MoneyLedger.Source.UPGRADES:
			return UiText.of(UPGRADES_NAME)
		MoneyLedger.Source.LVV:
			return UiText.of(LVV_NAME)
		MoneyLedger.Source.EVENTS:
			return UiText.of(EVENTS_NAME)
		MoneyLedger.Source.GOALS:
			return UiText.of(GOALS_NAME)
		_:
			return UiText.of(OTHER_NAME)


## Today's sources that earned (`gains`) or cost money, in Source order.
static func _parts(today : Dictionary, gains : bool) -> PackedStringArray:
	var parts : PackedStringArray = []
	for source : MoneyLedger.Source in MoneyLedger.Source.values():
		var amount : float = today.get(source, 0.0)
		if is_zero_approx(amount) or (amount > 0.0) != gains:
			continue
		parts.append(PART_FORMAT % [source_name(source), amount])
	return parts
