class_name CustomerBookLabel
extends Label

## Hover label for CustomerBookHoverArea, same pattern as ReceiptMachineLabel.

const LABEL_TEXT : String = "Panimokirja"


func _ready() -> void:
	text = LABEL_TEXT
	hide()
	GUISignals.mouse_entered_customer_book_hover_area.connect(func(is_entered : bool) -> void: visible = is_entered)
	# The window opens under the cursor, so the hover never ends on its own.
	GUISignals.customer_book_requested.connect(hide)
