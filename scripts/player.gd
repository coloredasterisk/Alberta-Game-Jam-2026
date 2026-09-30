class_name Player extends CharacterBody2D

@export var player_index: int = 1

var speed: int = Global.original_player_speed
var direction: Vector2
var acceleration: Vector2
var drag_factor : float = Global.drag_factor
var max_velocity: int = 50
var touch: TouchControls

## Non-zero while a phone controller (or, on the host, a remote online guest) is driving this
## player; overrides the keyboard input for movement (see main.gd).
var phone_id: int = 0
var username := ""
var external_stick := Vector2.ZERO

var nectar: int = 0
var current_nectar_capacity: int
var max_nectar_capacity: int
var collection_multi : int = 1

var pollen_counter: int = 0
var max_pollen_counter: int = 4
var money_counter: int = 100

var confused: bool = false
var rain: bool = false
var wind: bool = false
var capacity_tween
var shop = null
var shopping = false
var rain_speed = 0

var sound_list = {
	"stinger" : preload("res://music/Rainbow Stinger Powerup.wav"),
	"confusion" : preload("res://music/Confusion Powerup.wav"),
	"speed" : preload("res://music/Super Speed Powerup.wav"),
}

var has_stinger: bool = false:
	set(value):
		has_stinger = value
		stinger_effect.visible = value

@export_enum("red", "blue", "yellow", "green") var player_color: String = "red"

@onready var interaction: Area2D = $Area_Interact
@onready var bee_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var stinger_effect: Sprite2D = $animated_outline/Rainbow_Effect
@onready var bee_outline_animation: AnimatedSprite2D = $animated_outline



func _ready():
	$AnimatedSprite2D/Shadow.play()
	bee_outline_animation.self_modulate = Global.modulate_color[player_color]
	bee_animation.play(player_color)
	bee_outline_animation.play(player_color)
	
	current_nectar_capacity = Global.original_max_capacity
	interaction.body_entered.connect(_on_interaction_body_entered)
	disable()

func disable():
	set_process(false)
	set_physics_process(false)
	$collider.disabled = true
	visible = false

func enable():
	set_process(true)
	set_physics_process(true)
	$collider.disabled = false
	visible = true
	$Buzzing.play()

func update_capacity(num) -> void:
	nectar += num
	$Capacity.push_font_size(8)
	$Capacity.self_modulate = Color.WHITE
	if capacity_tween:
		capacity_tween.kill()
	if nectar >= current_nectar_capacity:
		$Capacity.text = "Full!"
		$Capacity.modulate = Color.RED
		
	else:
		$Capacity.text = str(nectar) +"/"+ str(current_nectar_capacity)
		$Capacity.modulate = Color.WHITE
		capacity_tween = get_tree().create_tween()
		capacity_tween.set_ease(Tween.EASE_IN_OUT)
		capacity_tween.tween_property($Capacity, "self_modulate", Color.TRANSPARENT, 5.0)
		capacity_tween.play()
		
func update_money(new_amount) -> void:
	if capacity_tween:
		capacity_tween.kill()
	var display = "[font_size=" + str(8 + (sqrt(abs(new_amount)) * 2)) + "]"
	if new_amount >= 0:
		display += "+"
		$Capacity.self_modulate = Color.GREEN
	else:
		$Capacity.self_modulate = Color.RED
	$Capacity.text = display + str(new_amount)
	capacity_tween = get_tree().create_tween()
	capacity_tween.set_ease(Tween.EASE_IN_OUT)
	capacity_tween.tween_property($Capacity, "self_modulate", Color.TRANSPARENT, 5.0)
	capacity_tween.play()
	
func movement(delta):

	if phone_id > 0:
		direction = external_stick
	else:
		if player_index == 3: #mouse input
			direction = (get_global_mouse_position() - global_position).normalized()
		else:
			direction = Input.get_vector("p%d_move_left" % player_index, "p%d_move_right" % player_index, "p%d_move_up" % player_index, "p%d_move_down" % player_index)
	if shopping and shop != null:
		shop.move_selection(direction.round(), self)
		acceleration = Vector2.ZERO
		velocity = Vector2.ZERO
		return
	
	if confused:
		direction = -direction
	if speed > Global.original_player_speed:
		$SpeedParticles.direction = -direction
	acceleration = direction * (speed + rain_speed)
	velocity = acceleration * delta + (velocity * drag_factor)

func confusion():
	confused = true
	$Birds.visible = true
	play_sound("confusion")
	$ConfusionTimer.start(Global.powerup_durations["confusion"])
	
