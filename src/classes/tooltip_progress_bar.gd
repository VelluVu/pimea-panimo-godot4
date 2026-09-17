class_name TooltipProgressBar
extends ProgressBar

## Same as TooltipLabel, for a scene-defined ProgressBar whose tooltip_text
## needs TooltipFactory's wrapping instead of the engine default — attach
## via existing_bar.set_script(TooltipProgressBar).
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
