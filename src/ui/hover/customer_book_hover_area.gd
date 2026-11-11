class_name CustomerBookHoverArea
extends CounterHoverArea

## Hover-and-glow trigger for the Asiakaskirja, a notebook on the counter.


func _hover_changed(is_entered : bool) -> void:
	GUISignals.mouse_entered_customer_book_hover_area.emit(is_entered)


func _clicked() -> void:
	GUISignals.customer_book_requested.emit()
