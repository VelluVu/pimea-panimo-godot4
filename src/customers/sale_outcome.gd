class_name SaleOutcome
extends RefCounted

## What a sale is worth, before SaleProcessor applies it to the Brewery.

var gross_income : float = 0.0
var tip_income : float = 0.0
## The tip-double perk fired on this sale.
var tip_doubled : bool = false
var net_income : float = 0.0
var reputation_gain : int = 0
