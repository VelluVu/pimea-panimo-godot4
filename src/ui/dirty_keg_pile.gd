class_name DirtyKegPile
extends Area2D

## The unwashed empty kegs in the cellar corner by the brewery door. Shows one keg sprite
## per dirty keg up to MAX_SHOWN_KEGS, the season's starting kegs (the label tells the full
## count), lights up on hover like the other cellar props and opens the keg wash on click.
## Hidden while every keg is clean.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15
const MAX_SHOWN_KEGS : int = KegRules.START_KEGS

@onready var _keg_sprites : Array[Sprite2D] = [%DirtyKeg1, %DirtyKeg2, %DirtyKeg3, %DirtyKeg4]

var current_tween : Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	modulate = HIDDEN_COLOR
	_show_count(0)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_show_count(brewery.inventory.dirty_keg_count())


func _show_count(count : int) -> void:
	for i : int in _keg_sprites.size():
		_keg_sprites[i].visible = i < mini(count, MAX_SHOWN_KEGS)
	visible = count > 0
	input_pickable = count > 0
	if count == 0:
		GUISignals.mouse_entered_dirty_keg_pile.emit(false, 0)


func _on_mouse_entered() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", HOVER_GLOW_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	GUISignals.mouse_entered_dirty_keg_pile.emit(true, _shown_dirty_count())


func _on_mouse_exited() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate", HIDDEN_COLOR, TWEEN_DURATION_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	GUISignals.mouse_entered_dirty_keg_pile.emit(false, 0)


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GUISignals.keg_wash_requested.emit()


func _shown_dirty_count() -> int:
	var brewery : Brewery = BrewEngine.current_brewery
	return 0 if brewery == null else brewery.inventory.dirty_keg_count()
