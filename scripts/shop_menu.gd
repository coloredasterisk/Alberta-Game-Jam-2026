extends Control

@export_enum("left","right") var direction = "left"


func _ready() -> void:
	if direction == "right":
		$ShopInfo.position.x = 225

func update_item(item : String, player) -> void:
	$ShopGrid.highlight(item)
	$ShopInfo._update_display(item, player)
