class_name AntHill extends Area2D

var ant_counter: int = 1
var combo = 0

@onready var bar: Sprite2D = $TextureProgressBar/progress_bar
@onready var progress_bar: TextureProgressBar = $TextureProgressBar

var active := false
var move_dir := 1
var bar_speed: Array = [20, 30, 40, 50, 60, 70, 80, 90, 100]
var penalty : Array = [5,5,4,4,4,3,3,2]
var current_speed: float

func _ready() -> void:
	bar.position.x = 1
	update_display()

func interact(player) -> bool:
	player.acceleration = Vector2.ZERO
	player.velocity = Vector2.ZERO
	if not active:
		#if ant_counter <= 0:
		#	return false
		start()
	else:
		var hit = check()
		stop()
		print("stopped at ", bar.position.x, " hit: ", hit)
		var added : int = 0
		if hit:
			#ant_counter -= 1
			added = ((1 + combo) * 5)
			player.money_counter += added
			print("goodjob! ants left: ", ant_counter)
			combo += 1
			$Ant.emitting = true
		else:
			added -= (player.money_counter / penalty[min(combo, 7)])
			player.money_counter += added
			player.send_home()
			combo = 0
		player.update_money(added)
	update_display()
	return true

func update_display():
	$MoneyDisplay/RichTextLabel.text = str((1 + combo) * 5)

func start():
	active = true
	progress_bar.visible = true
	bar.position.x = 1
	move_dir = 1
	current_speed = bar_speed[min(combo, 8)]

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
		combo = 0
		update_display()
		stop()

func _physics_process(delta: float) -> void:
	if active:
		back_and_forth(delta)


func _on_ant_spawner_timeout() -> void:
	ant_counter += 1
