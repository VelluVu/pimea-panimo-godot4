class_name CustomerLines
extends RefCounted

## Which of a moment's lines a customer says. The main line and its alternatives are equally
## likely, and a customer with no alternatives always says the main line.


## `roll` is 0 to 1.
static func pick(line : String, alternatives : Array[String], roll : float = randf()) -> String:
	if alternatives.is_empty():
		return line
	var index : int = mini(floori(roll * (alternatives.size() + 1)), alternatives.size())
	return line if index == 0 else alternatives[index - 1]
