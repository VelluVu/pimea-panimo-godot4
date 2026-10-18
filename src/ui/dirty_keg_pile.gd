class_name DirtyKegPile
extends Area2D

## The unwashed empty kegs by the brewery door: a sprite per dirty keg up to
## MAX_SHOWN_KEGS, glow on hover, keg wash on click; hidden while all are clean.

const HOVER_GLOW_COLOR : Color = Color(1.3, 1.15, 0.8, 1.0)
const HIDDEN_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_DURATION_SECONDS : float = 0.15
const MAX_SHOWN_KEGS : int = KegRules.START_KEGS

@onready var _keg_sprites : Array[Sprite2D] = [%DirtyKeg1, %DirtyKeg2, %DirtyKeg3, %DirtyKeg4]

var current_tween : Tween
var _count : int = 0
## The shop and brewery views lie over the pile, so it takes no hover meanwhile.
var _covered : bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	BrewerySignals.brewery_state_changed.connect(_on_brewery_state_changed)
	GUISignals.bar_view_exited.connect(_set_covered.bind(true))
	GUISignals.bar_view_entered.connect(_set_covered.bind(false))
	modulate = HIDDEN_COLOR
	_show_count(0)


func _on_brewery_state_changed(brewery : Brewery) -> void:
	_show_count(brewery.inventory.dirty_keg_count())


func _show_count(count : int) -> void:
	_count = count
	for i : int in _keg_sprites.size():
		_keg_sprites[i].visible = i < mini(count, MAX_SHOWN_KEGS)
	visible = count > 0
	_update_pickable()


func _set_covered(covered : bool) -> void:
	_covered = covered
	_update_pickable()


func _update_pickable() -> void:
	input_pickable = _count > 0 and not _covered
	if not input_pickable:
		modulate = HIDDEN_COLOR
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
