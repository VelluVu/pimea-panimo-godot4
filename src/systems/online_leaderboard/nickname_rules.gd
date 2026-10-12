class_name NicknameRules
extends RefCounted

## What a player name on a shared list may be: printable, single spaced and short.
## The server checks the length again; this keeps the field and the request tidy.

const MAX_LENGTH: int = 16


## Control characters dropped, runs of spaces made one, trimmed and cut to MAX_LENGTH.
static func clean(text: String) -> String:
	var kept: String = ""
	for i: int in text.length():
		var code: int = text.unicode_at(i)
		kept += " " if code < 32 or code == 127 else text[i]
	var words: PackedStringArray = kept.split(" ", false)
	return " ".join(words).left(MAX_LENGTH).strip_edges()


static func is_valid(text: String) -> bool:
	return not clean(text).is_empty()
