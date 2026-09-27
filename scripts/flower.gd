class_name Flower extends Area2D

@export_enum("red", "blue") var flower_color: String = "red"
enum FlowerState {BULB, GROW, BLOOM}
var current_state

func _ready():
	current_state = FlowerState.BLOOM
	$Color.play(flower_color)

func interact(player) -> bool:
	if player.player_color != flower_color or player.nectar >= player.current_nectar_capacity:
		return false
	current_state = FlowerState.BULB
	print("picked!")
	player.nectar += 1
	return true

func pollen(player) -> bool:
	
	if player.player_color != flower_color:
		return false
	print('qwejqwe')
	return true
