class_name Shop extends Area2D

@onready var hbox_containter: HBoxContainer = $HBoxContainer




func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hbox_containter.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		await get_tree().create_timer(5.0).timeout
		hbox_containter.visible = false
