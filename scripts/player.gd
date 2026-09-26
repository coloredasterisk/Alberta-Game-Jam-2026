class_name Player extends CharacterBody2D
@export var player_index = 1

var speed: int = 100
var direction: Vector2

@export_enum("red", "blue") var player_color: String = "red"
@onready var interaction: Area2D = $Area_Interact
@onready var bee_animation: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	pass
			

func movement(delta):
	direction = Input.get_vector("p%d_move_left" % player_index, "p%d_move_right" % player_index, "p%d_move_up" % player_index, "p%d_move_down" % player_index)
	velocity = direction * speed

func interact():
	if Input.is_action_just_pressed("p%d_interact" % player_index):
		print("grap")

func animation():
	if direction.x < 0:
		bee_animation.flip_h = true
	elif direction.x > 0:
		bee_animation.flip_h = false

func _physics_process(delta: float) -> void:
	interact()
	animation()
	movement(delta)
	move_and_slide()
