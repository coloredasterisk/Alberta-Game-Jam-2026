extends Node2D


var bee_spawn_timer = 0.5
var bee_timer = bee_spawn_timer
var money_spawn_timer = 0.05
var money_timer = money_spawn_timer
var paused = false

func _process(delta: float) -> void:
	if paused: return
	bee_timer -= delta
	money_timer -= delta
	if bee_timer <= 0:
		bee_timer = bee_spawn_timer
		var bee = preload("res://scenes/splash_bee.tscn").instantiate()
		bee.global_position = Vector2(-15, randi_range(15, 360))
		$Bees.add_child(bee)
	elif money_timer <= 0:
		money_timer = money_spawn_timer
		var oney = [preload("res://scenes/splash_honey.tscn"), preload("res://scenes/splash_money.tscn")].pick_random().instantiate()
		oney.global_position = Vector2(randi_range(0, 640), -10)
		$Objects.add_child(oney)
		
func stop():
	paused = true


func _on_destroyer_body_entered(body: Node2D) -> void:
	body.queue_free()
