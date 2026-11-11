class_name PopupTierRules
extends RefCounted

## How loud a sale's gain popups are, like an RPG crit. Tips are judged against the price,
## so a big tip feels big on any style; reputation and XP follow the quality sold.

enum Tier { NORMAL, BIG, CRITICAL }

const BIG_TIP_SHARE : float = 0.5
const CRITICAL_TIP_SHARE : float = 1.0
const BIG_QUALITY : float = QualityTier.EXCELLENT_FROM
const CRITICAL_QUALITY : float = QualityTier.MASTERFUL_FROM


## A doubled tip is always critical: the perk roll is the crit.
static func tip_tier(tip : float, sale_price : float, doubled : bool) -> Tier:
	if tip <= 0.0:
		return Tier.NORMAL
	if doubled:
		return Tier.CRITICAL
	var share : float = tip / maxf(sale_price, 0.1)
	if share >= CRITICAL_TIP_SHARE:
		return Tier.CRITICAL
	if share >= BIG_TIP_SHARE:
		return Tier.BIG
	return Tier.NORMAL


## Only a gain is loud; a penalty stays a plain popup however good the beer was.
static func quality_tier(quality : float, gain : int) -> Tier:
	if gain <= 0:
		return Tier.NORMAL
	if quality >= CRITICAL_QUALITY:
		return Tier.CRITICAL
	if quality >= BIG_QUALITY:
		return Tier.BIG
	return Tier.NORMAL
