extends Node2D

const FLOWER = preload("res://scenes/flower.tscn")
const RAIN = preload("res://scenes/rain_powerup.tscn")
var flower
var rain

#FOR SHOP
@onready var stinger_rect: TextureRect = $Shop/HBoxContainer/Stinger
@onready var rain_rect: TextureRect = $Shop/HBoxContainer/Rain
@onready var swarm_rect: TextureRect = $Shop/HBoxContainer/Swarm
@onready var speed_rect: TextureRect = $Shop/HBoxContainer/Speed
@onready var confusion_rect: TextureRect = $Shop/HBoxContainer/Confusion

func _ready():
	for item in $Shop/HBoxContainer.get_children():
		var areas = item.get_child(0)
		if areas.has_signal("purchased"):
			areas.purchased.connect(_on_powerup_purchased)
	$Red_Bee.enable()
	$Blue_Bee.enable()
	$Yellow_Bee.enable()
	$Green_Bee.enable()

func _on_powerup_purchased(type: String, buyer: Player):
	print()
	match type:
		
		"confusion":
			if buyer.money_counter >= Global.confusion_cost: 
				buyer.money_counter -= Global.confusion_cost
				confusion_rect.visible = false
				for bee in [$Red_Bee, $Blue_Bee, $Yellow_Bee,  $Green_Bee]:#add players
					if bee != buyer:
						bee.confusion()
		"speed":
			if buyer.money_counter >= Global.speed_cost: 
				buyer.money_counter -= Global.speed_cost
				speed_rect.visible = false
				buyer.speed += 100
				await get_tree().create_timer(Global.speed_duration).timeout
				speed_rect.visible = true
				buyer.speed -= 100
		"rain":
			if buyer.money_counter >= Global.rain_cost: 
				buyer.money_counter -= Global.rain_cost
				rain_rect.visible = false
				for bees in [$Red_Bee, $Blue_Bee, $Yellow_Bee,  $Green_Bee]:#add players
					if bees != buyer:
						rain_spawning(bees)
						bees.rain_power()
		"stinger":
			if buyer.money_counter >= Global.stinger_cost: 
				buyer.money_counter -= Global.stinger_cost
				stinger_rect.visible = false
				buyer.stinger()
		"swarm":
			if buyer.money_counter >= Global.swarm_cost:
				buyer.money_counter -= Global.swarm_cost
				var all_hives = [$Red_Hive, $Blue_Hive, $Yellow_Hive, $Green_Hive]
				var own_hive = all_hives.filter(func(h): return h.color == buyer.player_color)[0]
				var enemies = all_hives.filter(func(h): return h.color != buyer.player_color)
				enemies.sort_custom(func(a, b): return a.current_amount > b.current_amount)
				var target = enemies[0]
				var stolen = min(5, target.current_amount)
				target.current_amount -= stolen
				own_hive.current_amount += stolen
				$Shop/HBoxContainer/Swarm.visible = false
				await get_tree().create_timer(Global.swarm_cooldown_duration).timeout
				$Shop/HBoxContainer/Swarm.visible = true
				print(buyer.player_color, " swarm stole ", stolen, " from ", target.color)

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
	var hives = get_tree().get_nodes_in_group("hives")
	hives.sort_custom(func(a, b): return a.current_amount > b.current_amount)

	var place := 0
	for i in hives.size():
		# only move down a place if this hive has less than the one before it
		if i == 0 or hives[i].current_amount < hives[i - 1].current_amount:
			place = i + 1
		print(place_name(place), ": ", hives[i].color, " with ", hives[i].current_amount, " nectar")

	get_tree().paused = true

func place_name(place: int) -> String:
	return ["1st", "2nd", "3rd", "4th"][place - 1]
