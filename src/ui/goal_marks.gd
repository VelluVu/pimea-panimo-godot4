class_name GoalMarks
extends RefCounted

## The mark in front of a goal line: a tick once it is met, a cross while it will fail
## today, so the colour is never alone. A met goal is also struck through.

const DONE_PREFIX : String = "✔ "
const FAILED_PREFIX : String = "✖ "


static func prefix_for(state : GoalStatus.State) -> String:
	match state:
		GoalStatus.State.MET:
			return DONE_PREFIX
		GoalStatus.State.FAILING:
			return FAILED_PREFIX
		_:
			return ""


static func is_struck(state : GoalStatus.State) -> bool:
	return state == GoalStatus.State.MET


## Where the strike runs on a right-aligned label: from after the mark to the end of the
## text, as (from, to) in the label's x. Zero length when the text does not fit on one line,
## since a wrapped line would be struck in the wrong place.
static func strike_span(label_width : float, text_width : float, prefix_width : float) -> Vector2:
	if text_width > label_width or text_width <= prefix_width:
		return Vector2.ZERO
	var start : float = label_width - text_width + prefix_width
	return Vector2(floorf(start), floorf(label_width))
