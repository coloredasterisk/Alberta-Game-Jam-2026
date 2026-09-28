class_name Player extends CharacterBody2D
const POWER_EFFECT = preload("res://scripts/power_effect_2d.gd")
@export var player_index: int = 1

var speed: int = 200
var direction: Vector2
var acceleration: Vector2
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

var pollen_counter: int = 0
var max_pollen_counter: int = 4
var money_counter: int = 100

var confused: bool = false
var rain: bool = false
var capacity_tween

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
		
func movement(delta):

	if phone_id > 0:
		direction = external_stick
	else:
		if player_index == 3:
			direction = (get_global_mouse_position() - global_position).normalized()
		else:
			direction = Input.get_vector("p%d_move_left" % player_index, "p%d_move_right" % player_index, "p%d_move_up" % player_index, "p%d_move_down" % player_index)
	if confused:
		direction = -direction
	acceleration = direction * speed
	velocity = acceleration * delta + (velocity * 0.98)
	
	#if velocity.length() > max_velocity:
	#	velocity = velocity.normalized() * max_velocity

func confusion():
	confused = true
	POWER_EFFECT.spawn(self, "confusion", Global.confusion_duration)
	var sfx = preload("res://scenes/one_shot.tscn").instantiate()
	sfx.stream = preload("res://Confusion Powerup.wav")
	add_child(sfx)
	await get_tree().create_timer(Global.confusion_duration).timeout
	sfx.queue_free()
	confused = false

func rain_power():
	rain = true
	speed -= 150
	POWER_EFFECT.spawn(self, "rain", Global.rain_duration)
	await get_tree().create_timer(Global.rain_duration).timeout
	speed += 150
	rain = false

func speed_power():
	speed += 100
	POWER_EFFECT.spawn(self, "speed", Global.speed_duration)
	var sfx = preload("res://scenes/one_shot.tscn").instantiate()
	sfx.stream = preload("res://Super Speed Powerup.wav")
	add_child(sfx)
	await get_tree().create_timer(Global.speed_duration).timeout
	sfx.queue_free()
	speed -= 100

func pollen():
	for area in interaction.get_overlapping_areas():
		if area is Flower and area.pollen(self):
			break

func interact(is_phone = false):
	print(is_phone)
	if Input.is_action_just_pressed("p%d_interact" % player_index):
		for area in interaction.get_overlapping_areas():
			if area.has_method("interact") and area.interact(self):
				break


func stinger():
	has_stinger = true
	POWER_EFFECT.spawn(self, "stinger", Global.stinger_duration)
	var blink = create_tween().set_loops()
	blink.tween_property(stinger_effect, "modulate:a", 0.3, 0.3)
	blink.tween_property(stinger_effect, "modulate:a", 1.0, 0.3)
	blink.tween_property($animated_outline/Rainbow_Effect, "modulate:a", 0.3, 0.3)
	blink.tween_property($animated_outline/Rainbow_Effect, "modulate:a", 1.0, 0.3)
	var sfx = preload("res://scenes/one_shot.tscn").instantiate()
	sfx.stream = preload("res://Rainbow Stinger Powerup.wav")
	add_child(sfx)
	await get_tree().create_timer(Global.stinger_duration).timeout
	blink.kill()
	sfx.queue_free()
	has_stinger = false

func get_stung(attacker: Player):
	print(player_color, " bee got stung by ", attacker.player_color)
	nectar = 0
	send_home()

func send_home():
	for hive in get_tree().get_nodes_in_group("hives"):
		if hive.color == player_color:
			update_capacity(-nectar)
			global_position = hive.global_position
			break

func _on_interaction_body_entered(body: Node2D) -> void:
	if has_stinger and body is Player and body != self:
		body.get_stung(self)

func animation():
	if bee_animation.frame == 1:
		stinger_effect.position.y = 2
	else:
		stinger_effect.position.y = 1
	if direction.x < 0:
		bee_animation.flip_h = true
		$animated_outline.flip_h = true
		stinger_effect.flip_h = true
		stinger_effect.position.x = -1.0
		$AnimatedSprite2D/Shadow.flip_h = true
	elif direction.x > 0:
		bee_animation.flip_h = false
		$animated_outline.flip_h = false
		stinger_effect.flip_h = false
		$AnimatedSprite2D/Shadow.flip_h = false
		stinger_effect.position.x = 2.0

func _physics_process(delta: float) -> void:
	pollen()
	interact()
	animation()
	movement(delta)
	move_and_slide()
