class_name PCProp
extends Sprite2D


const HOVER_GLOW_COLOR = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS = 0.15

var current_tween: Tween


func _ready() -> void:
	self_modulate = HIDDEN_COLOR
	GUISignals.mouse_entered_shop_hover_area.connect(_on_shop_hover_changed)


func _on_shop_hover_changed(is_hovered: bool) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	var target_color := HOVER_GLOW_COLOR if is_hovered else HIDDEN_COLOR
	var ease_type := Tween.EASE_OUT if is_hovered else Tween.EASE_IN

	current_tween = create_tween()
	current_tween.tween_property(self, "self_modulate", target_color, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(ease_type)
