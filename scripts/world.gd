extends Panel


const POWER_EFFECT = preload("res://scripts/power_effect_2d.gd")

var round_time = 120.0
var timer = 120.0
var playing = false
var round_over = false
var hives = []
var players = []

#FOR SHOP
@onready var stinger_rect: TextureRect = $Player1/SubViewport/Map1/Shop/HBoxContainer/Stinger
@onready var rain_rect: TextureRect = $Player1/SubViewport/Map1/Shop/HBoxContainer/Rain
@onready var swarm_rect: TextureRect = $Player1/SubViewport/Map1/Shop/HBoxContainer/Swarm
@onready var speed_rect: TextureRect = $Player1/SubViewport/Map1/Shop/HBoxContainer/Speed
@onready var confusion_rect: TextureRect = $Player1/SubViewport/Map1/Shop/HBoxContainer/Confusion



func _ready() -> void:
	# get 2D scene (= 2D world) to share
	var world = $Player1/SubViewport.find_world_2d()
	# give it to render to the viewport of Player 2
	$Player2/SubViewport.world_2d = world
	$Player3/SubViewport.world_2d = world
	$Player4/SubViewport.world_2d = world
	
	players = [
		$Player1/SubViewport/Player,
		$Player2/SubViewport/Player,
		$Player3/SubViewport/Player,
		$Player4/SubViewport/Player,
	]
	get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").max_value = round_time
	get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").value = round_time
	
	for item in $Player1/SubViewport/Map1/Shop/HBoxContainer.get_children():
		var area = item.get_child(0)
		if area.has_signal("purchased"):
			area.purchased.connect(_on_powerup_purchased)

func _process(delta: float) -> void:
	if playing:
		timer -= delta
		if timer <= 0:
			playing = false
			timer = 0
			_on_round_timer_timeout()
		get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").value = timer
		get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar/TimeText").text = str(int(timer))
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("p1_interact") and round_over:
		get_tree().reload_current_scene()

func _start_game() -> void:
	
	hives = $Player1/SubViewport/Map1/Hives.get_children()
	
	for i in range(hives.size()):
		players[i].global_position = hives[i].global_position
	
	get_node("../BackgroundMusic").play()
	get_node("../CanvasLayer/321Go").visible = true
	get_node("../CanvasLayer/321Go").play()

func _on_start_countdown_timeout() -> void:
	playing = true
	get_node("../CanvasLayer/321Go").visible = false
	for player in players:
		player.enable()
		
func _on_round_timer_timeout() -> void:
	#var hives = get_tree().get_nodes_in_group("hives")
	#hives.sort_custom(func(a, b): return a.current_amount > b.current_amount)

	var place := 0
	for i in hives.size():
		# only move down a place if this hive has less than the one before it
		if i == 0 or hives[i].current_amount < hives[i - 1].current_amount:
			place = i + 1
		var result = place_name(place)
		var score =  hives[i].current_amount
		get_node("/root/Main/World").get_child(i).get_node("SubViewport/BG/Placement").update_display(result, score)
	get_tree().paused = true
	round_over = true

func place_name(place: int) -> String:
	return ["1st", "2nd", "3rd", "4th"][place - 1]
	
	
const FLOWER = preload("res://scenes/flower.tscn")
const RAIN = preload("res://scenes/rain_powerup.tscn")
var flower
var rain


func _on_powerup_purchased(type: String, buyer: Player):
	match type:
		"confusion":
			if buyer.money_counter >= Global.confusion_cost: 
				buyer.money_counter -= Global.confusion_cost
				confusion_rect.visible = false
				for bee in players:#add players
					if bee != buyer:
						bee.confusion()
				await get_tree().create_timer(Global.confusion_duration).timeout
				confusion_rect.visible = true
		"speed":
			if buyer.money_counter >= Global.speed_cost: 
				buyer.money_counter -= Global.speed_cost
				speed_rect.visible = false
				buyer.speed_power()
				await get_tree().create_timer(Global.speed_duration).timeout
				speed_rect.visible = true
		"rain":
			if buyer.money_counter >= Global.rain_cost: 
				buyer.money_counter -= Global.rain_cost
				rain_rect.visible = false
				for bees in players:#add players
					if bees != buyer:
						rain_spawning(bees)
						bees.rain_power()
				await get_tree().create_timer(Global.rain_duration).timeout
				rain_rect.visible = true
		"stinger":
			if buyer.money_counter >= Global.stinger_cost: 
				buyer.money_counter -= Global.stinger_cost
				stinger_rect.visible = false
				buyer.stinger()
				await get_tree().create_timer(Global.stinger_duration).timeout
				stinger_rect.visible = true
		"swarm":
			if buyer.money_counter >= Global.swarm_cost:
				buyer.money_counter -= Global.swarm_cost
				var all_hives = hives
				var own_hive = all_hives.filter(func(h): return h.color == buyer.player_color)[0]
				var enemies = all_hives.filter(func(h): return h.color != buyer.player_color)
				enemies.sort_custom(func(a, b): return a.current_amount > b.current_amount)
				var target = enemies[0]
				var stolen = min(5, target.current_amount)
				target.current_amount -= stolen
				own_hive.current_amount += stolen
				POWER_EFFECT.spawn(target, "swarm", maxf(1.5, Global.swarm_cooldown_duration))
				swarm_rect.visible = false
				await get_tree().create_timer(Global.swarm_cooldown_duration).timeout
				swarm_rect.visible = true
				print(buyer.player_color, " swarm stole ", stolen, " from ", target.color)

func flower_spawning():
	flower = FLOWER.instantiate()
	flower.flower_color = ["red", "blue", "green", "yellow"].pick_random()
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
