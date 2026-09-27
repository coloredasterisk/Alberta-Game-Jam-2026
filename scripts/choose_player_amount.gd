extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range($Amount.get_child_count()):
		$Amount.get_child(i).pressed.connect(send_player_amount.bind(i+1))
	
func send_player_amount(amount : int) -> void:
	get_parent().get_parent().set_player_amount(amount)
