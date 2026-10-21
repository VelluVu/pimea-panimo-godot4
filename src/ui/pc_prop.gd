class_name PCProp
extends CanvasGroup

## The shop's PC on the bar counter: glows and gets its hover outline (hover_outline.gdshader)
## while the shop entrance is hovered. Its modulate, not self_modulate, so the glow reaches
## the PC sprite inside and the outline shader sees it as COLOR.

const HOVER_GLOW_COLOR = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS = 0.15

var current_tween: Tween


func _ready() -> void:
	modulate = HIDDEN_COLOR
	GUISignals.mouse_entered_shop_hover_area.connect(_on_shop_hover_changed)


func _on_shop_hover_changed(is_hovered: bool) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	var target_color := HOVER_GLOW_COLOR if is_hovered else HIDDEN_COLOR
	var ease_type := Tween.EASE_OUT if is_hovered else Tween.EASE_IN

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", target_color, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(ease_type)
