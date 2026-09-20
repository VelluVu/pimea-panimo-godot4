class_name TooltipButton
extends Button

## Same as TooltipLabel, for Button.new() call sites that set tooltip_text —
## see TooltipFactory.
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
