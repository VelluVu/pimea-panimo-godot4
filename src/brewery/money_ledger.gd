class_name MoneyLedger
extends RefCounted

## Where the run's money came from and went, for the top bar's money tooltip: today's
## totals per Source and the net of the last few days. Brewery.change_money() records
## into its money_today, and TimeManager closes the day after the night's bills.

enum Source { OTHER, SALES, TIPS, SHIPMENTS, INGREDIENTS, BREWING, BILLS, UPGRADES, LVV, EVENTS, GOALS }

const HISTORY_DAYS : int = 5


## Adds `amount` to `source`'s total in `today` (Source -> float), in place.
static func record(today : Dictionary, source : Source, amount : float) -> void:
	if is_zero_approx(amount):
		return
	today[source] = snappedf(today.get(source, 0.0) + amount, 0.1)


static func net(today : Dictionary) -> float:
	var total : float = 0.0
	for amount : float in today.values():
		total += amount
	return snappedf(total, 0.1)


## `history` (oldest first) with today's net appended, trimmed to HISTORY_DAYS.
static func closed_day(today : Dictionary, history : Array[float]) -> Array[float]:
	var result : Array[float] = history.duplicate()
	result.append(net(today))
	while result.size() > HISTORY_DAYS:
		result.remove_at(0)
	return result
