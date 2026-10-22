class_name CustomerPreviewText
extends RefCounted

## The customer's line before the sale: the styles they will take, or that nothing suits.

## Joins the style names when a customer previews more than one batch.
const STYLE_JOINER : String = " ja "


## `style_names` are the picked batches' styles, already in the active language.
static func line(data : CustomerData, style_names : PackedStringArray) -> String:
	if style_names.is_empty() or data.browses_only:
		return UiText.of(data.dialogue_nothing_available)
	return UiText.of(data.dialogue_preview_format) % UiText.of(STYLE_JOINER).join(style_names)
