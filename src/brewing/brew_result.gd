class_name BrewResult
extends Resource


@export var beer_style : BeerStyle
@export var final_ebc : int = 0
@export var final_ibu : int = 0
@export var original_quality : float = 1.0
@export var reputation_change : int = 0
## Computed from the grist, see BrewFormulas.
@export var abv : float = 0.0
## Kilograms of malt and sugar, checked against the mash tun (MashTun).
@export var malt_weight : float = 0.0
## One 20 L keg at 0.44 L a serving is about 45 after BOTTLE_LOSS_RATE: 47 raw lands on 45.
@export var bottle_yield : int = 47
@export var is_matched : bool = true

@export var precision_score : float = 1.0
@export var hop_diversity_count : int = 0
## Hop layers filled well, out of the style's hop marks (BrewQuality.good_hop_layers()).
@export var hop_layers : int = 0
@export var hop_layer_slots : int = 0
@export var flavor_matched : bool = false
@export var spice_bonus : float = 0.0
## Quality lost to spices the style does not like, see BrewQuality.unsuited_spice_penalty().
@export var unsuited_spice_penalty : float = 0.0
## Quality from the style's character malts, see BrewQuality.malt_bonus().
@export var malt_bonus : float = 0.0
