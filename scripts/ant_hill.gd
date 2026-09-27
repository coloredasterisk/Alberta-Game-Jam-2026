class_name AntHill extends Area2D

@onready var bar: Sprite2D = $TextureProgressBar/progress_bar
var move_dir: int
var bar_speed: int = 100

func interact(player) -> bool:
	pass
	start()
	return true

func _ready() -> void:
	bar.position.x = 0

func start():
	bar.position.x = 0
	move_dir = 1

func back_and_forth(delta):
	bar.position.x += move_dir * bar_speed * delta
	if bar.position.x > 38:
		bar.position.x = 38
		move_dir = -1
	elif bar.position.x <= 0:
		bar.position.x = 0
		move_dir = 1


func stop() -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	stop()

func _physics_process(delta: float) -> void:
	start()
	back_and_forth(delta)
	
