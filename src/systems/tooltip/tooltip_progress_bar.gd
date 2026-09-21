class_name TooltipProgressBar
extends ProgressBar

## A ProgressBar with TooltipFactory's wrapping tooltip built in. Attach it to a scene bar
## with bar.set_script(TooltipProgressBar).
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
