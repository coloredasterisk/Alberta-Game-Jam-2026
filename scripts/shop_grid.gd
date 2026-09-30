extends Control


@onready var highlighted = $Cancel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func highlight(thing_name : String) -> void:
	var shop_item
	if thing_name == "":
		shop_item = $Cancel
	else:
		shop_item = get_node(thing_name.capitalize())
	highlighted.self_modulate = Color.WHITE
	shop_item.self_modulate = Color(0.863, 1.57, 1.57)
	highlighted = shop_item
	
