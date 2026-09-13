class_name RunPerk
extends Resource

## A small permanent-for-this-run buff picked on level-up — see
## Brewery.add_xp()/apply_perk() and LevelUpWindow. Unlike RunModifier
## (rolled once, fixed for the whole run, shapes risk/pricing), perks
## accumulate over a run and only ever make things stronger — the
## roguelike "you're growing" half of the loop, where RunModifier is the
## "this run's starting conditions" half.
##
## Each field defaults to neutral (1.0 for multipliers, 0.0 for flat
## bonuses) so multiple perks — including repeats of the same one, see
## PerkRegistry.get_random_perks() — stack by simple multiplication/
## addition in Brewery's get_quality_bonus()/get_reputation_gain_multiplier()/
## get_tip_income_multiplier().

@export var perk_name: String = ""
@export var description: String = ""

## Same "no real art yet" convention as RunModifier.icon_placeholder.
@export var icon_placeholder: String = "⭐"

## Flat addition to a brewed batch's original_quality (quality is already
## known to exceed 1.0 for a masterful batch — see BrewResolver — so this
## isn't clamped).
@export var quality_bonus: float = 0.0

## Multiplies the reputation gained from a sale (see CustomerManager.
## process_auto_sale()).
@export var reputation_gain_multiplier: float = 1.0

## Multiplies the tip earned from a sale (see CustomerManager.
## process_auto_sale()).
@export var tip_income_multiplier: float = 1.0
