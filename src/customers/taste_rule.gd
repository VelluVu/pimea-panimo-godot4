class_name TasteRule
extends Resource

## One kind of beer a customer likes (see CustomerData's taste tiers): a group of styles,
## something about the batch itself, or both. Every condition that is set must hold.

## Shown in the Asiakaskirja, e.g. "saksalaiset oluet".
@export var label : String = ""
## Empty = any style. A favourite tier rolls its favourite from these.
@export var styles : Array[BeerStyle.Style] = []
## -1 = no limit. Compared with the batch's own ABV, above this.
@export var min_abv_over : float = -1.0
## -1 = no limit. The batch's own colour, at least this.
@export var min_ebc : int = -1
@export var needs_spices : bool = false
## Non-empty: an aroma or dry hop of one of these flavours went in (BatchTraits).
@export var late_hop_profiles : Array[HopData.FlavorProfile] = []
## Non-empty: a hop of one of these flavours went in at any point of the boil.
@export var hop_profiles : Array[HopData.FlavorProfile] = []
## Non-empty: the batch was brewed with at least one of these malts.
@export var malt_ids : Array[int] = []
## -1 = no limit. A batch below this does not count for this rule.
@export var min_quality : float = -1.0


func matches(batch : BrewBatch) -> bool:
	if not styles.is_empty() and not styles.has(batch.beer_style.style):
		return false
	if min_abv_over >= 0.0 and batch.get_abv() <= min_abv_over:
		return false
	if min_ebc >= 0 and batch.final_ebc < min_ebc:
		return false
	if needs_spices and not batch.spiced:
		return false
	if not late_hop_profiles.is_empty() and not late_hop_profiles.any(func(profile : HopData.FlavorProfile) -> bool: return batch.late_hop_profiles.has(profile)):
		return false
	if not hop_profiles.is_empty() and not hop_profiles.any(func(profile : HopData.FlavorProfile) -> bool: return batch.hop_profiles.has(profile)):
		return false
	if not malt_ids.is_empty() and not malt_ids.any(func(id : int) -> bool: return batch.malt_ids.has(id)):
		return false
	if min_quality >= 0.0 and batch.current_quality < min_quality:
		return false
	return true


static func any_matches(rules : Array[TasteRule], batch : BrewBatch) -> bool:
	return rules.any(func(rule : TasteRule) -> bool: return rule.matches(batch))
