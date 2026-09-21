class_name TooltipButton
extends Button

## A Button with TooltipFactory's wrapping tooltip built in.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
