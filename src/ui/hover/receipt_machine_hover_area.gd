class_name ReceiptMachineHoverArea
extends CounterHoverArea

## Hover-and-glow trigger for the receipt log ("Kuitit"), a receipt machine.


func _hover_changed(is_entered : bool) -> void:
	GUISignals.mouse_entered_receipt_machine_hover_area.emit(is_entered)


func _clicked() -> void:
	GUISignals.receipt_log_requested.emit()
