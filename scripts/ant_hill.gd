class_name AntHill extends Area2D

var ant_counter: int = 1

@onready var bar: Sprite2D = $TextureProgressBar/progress_bar
@onready var progress_bar: TextureProgressBar = $TextureProgressBar

var active := false
var move_dir := 1
var bar_speed: Array = [60, 75, 80, 40]
var current_speed: float

func _ready() -> void:
	bar.position.x = 1

func interact(player) -> bool:
	if not active:
		if ant_counter <= 0:
			return false
		start()
	else:
		var hit = check()
		stop()
		print("stopped at ", bar.position.x, " hit: ", hit)
		if hit:
			ant_counter -= 1
			player.money_counter += 5
			print("goodjob! ants left: ", ant_counter)
		else:
			player.money_counter -= 5
			player.send_home()
	return true

func start():
	active = true
	progress_bar.visible = true
	bar.position.x = 1
	move_dir = 1
	current_speed = bar_speed.pick_random()

func check() -> bool:
	return bar.position.x > 16 and bar.position.x < 22

func stop() -> void:
	active = false
	progress_bar.visible = false

func back_and_forth(delta):
	bar.position.x += move_dir * current_speed * delta
	if bar.position.x >= 38:
		bar.position.x = 38
		move_dir = -1
	elif bar.position.x <= 0:
		bar.position.x = 0
		move_dir = 1

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		stop()

func _physics_process(delta: float) -> void:
	if active:
		back_and_forth(delta)


func _on_ant_spawner_timeout() -> void:
	ant_counter += 1
