class_name Shop extends Area2D


const FLOWER = preload("res://scenes/flower.tscn")
const RAIN = preload("res://scenes/rain_powerup.tscn")

var flower
var rain
var world

var shop_grid = [
	["collection", "confusion", "speed"],
	["capacity", "", "rain"],
	["swarm", "wind", "stinger"],
]
var grid_position = Vector2(1,1)
var direction_to_vector = {
	"left": Vector2(-1,0),
	"right":Vector2(1,0),
	"up":Vector2(0,-1),
	"down":Vector2(0,1),
}

func _ready() -> void:
	for item in $Powerups.get_child_count():
		var area = $Powerups.get_child(item).get_child(0)
		if area.has_signal("purchased"):
			area.purchased.connect(_on_powerup_purchased)
		area.powerup_type = Global.powerup_costs.keys()[item]
		area.powerup_cost = Global.powerup_costs.values()[item]
		area.initialize()
	world = get_node("/root/Main/World")

func interact(player) -> void:
	if player.shopping:
		_on_powerup_purchased(shop_grid[grid_position.y][grid_position.x], player)
	else:
		player.shopping = true
		player.get_node("../BG/ShopMenu").visible = true
	

func move_selection(direction, player):
	if player.shopping:
		grid_position = direction.clamp(Vector2(-1,-1), Vector2(1,1))
		grid_position += Vector2.ONE
		player.get_node("../BG/ShopMenu").update_item(shop_grid[grid_position.y][grid_position.x], player.money_counter)
		
		
		
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.shop = self


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if not body.shopping:
			body.shop = null
		
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
			var enemies = all_hives.filter(func(h): return h.color != buyer.player_color and h.playing)
			enemies.sort_custom(func(a, b): return a.current_amount > b.current_amount)
			var index = 0
			var target = enemies[index]
			while target.has_wind:
				index += 1
				if index >= enemies.size():
					index = -1
					break
				else:
					target = enemies[index]
			if index != -1:
				var stolen = min(5, target.current_amount)
				target.current_amount -= stolen
				own_hive.current_amount += stolen
				print(buyer.player_color, " swarm stole ", stolen, " from ", target.color)
				
			for i in range(0, 5):
				var swarmie = preload("res://scenes/swarm.tscn").instantiate()
				swarmie.home_hive_position = own_hive.global_position
				if index == -1:
					swarmie.target_hive_position = Vector2(randi_range(-160, 160), randi_range(-160, 160))
				else:
					swarmie.target_hive_position = target.global_position
				swarmie.color = own_hive.color
				add_child(swarmie)
				await get_tree().create_timer(0.1).timeout
				
		"capacity":
			buyer.add_capacity()
		"collection":
			buyer.add_collection()
		"wind":
			var own_hive = world.hives.filter(func(h): return h.color == buyer.player_color)[0]
			own_hive.spawn_wind(Global.powerup_durations["wind"])
			buyer.spawn_wind()
		"":
			buyer.shopping = false
			buyer.get_node("../BG/ShopMenu").visible = false
			if not (buyer in get_overlapping_bodies()):
				buyer.shop = null
	hide_rect()
