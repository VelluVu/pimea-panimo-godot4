class_name MashProgram
extends RefCounted

## How the mash's counted time splits over its steps. Every style mashes for MASH_SECONDS;
## a step mash keeps its short rests first, like a real protein rest.

const MASH_SECONDS : float = 10.0


static func step_seconds(step_count : int) -> Array[float]:
	var seconds : Array[float] = []
	match step_count:
		1: seconds.assign([10.0])
		2: seconds.assign([4.0, 6.0])
		3: seconds.assign([2.0, 4.0, 4.0])
		4: seconds.assign([2.0, 2.0, 3.0, 3.0])
		_:
			for i : int in maxi(step_count, 1):
				seconds.append(MASH_SECONDS / maxi(step_count, 1))
	return seconds
