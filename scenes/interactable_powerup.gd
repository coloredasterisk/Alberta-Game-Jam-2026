extends Node2D


@export var powerup_type = "rain"
@export var powerup_cost := 5


func _ready() -> void:
	initialize()
	
func buy_powerup() -> void:
	pass
	
func initialize():
	$AnimatedSprite2D.animation = powerup_type
	$Cost/NumberDisplay.update_display(powerup_cost)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		$Cost.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		$Cost.visible = false
