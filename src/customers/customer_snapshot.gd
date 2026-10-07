class_name CustomerSnapshot
extends Resource

## One customer frozen mid-visit for the save (Brewery.cellar_customers, or a member in
## a GroupVisitSnapshot), so a loaded run carries on exactly where it was: the same spot,
## the same line, the same time left. Customer.snapshot() fills it and Customer.resume()
## plays it back.

## WAITING is a group member standing at the counter; its group does the talking.
enum Phase { WALKING_IN, GREETING, PREVIEWING, SERVED, LEAVING, WAITING }

@export var data : CustomerData
@export var generated_name : String = ""
@export var slot : int = -1
@export var phase : Phase = Phase.WALKING_IN
@export var group_member : bool = false
@export var position : Vector2 = Vector2.ZERO

## Walking in: the waypoints (spawn, stairs bottom, room centre, counter spot), the leg
## under way (Customer.Leg) and, for the pause in the centre, its seconds left.
@export var route : Array[Vector2] = []
@export var leg : int = 0
@export var pause_left : float = 0.0

## At the counter: the line on screen and the seconds before the next step.
@export var bubble_text : String = ""
@export var time_left : float = 0.0

## After the sale, which is already in the saved money and stock.
@export var made_purchase : bool = false
@export var beer_ebc : int = -1
## Seconds before the served glass appears; negative once it is on the counter.
@export var glass_time_left : float = -1.0
@export var glass_shown : bool = false
@export var glass_position : Vector2 = Vector2.ZERO

## Walking out; a group member may first walk to the bar stack for their glass.
@export var exit_position : Vector2 = Vector2.ZERO
@export var walks_to_pickup : bool = false
@export var pickup_position : Vector2 = Vector2.ZERO
