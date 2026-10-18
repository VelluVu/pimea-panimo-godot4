class_name FirstBrewRules
extends RefCounted

## The season's first batch of each style is a novelty ("Uutuus"): XP by how demanding the
## style is, and a counter premium. Every season counts, so veterans keep brewing the
## whole range.

## Extra share of the counter price a novelty batch sells for.
const NOVELTY_PRICE_BONUS : float = 0.25
## XP per point of the style's reputation_change: 20 for a plain lager, 60 for an
## Imperial Stout.
const XP_PER_STYLE_REPUTATION : int = 10


static func xp_bonus(beer_style : BeerStyle) -> int:
	return maxi(1, beer_style.reputation_change) * XP_PER_STYLE_REPUTATION


static func price_multiplier(novelty : bool) -> float:
	return 1.0 + NOVELTY_PRICE_BONUS if novelty else 1.0
