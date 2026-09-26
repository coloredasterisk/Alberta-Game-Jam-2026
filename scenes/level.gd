extends Node2D

const FLOWER = preload("res://scenes/flower.tscn")
var flower

func flower_spawning():
	flower = FLOWER.instantiate()
	flower.flower_color = ["red", "blue"].pick_random()
	flower.position = Vector2(randf_range(-160, 160), randf_range(-90, 90))
	add_child(flower)

func _on_flower_spawner_timeout() -> void:
	flower_spawning()
	print('spawn: ', flower.flower_color)
