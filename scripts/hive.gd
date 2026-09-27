class_name Hive extends Area2D
var current_amount = 0

@export_enum("red","blue","yellow","green") var color: String = "red"
var oneshot = preload("res://scenes/one_shot.tscn")

func _ready() -> void:
	$Sprite.animation = color
	$outline.modulate = Global.modulate_color[color]
	add_to_group("hives")

func interact(player) -> bool:
	print("hive interact called by ", player.player_color, " bee with ", player.nectar, " nectar")
	if player.player_color == color:
		# own hive: deposit
		if player.nectar <= 0:
			return false
		current_amount += player.nectar
		player.nectar = 0
		var sfx = oneshot.instantiate()
		sfx.stream = preload("res://Dropping Nectar At Hive.wav")
		add_child(sfx)
	else:
		# rival hive: steal
		if current_amount <= 0 or player.nectar >= player.current_nectar_capacity:
			return false
		current_amount -= 1
		player.nectar += 1
	print(color, " hive: ", current_amount, " | bee nectar: ", player.nectar)
	return true
