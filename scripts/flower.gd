class_name Flower extends Area2D

@export_enum("red", "blue", "yellow", "green") var flower_color: String = "red"
enum FlowerState {BULB, GROW, BLOOM}
var current_state
var can_give_pollen: bool = true

func _ready():
	current_state = FlowerState.BLOOM
	$Color.play(flower_color)

func interact(player) -> bool:
	if player.player_color != flower_color or player.nectar >= player.current_nectar_capacity:
		return false
	if current_state == FlowerState.BLOOM:
		current_state = FlowerState.BULB
		print(current_state)
		player.nectar += 1
		print("picked! nectar counter: ", player.nectar)
	elif current_state == FlowerState.BULB and player.pollen_counter == 4:
		current_state = FlowerState.GROW
		player.pollen_counter = 0
		$Growing_Cooldown.start()
		print("you changed to grow ", current_state)
	return true

func pollen(player) -> bool:
	if player.player_color != flower_color:
		return false
	if current_state == FlowerState.BLOOM and can_give_pollen:
		player.pollen_counter += 1
		can_give_pollen = false
		print(player.pollen_counter)
	return true

func _on_growing_cooldown_timeout() -> void:
	current_state = FlowerState.BLOOM
	print(current_state, "flower grown")
