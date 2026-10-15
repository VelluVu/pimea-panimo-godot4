class_name SourReactions
extends Resource

## What a customer says when the beer they bought turned sour in a dirty keg, by how
## badly it soured (FermentationRules.SourLevel). Any customer may say any line.

@export var light_lines : Array[String] = []
@export var sour_lines : Array[String] = []
@export var spoiled_lines : Array[String] = []


## A random line for `level`, or "" when the batch did not sour.
func line_for(level : FermentationRules.SourLevel) -> String:
	var lines : Array[String] = []
	match level:
		FermentationRules.SourLevel.LIGHT:
			lines = light_lines
		FermentationRules.SourLevel.CLEAR:
			lines = sour_lines
		FermentationRules.SourLevel.STRONG:
			lines = spoiled_lines
	return "" if lines.is_empty() else lines.pick_random()
