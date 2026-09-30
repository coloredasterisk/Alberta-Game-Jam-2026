extends CharacterBody2D

var color = "red"
var follow_parent : CharacterBody2D
var acceleration := Vector2(0,0)
var speed = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Outline.modulate = Global.modulate_color[color]
	global_position = follow_parent.global_position

func flip(is_flip : bool):
	$Sprite2D.flip_h = is_flip
	$Outline.flip_h = is_flip
	
func _process(delta: float) -> void:
	
	var direction = Vector2.ZERO
	if global_position.distance_squared_to(follow_parent.global_position) > 300:
		direction = global_position.direction_to(follow_parent.global_position).rotated(0.1)
	acceleration = direction * speed
	velocity = acceleration * delta + (velocity * 0.98)
	
	if velocity.x < 0:
		flip(true)
	elif velocity.x > 0:
		flip(false)
	move_and_slide()
	
