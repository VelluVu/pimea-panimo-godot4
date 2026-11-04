class_name SeasonMusic
extends Resource

## Tracks mixed into the run playlist while their season is on (the Christmas carols).

@export var season : SeasonRules.Season = SeasonRules.Season.NONE
@export var tracks : Array[AudioStream] = []
