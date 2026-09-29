class_name Shop extends Area2D


const FLOWER = preload("res://scenes/flower.tscn")
const RAIN = preload("res://scenes/rain_powerup.tscn")

var flower
var rain
var world

func _ready() -> void:
	for item in $Powerups.get_child_count():
		var area = $Powerups.get_child(item).get_child(0)
		if area.has_signal("purchased"):
			area.purchased.connect(_on_powerup_purchased)
		area.powerup_type = Global.powerup_costs.keys()[item]
		area.powerup_cost = Global.powerup_costs.values()[item]
		area.initialize()
	world = get_node("/root/Main/World")

	
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		$Powerups.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		await get_tree().create_timer(5.0).timeout
		$Powerups.visible = false

func hide_rect():
	$Powerups.visible = false
	
	
func rain_spawning(target: Player):
	rain = RAIN.instantiate()
	rain.target = target
	add_child(rain)

func _on_powerup_purchased(type: String, buyer: Player):
	var cost = Global.powerup_costs[type]
	if buyer.money_counter < cost:
		return
	buyer.money_counter -= cost
	
	match type:
		"confusion":
			for bee in world.players:#add players
				if bee != buyer:
					bee.confusion()
		"speed":
			buyer.speed_power()
		"rain":
			for bees in world.players:#add players
				if bees != buyer:
					rain_spawning(bees)
					bees.rain_power()
			Global.play_sound(preload("res://music/Raincloud powerup.wav"), Global.powerup_durations["rain"])
		"stinger":
			buyer.stinger()
		"swarm":
			var all_hives = world.hives
			var own_hive = all_hives.filter(func(h): return h.color == buyer.player_color)[0]
			var enemies = all_hives.filter(func(h): return h.color != buyer.player_color)
			enemies.sort_custom(func(a, b): return a.current_amount > b.current_amount)
			var target = enemies[0]
			var stolen = min(5, target.current_amount)
			target.current_amount -= stolen
			own_hive.current_amount += stolen
			for i in range(0, 5):
				var swarmie = preload("res://scenes/swarm.tscn").instantiate()
				swarmie.home_hive_position = own_hive.global_position
				swarmie.target_hive_position = target.global_position
				swarmie.color = own_hive.color
				add_child(swarmie)
				await get_tree().create_timer(0.1).timeout
				
			print(buyer.player_color, " swarm stole ", stolen, " from ", target.color)
	hide_rect()
