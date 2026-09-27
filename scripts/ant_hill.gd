class_name AntHill extends Area2D


func interact(player) -> bool:
	print('qweuhwqe')
	start()
	return true

func start() -> void:
	pass
func stop() -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	stop()
