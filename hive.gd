extends Node2D

var current_ammount = 0


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_meta("player"):
		body.start_deposit()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_meta("player"):
		body.cancel_deposit()
