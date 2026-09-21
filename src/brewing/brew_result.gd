class_name BrewResult
extends Resource


@export var beer_style : BeerStyle
@export var final_ebc : int = 0
@export var final_ibu : int = 0
@export var original_quality : float = 1.0
@export var reputation_change : int = 0
## A batch is one 20L keg; at 0.44L per serving that's ~45 servings once
## StylePricing.BOTTLE_LOSS_RATE's loss is applied — see
## get_effective_bottle_yield(). 47 raw so the after-loss number lands on
## 45, not the raw figure itself.
@export var bottle_yield : int = 47
@export var is_matched : bool = true

@export var precision_score : float = 1.0
@export var hop_diversity_count : int = 0
@export var hop_balance_bonus : float = 0.0
@export var flavor_matched : bool = false
