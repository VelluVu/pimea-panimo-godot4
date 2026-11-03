class_name SeasonCatalog
extends RefCounted

## Finds the SeasonData to show. The lookups take the list as a parameter so tests can
## pass their own.

const FOLDER_PATH : String = "res://src/resources/seasons/"

static var _loaded : Array[SeasonData] = []


static func all() -> Array[SeasonData]:
	if _loaded.is_empty():
		_loaded.assign(ResourceFolder.load_all(FOLDER_PATH, SeasonData))
	return _loaded


## The season on the player's clock, or null between seasons.
static func current() -> SeasonData:
	return pick(SeasonRules.now(), SeasonRules.is_winter_now(), all())


## A named season wins over winter, which runs under Black Month; null when neither is on.
static func pick(season : SeasonRules.Season, is_winter : bool, seasons : Array[SeasonData]) -> SeasonData:
	if season != SeasonRules.Season.NONE:
		return of(season, seasons)
	if is_winter:
		for data : SeasonData in seasons:
			if data.winter:
				return data
	return null


static func of(season : SeasonRules.Season, seasons : Array[SeasonData]) -> SeasonData:
	for data : SeasonData in seasons:
		if not data.winter and data.season == season:
			return data
	return null
