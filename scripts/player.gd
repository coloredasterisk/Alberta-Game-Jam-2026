class_name Player extends CharacterBody2D
@export var player_index: int = 1

var speed: int = 100
var direction: Vector2
var acceleration: Vector2
var max_velocity: int = 50

var nectar: int = 0
var current_nectar_capacity: int
var max_nectar_capacity: int

var pollen_counter: int = 0
var max_pollen_counter: int = 4
var money_counter: int = 0

var confused: bool = false
var confused_timer: float = 5.0

var has_stinger: bool = false:
	set(value):
		has_stinger = value
		$Rainbow_Effect.visible = value

@export_enum("red", "blue", "yellow", "green") var player_color: String = "red"
@onready var interaction: Area2D = $Area_Interact
@onready var bee_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var stinger_effect: Sprite2D = $Rainbow_Effect

func _ready():
	
	$animated_outline.modulate = Global.modulate_color[player_color]
	bee_animation.play(player_color)
	current_nectar_capacity = Global.original_max_capacity
	interaction.body_entered.connect(_on_interaction_body_entered)

func movement(delta):
	direction = Input.get_vector("p%d_move_left" % player_index, "p%d_move_right" % player_index, "p%d_move_up" % player_index, "p%d_move_down" % player_index)
	if confused:
		direction = -direction
	
	if direction == Vector2.ZERO:
		acceleration *= 0.6
	else:
		acceleration += direction * speed
	velocity = acceleration * delta * 100
	
	if velocity.length() > max_velocity:
		velocity = velocity.normalized() * max_velocity

func confusion():
	confused = true
	await get_tree().create_timer(Global.confusion_duration).timeout
	confused = false

func pollen():
	for area in interaction.get_overlapping_areas():
		if area is Flower and area.pollen(self):
			break

func interact():
	if Input.is_action_just_pressed("p%d_interact" % player_index):
		for area in interaction.get_overlapping_areas():
			if area.has_method("interact") and area.interact(self):
				break

func stinger():
	has_stinger = true
	var blink = create_tween().set_loops()
	blink.tween_property($Rainbow_Effect, "modulate:a", 0.3, 0.3)
	blink.tween_property($Rainbow_Effect, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(Global.stinger_duration).timeout
	blink.kill()
	has_stinger = false

func get_stung(attacker: Player):
	print(player_color, " bee got stung by ", attacker.player_color)
	nectar = 0
	for hive in get_tree().get_nodes_in_group("hives"):
		if hive.color == player_color:
			global_position = hive.global_position
			break

func _on_interaction_body_entered(body: Node2D) -> void:
	if has_stinger and body is Player and body != self:
		body.get_stung(self)

func animation():
	if direction.x < 0:
		bee_animation.flip_h = true
		stinger_effect.flip_h = true
		stinger_effect.position.x = -2.0

	elif direction.x > 0:
		bee_animation.flip_h = false
		stinger_effect.flip_h = false

		stinger_effect.position.x = 1.0

func _physics_process(delta: float) -> void:
	pollen()
	interact()
	animation()
	movement(delta)
	move_and_slide()
