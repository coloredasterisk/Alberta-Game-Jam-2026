class_name Shop extends Area2D

@onready var stinger: Area2D = $Stinger
@onready var rain: Area2D = $Rain
@onready var swarm: Area2D = $Swarm
@onready var speed: Area2D = $Speed
@onready var confusion: Area2D = $Confusion




func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		stinger.visible = true
		rain.visible = true
		swarm.visible = true
		speed.visible = true
		confusion.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		await get_tree().create_timer(5.0).timeout
		stinger.visible = false
		rain.visible = false
		swarm.visible = false
		speed.visible = false
		confusion.visible = false
