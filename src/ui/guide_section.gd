class_name GuideSection
extends Resource

## One topic of the Panimokirja's Ohjeet tab: a title and short paragraphs, each its own
## translation key. Sections show in `order`.

@export var order : int = 0
@export var title : String = ""
@export var lines : Array[String] = []
