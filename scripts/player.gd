class_name Player extends CharacterBody2D
@export var player_index = 1

var speed: int = 100
var direction: Vector2

var nectar: int = 0
var current_nectar_capacity: int
var max_nectar_capacity: int

var pollen_counter: int = 0
var money_counter: int = 0

var confused: bool = false
var confused_timer: float = 5.0

@export_enum("red", "blue") var player_color: String = "red"
@onready var interaction: Area2D = $Area_Interact
@onready var bee_animation: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	bee_animation.play(player_color)
	current_nectar_capacity = Global.original_max_capacity


func movement(delta):
	direction = Input.get_vector("p%d_move_left" % player_index, "p%d_move_right" % player_index, "p%d_move_up" % player_index, "p%d_move_down" % player_index)
	velocity = direction * speed
	if confused:
		direction = -direction

func confusion():
	confused = true
	await get_tree().create_timer(Global.confusion_duration).timeout
	confused = false

func rain():
	pass

#func pollen():
	#for area in interaction.get_overlapping_areas():
		#if area is Flower and area.pollen(self):
			#print("pollen!", pollen_counter)
			#break

func interact():
	if Input.is_action_just_pressed("p%d_interact" % player_index):
		for area in interaction.get_overlapping_areas():
			if area.has_method("interact") and area.interact(self):
				break


func animation():
	if direction.x < 0:
		bee_animation.flip_h = true
	elif direction.x > 0:
		bee_animation.flip_h = false


func _physics_process(delta: float) -> void:
	#pollen()
	interact()
	animation()
	movement(delta)
	move_and_slide()
