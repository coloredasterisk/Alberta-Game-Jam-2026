class_name Hive extends Node2D
var current_amount = 0
var overlapping_players = {}

@export var color = "red"

func _ready() -> void:
	$Sprite.animation = color
	
func interact() -> void:
	for player in overlapping_players.keys():
		if player.color == color and player.nectar > 1:
			current_amount += 1
			player.nectar -= 1
		elif player.color != color and player.nectar < player.max_nectar:
			current_amount -= 1
			player.nectar += 1


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		overlapping_players[body] = 0


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		overlapping_players.erase(body)
		
