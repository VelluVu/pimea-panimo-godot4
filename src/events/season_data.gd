class_name SeasonData
extends Resource

## How one season shows in the UI: the top bar's chip, the card when it starts and the mark
## on its seasonal goods. SeasonCatalog loads them from res://src/resources/seasons/.

## Which season this is. Winter is not a SeasonRules.Season: it takes `winter` and NONE.
@export var season : SeasonRules.Season = SeasonRules.Season.NONE
@export var winter : bool = false
@export var title : String = ""
## One emoji the icon font draws (see make_icon_font.py).
@export var icon : String = ""
## What the season brings, for the chip's tooltip and the card.
@export_multiline var description : String = ""


## Saved on the run, so the start card shows once per season.
func id() -> String:
	return resource_path.get_file().get_basename()
