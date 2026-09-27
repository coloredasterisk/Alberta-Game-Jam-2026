extends Node2D

var target: Node2D
var offset := Vector2(0, -20)

func _ready():
	await get_tree().create_timer(Global.rain_duration).timeout
	queue_free()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position + offset
