extends Node2D

const FLOWER = preload("res://scenes/flower.tscn")
const RAIN = preload("res://scenes/rain_powerup.tscn")
var flower
var rain

func _ready():
	for item in $Shop.get_children():
		if item.has_signal("purchased"):
			item.purchased.connect(_on_powerup_purchased)

func _on_powerup_purchased(type: String, buyer: Player):
	match type:
		"confusion":
			for bee in [$Red_Bee, $Blue_Bee]:#add players
				if bee != buyer:
					bee.confusion()
		"speed":
			buyer.max_velocity += 50
			await get_tree().create_timer(Global.speed_duration).timeout
			buyer.max_velocity -= 50
		"rain":
			for bee in [$Red_Bee, $Blue_Bee]:#add players
				if bee != buyer:
					rain_spawning(bee)
					bee.max_velocity -= 50
					await get_tree().create_timer(Global.rain_duration).timeout
					bee.max_velocity += 50
		"stinger":
			buyer.stinger()
		"swarm":
			pass

func flower_spawning():
	flower = FLOWER.instantiate()
	flower.flower_color = ["red", "blue"].pick_random()
	flower.position = Vector2(randf_range(-160, 160), randf_range(-90, 90))
	add_child(flower)

func rain_spawning(target: Player):
	rain = RAIN.instantiate()
	rain.target = target
	add_child(rain)

func _on_flower_spawner_timeout() -> void:
	pass
	#flower_spawning()
	#print('spawn: ', flower.flower_color)


func _on_round_timer_timeout() -> void:
	pass # Replace with function body.
