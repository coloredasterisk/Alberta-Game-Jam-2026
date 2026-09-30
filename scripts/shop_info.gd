extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_display("", 1)


func _update_display(item_name : String, money) -> void:
	$Name.text = item_name.capitalize()
	$Cost/CostAmount.text = str(Global.powerup_costs[item_name])
	if money < Global.powerup_costs[item_name]:
		$Cost/CostAmount.modulate = Color.RED
	else:
		$Cost/CostAmount.modulate = Color.WHITE
	$Description.text = Global.powerup_descriptions[item_name]
	$Icon.texture = Global.powerup_icons[item_name]
	visible = true
