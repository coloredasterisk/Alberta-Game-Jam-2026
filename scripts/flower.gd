class_name Flower extends Area2D

@export_enum("red", "blue", "yellow", "green") var flower_color: String = "red"
enum FlowerState {BULB, GROW, BLOOM}
var current_state
var can_give_pollen: bool = true
var oneshot = preload("res://scenes/one_shot.tscn")
var nectar = [preload("res://music/Picking Up Nectar At Flower 2 (Yum).wav"), preload("res://music/Picking Up Nectar At Flower.wav")]

@onready var bloom_color: AnimatedSprite2D = $Color
@onready var bloom_outline: Sprite2D = $bloom_outline
@onready var bulb_color: AnimatedSprite2D = $bulb_color
@onready var bulb_outline: Sprite2D = $bulb_outline

func _ready():
	current_state = FlowerState.BLOOM
	bloom_outline.modulate = Global.modulate_color[flower_color]
	bloom_color.play(flower_color)
	bulb_outline.modulate = Global.modulate_color[flower_color]
	bulb_color.play(flower_color)

func interact(player) -> bool:
	if player.player_color != flower_color or player.nectar >= player.current_nectar_capacity:
		return false
	if current_state == FlowerState.BLOOM:
		current_state = FlowerState.BULB
		bloom_color.hide()
		bloom_outline.hide()
		bulb_color.show()
		bulb_outline.show()
		$Growing_Cooldown.start()
		print(current_state)
		player.update_capacity(1 * player.collection_multi)
		print("picked! nectar counter: ", player.nectar)
		$Shadow.play("bulb")
		var sfx = oneshot.instantiate()
		sfx.stream = nectar.pick_random()
		add_child(sfx)
	elif current_state == FlowerState.BULB and player.pollen_counter == 4:
		current_state = FlowerState.GROW
		player.pollen_counter = 0
		$Growing_Cooldown.stop()
		$Pollen_Growth_Cooldown.start()
		$Shadow.play("default")
		
		print("you changed to grow ", current_state)
		var sfx = oneshot.instantiate()
		sfx.stream = preload("res://music/Pollenating A Bulb.wav")
		add_child(sfx)
	return true

func pollen(player) -> bool:
	if player.player_color != flower_color:
		return false
	if current_state == FlowerState.BLOOM and can_give_pollen:
		player.pollen_counter += 1
		can_give_pollen = false
		print(player.pollen_counter)
	return true

func _on_growing_cooldown_timeout() -> void:
	current_state = FlowerState.BLOOM
	bloom_color.show()
	bloom_outline.show()
	bulb_color.hide()
	bulb_outline.hide()
	print(current_state, "flower grown")
	$Shadow.play("default")


func _on_pollen_growth_cooldown_timeout() -> void:
	current_state = FlowerState.BLOOM
	bloom_color.show()
	bloom_outline.show()
	bulb_color.hide()
	bulb_outline.hide()
	print(current_state, "flower grown")
	$Shadow.play("default")
	
func disable():
	visible = false
