class_name GroupVisitSnapshot
extends Resource

## One crowd visit frozen mid-visit for the save (Brewery.cellar_groups), like
## CustomerSnapshot for a solo customer. GroupVisit.snapshot() fills it and
## GroupVisitDirector.resume() plays it back from the same stage.

@export var event_data : GroupVisitEventData
@export var slot : int = -1
## The counter spot when saved, so members can shift if the visit resumes at another one.
@export var counter_position : Vector2 = Vector2.ZERO
@export var stage : GroupVisit.Stage = GroupVisit.Stage.SPAWNING
## Seconds left of the stage's current wait.
@export var time_left : float = 0.0

@export var group_size : int = 0
@export var chant_index : int = 0

## After the order: the sale is already in the saved money and stock.
@export var order_data : CustomerData
@export var response_text : String = ""
@export var purchased : bool = false
@export var beer_ebc : int = -1
@export var bar_fight_bottles : int = -1
@export var served : int = 0
@export var glasses_out : int = 0
## The sale's money and reputation popups, still to show once the round is poured.
@export var popups_pending : bool = false
@export var popup_reputation : int = 0
@export var popup_income : float = 0.0
@export var popup_tip : float = 0.0
@export var popup_tip_tier : PopupTierRules.Tier = PopupTierRules.Tier.NORMAL
@export var popup_beer_quality : float = -1.0
@export var popup_notes : Array[int] = []

## The shared bubble on screen and its seconds left.
@export var bubble_text : String = ""
@export var bubble_position : Vector2 = Vector2.ZERO
@export var bubble_fade : float = 0.0
@export var bubble_time_left : float = 0.0

## In walk-in order; null where a member had already gone.
@export var members : Array[CustomerSnapshot] = []