func end_confusion():
	confused = false
	$Birds.visible = false

func rain_power():
	rain = true
	$Rain.visible = true
	rain_speed -= Global.rain_slow_speed
	get_tree().create_timer(Global.powerup_durations["rain"]).timeout.connect(end_rain)

func end_rain():
	$Rain.visible = false
	rain_speed += Global.rain_slow_speed
	rain = false
	
func speed_power():
	speed += Global.additive_speed_up
	drag_factor = Global.speed_up_drag_factor
	$SpeedParticles.visible = true
	play_sound("speed")
	get_tree().create_timer(Global.powerup_durations["speed"]).timeout.connect(end_speed)
	
func end_speed():
	drag_factor = Global.drag_factor
	speed -= Global.additive_speed_up
	$SpeedParticles.visible = false
	
func add_capacity():
	current_nectar_capacity += 1
	update_capacity(0)
	
func add_collection():
	collection_multi += 1
	var loyal = preload("res://scenes/loyal_swarm.tscn").instantiate()
	loyal.color = player_color
	loyal.follow_parent = self
	get_parent().add_child(loyal)
	
func spawn_wind():
	wind = true
	var windarea = preload("res://scenes/wind_area.tscn").instantiate()
	windarea.color = player_color
	windarea.enable(Global.powerup_durations["wind"])
	add_child(windarea)
	
func end_wind():
	wind = false

func pollen():
	for area in interaction.get_overlapping_areas():
		if area is Flower and area.pollen(self):
			break

func interact():
	if Input.is_action_just_pressed("p%d_interact" % player_index):
		if shop != null:
			shop.interact(self)
		else:
			for area in interaction.get_overlapping_areas():
				apply_interact(true)

func apply_interact(override = false):
	if shop != null and not override:
		shop.interact(self)
	else:
		for area in interaction.get_overlapping_areas():
			if area.has_method("interact") and area.interact(self):
				break

func stinger():
	has_stinger = true
	$StingerIcon.visible = true
	var blink = create_tween().set_loops()
	blink.tween_property(stinger_effect, "modulate:a", 0.3, 0.2)
	blink.tween_property(stinger_effect, "modulate:a", 1.0, 0.2)
	blink.tween_property($animated_outline/Rainbow_Effect, "modulate:a", 0.3, 0.2)
	blink.tween_property($animated_outline/Rainbow_Effect, "modulate:a", 1.0, 0.2)
	get_tree().create_timer(Global.powerup_durations["stinger"]).timeout.connect(end_stinger.bind(blink))
	play_sound("stinger")
	
func end_stinger(blink):
	blink.kill()
	has_stinger = false
	$StingerIcon.visible = false

func get_stung(attacker: Player):
	print(player_color, " bee got stung by ", attacker.player_color)
	attacker.update_capacity(nectar)
	update_capacity(-nectar)
	velocity += attacker.global_position.direction_to(global_position) * Global.stinger_knockback

func send_home():
	for hive in get_tree().get_nodes_in_group("hives"):
		if hive.color == player_color:
			update_capacity(-nectar)
			global_position = hive.global_position
			break

func _on_interaction_body_entered(body: Node2D) -> void:
	if body is Player and body != self:
		if has_stinger:
			body.get_stung(self)
		else:
			velocity += body.global_position.direction_to(global_position) * Global.normal_knockback
func animation():
	if bee_animation.frame == 1:
		stinger_effect.position.y = 2
		$StingerIcon.position.y = 2
	else:
		stinger_effect.position.y = 1
		$StingerIcon.position.y = 1
	if direction.x < 0:
		bee_animation.flip_h = true
		$animated_outline.flip_h = true
		stinger_effect.flip_h = true
		stinger_effect.position.x = -1.0
		$AnimatedSprite2D/Shadow.flip_h = true
		$StingerIcon.flip_h = false
		$StingerIcon.position.x = 6
	elif direction.x > 0:
		bee_animation.flip_h = false
		$animated_outline.flip_h = false
		stinger_effect.flip_h = false
		$AnimatedSprite2D/Shadow.flip_h = false
		stinger_effect.position.x = 2.0
		$StingerIcon.flip_h = true
		$StingerIcon.position.x = -6

func _physics_process(delta: float) -> void:
	pollen()
	interact()
	animation()
	movement(delta)
	move_and_slide()
	
func play_sound(sound_name):
	Global.play_sound(sound_list[sound_name], Global.powerup_durations[sound_name])
