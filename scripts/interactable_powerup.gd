extends Node2D

signal purchased(powerup_type: String, buyer: Player)
@export var powerup_type = "confusion"
@export var powerup_cost := 5


func _ready() -> void:
	initialize()
	
func interact(player) -> bool:
	if not is_visible_in_tree():
		return false
	purchased.emit(powerup_type, player)
	
	print("bought ", powerup_type)
	return true

func initialize():
	$AnimatedSprite2D.animation = powerup_type
	$Cost/NumberDisplay.update_display(powerup_cost)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		$Cost.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		$Cost.visible = false
