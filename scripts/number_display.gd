extends HBoxContainer

@export var number: int = 0

func _ready() -> void:
	update_display()

func update_display() -> void:
	var count = 0
	for child in get_children():
		child.text = str(number)[count]
		count += 1
