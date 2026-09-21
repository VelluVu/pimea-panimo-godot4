class_name TooltipLabel
extends Label

## A Label with TooltipFactory's wrapping tooltip built in. Use it instead of Label.new(), or
## attach it to a scene Label with label.set_script(TooltipLabel).
func _make_custom_tooltip(for_text: String) -> Object:
	return TooltipFactory.make_wrapped_tooltip(for_text)
