extends Panel

func _ready() -> void:
	visible = false

func update_display(placement, honey) -> void:
	visible = true
	$RichTextLabel.text = placement + "\n\nWith " + str(honey) + " Honey"
