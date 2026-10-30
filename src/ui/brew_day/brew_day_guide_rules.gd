class_name BrewDayGuideRules
extends RefCounted

## The guided first brew day's step, from what the kettle is doing now. Only explains:
## the rules and the scoring stay the same. BrewDayWindow shows the step's text and
## points at its control.

enum Phase { MASH, MASH_DONE, BOIL, RESULT }
enum Step { NONE, HEAT_WATER, COOL_WATER, POUR_MALTS, BREAK_CLUMPS, HOLD_MASH, TO_BOIL, HEAT_BOIL, KEEP_BOILING, WATCH_FOAM, ADD_HOPS, FINISH }


## `in_band`: the mash is in its green band; `too_hot`: above it. `foaming`: the boil is in the orange zone,
## which outranks a hop sack: a boil-over costs more than a late handful.
static func mash_step(phase : Phase, malts_added : bool, in_band : bool, too_hot : bool, clumps_left : bool) -> Step:
	match phase:
		Phase.MASH:
			if not malts_added:
				if in_band:
					return Step.POUR_MALTS
				return Step.COOL_WATER if too_hot else Step.HEAT_WATER
			return Step.BREAK_CLUMPS if clumps_left else Step.HOLD_MASH
		Phase.MASH_DONE:
			return Step.TO_BOIL
		Phase.RESULT:
			return Step.FINISH
		_:
			return Step.NONE


static func boil_step(boiling : bool, foaming : bool, hop_cued : bool) -> Step:
	if foaming:
		return Step.WATCH_FOAM
	if hop_cued:
		return Step.ADD_HOPS
	return Step.KEEP_BOILING if boiling else Step.HEAT_BOIL
