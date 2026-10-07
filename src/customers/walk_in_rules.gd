class_name WalkInRules
extends RefCounted

## How many customers one walk-in tick brings. Usually one; now and then the walk-in
## arrives with company, the others following a moment apart. Perks and Olutoppi
## talents raise the chance (walk_in_company_chance) and the company's size
## (walk_in_company_bonus).

const BASE_COMPANY_CHANCE : float = 0.02
const COMPANY_SIZE : int = 2
## Seconds between the members of a company, so they walk in one after another.
const COMPANY_GAP_SECONDS : Vector2 = Vector2(1.0, 2.0)


static func company_chance(perk_chance : float) -> float:
	return clampf(BASE_COMPANY_CHANCE + perk_chance, 0.0, 1.0)


## `roll` is randf(): below the chance the walk-in brings company.
static func customer_count(roll : float, chance : float, company_bonus : int) -> int:
	if roll >= chance:
		return 1
	return COMPANY_SIZE + maxi(0, company_bonus)
