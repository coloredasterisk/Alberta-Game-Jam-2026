extends Node2D

var color = "red"
@export_enum("leaving", "stealing", "returning") var action = "leaving"
var target_hive_position : Vector2
var home_hive_position : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Outline.modulate = Global.modulate_color[color]
	global_position = home_hive_position
	if home_hive_position.x >= target_hive_position.x:
		flip()
	fly_to_target()

func flip():
	$Sprite2D.flip_h = !$Sprite2D.flip_h
	$Outline.flip_h = !$Outline.flip_h
	
func fly_to_target() -> void:
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", target_hive_position, 1)
	for i in range(0, 9):
		tween.tween_property(self, "global_position", target_hive_position + (Vector2(randf_range(-16, 16), randf_range(-16, 16))), 0.1) 
		tween.tween_callback(flip)
	tween.tween_property(self, "global_position", home_hive_position, 1)
	tween.tween_callback(queue_free)
	tween.play()
