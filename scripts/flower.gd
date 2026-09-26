class_name Flower extends Area2D

@export_enum("red", "blue") var flower_color: String = "red"

func _ready():
	$Color.play(flower_color)

func interact(player) -> bool:
	if player.player_color != flower_color:
		return false
	print("picked!")
	
	queue_free()
	return true
