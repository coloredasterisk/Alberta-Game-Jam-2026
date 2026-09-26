extends HBoxContainer

@export var number: int = 0

func _ready() -> void:
	update_display(number)

func update_display(num : int) -> void:
	var count = 0
	var str_num = str(num)
	for child in get_children():
		if count >= str_num.length():
			child.visible = false
			continue
		child.texture = Global.num_to_art[int(str_num[count])]
		count += 1
