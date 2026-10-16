class_name HopUtilization
extends RefCounted

## How much of a hop's alpha acid ends up as bitterness, by the mark it goes in on. The
## curve is Tinseth's boil-time term, 1 - e^(-0.04 t), relative to a full 60-minute
## boil, so a bittering addition bitters as fully as before and late hops far less.

## Boil minutes each mark stands for. The aroma mark goes in at flame-out and stands in
## the hot wort, which bitters about as much as a few minutes of boiling.
const MINUTES : Dictionary = {
	HopAddition.Kind.BITTERING: 60.0,
	HopAddition.Kind.FLAVOR: 15.0,
	HopAddition.Kind.AROMA: 2.5,
	HopAddition.Kind.DRY_HOP: 0.0,
}
const FULL_BOIL_MINUTES : float = 60.0
const TINSETH_RATE : float = 0.04


## Share of a full boil's bitterness, 1.0 for bittering down to 0 for the dry hop.
static func of(kind : HopAddition.Kind) -> float:
	var minutes : float = float(MINUTES.get(kind, 0.0))
	return _time_factor(minutes) / _time_factor(FULL_BOIL_MINUTES)


## IBU of hop marks: alpha x grams x utilisation, at the game's scale (a full boil gives
## alpha x grams / BrewMixture.ALPHA_ACIDS_PER_IBU). Spice marks have no alpha acid.
static func ibu(marks : Array[BoilMark], table : Dictionary) -> int:
	var alpha : float = 0.0
	for mark : BoilMark in marks:
		var hop : HopData = table.get(mark.ingredient_id) as HopData
		if hop != null:
			alpha += hop.alpha_acids * mark.grams * of(mark.kind)
	return roundi(alpha / BrewMixture.ALPHA_ACIDS_PER_IBU)


static func _time_factor(minutes : float) -> float:
	return 1.0 - exp(-TINSETH_RATE * minutes)
