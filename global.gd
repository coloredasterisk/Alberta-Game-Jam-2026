extends Node


#power up costs
var powerup_costs = {
	"confusion" : 10,
	"speed" : 15,
	"rain" : 25,
	"stinger" : 20,
	"wind" : 25,
	"swarm" : 30,
	"capacity" : 30,
	"collection" : 100,
	"" : 0,
}

var powerup_descriptions = {
	"confusion" : "Invert all rival bees controls for 10s",
	"speed" : "Gain a boost of speed for 15s",
	"rain" : "Slow all rival bees for 10s",
	"stinger" : "For 10s when touching a bee, steal their nectar and fling them",
	"wind" : "You and the hive create a field that pushes bees away for 15s",
	"swarm" : "Steal up to 5 honey from the richest rival bee",
	"capacity" : "Increase your carrying capacity by 1",
	"collection" : "Increase nectar collected from flowers by 1",
	"" : "Move to browse the shop or press interact now to leave"
}

var powerup_icons = {
	"confusion" : preload("res://art/Confusion_Icon.png"),
	"speed" : preload("res://art/Speed_Icon.png"),
	"rain" : preload("res://art/Rain_Powerup_Icon.png"),
	"stinger" : preload("res://art/Stinger_Icon.png"),
	"wind" : preload("res://art/swirl.png"),
	"swarm" : preload("res://art/Swarm_Icon.png"),
	"capacity" : preload("res://art/backpack.png"),
	"collection" : preload("res://art/flower_upgrade.png"),
	"" : null
}

#power up durations
var powerup_durations = {
	"confusion" : 10,
	"speed" : 20,
	"rain" : 10,
	"stinger" : 10,
	"wind" : 15,
}

var original_max_capacity: int = 5
var win_amount = 10
var max_time = 60
var amount_of_players = 1
var local_mode = false

var original_player_speed = 200
var rain_slow_speed = 50
var drag_factor = 0.98
var additive_speed_up = 400
var speed_up_drag_factor = 0.95
var normal_knockback = 100
var stinger_knockback = 1000

var modulate_color = {
"red": Color.RED,
"blue": Color.BLUE,
"yellow": Color.YELLOW,
"green": Color.GREEN,
}

var num_to_art = [
	preload("res://art/numbers/0.png"),
	preload("res://art/numbers/1.png"),
	preload("res://art/numbers/2.png"),
	preload("res://art/numbers/3.png"),
	preload("res://art/numbers/4.png"),
	preload("res://art/numbers/5.png"),
	preload("res://art/numbers/6.png"),
	preload("res://art/numbers/7.png"),
	preload("res://art/numbers/8.png"),
	preload("res://art/numbers/9.png"),
]

enum PlayerSim { AUTHORITY, REPLICA, PREDICTED }
var PLAYER_SPAWN_FROM_CENTER = Vector2(640, 360)
const COLOR_NAMES := ["red", "blue","green","yellow","pink","cyan","purple","orange"]
const CHAR_INPUT = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"


const ACTIONS = {
	
	"p1_move_left":  KEY_A,
	"p1_move_right":  KEY_D,
	"p1_move_up":    KEY_W,
	"p1_move_down":  KEY_S,
	"p1_interact": KEY_E,

	"p2_move_left":  KEY_LEFT,
	"p2_move_right":  KEY_RIGHT,
	"p2_move_up":    KEY_UP,
	"p2_move_down":  KEY_DOWN,
	"p2_interact": KEY_ENTER,

	#p3 has mouse movement
	"p3_interact": MOUSE_BUTTON_LEFT,

	"p4_move_left":  KEY_J,
	"p4_move_right":  KEY_L,
	"p4_move_up":    KEY_I,
	"p4_move_down":  KEY_K,
	"p4_interact":  KEY_O,

}

const SPLIT_SCREEN_DIMENSIONS = [
	[Vector2(640, 360)],
	[Vector2(318, 360), Vector2(318, 360)],
	[Vector2(318, 180), Vector2(318, 180), Vector2(318, 180)],
	[Vector2(318, 180), Vector2(318, 180), Vector2(318, 180), Vector2(318, 180)],
]
	

func _ready() -> void:
	for action in Global.ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev
			if action == "p3_interact":
				ev = InputEventMouseButton.new()
				ev.button_index = Global.ACTIONS[action]
			else:
				ev = InputEventKey.new()
				ev.physical_keycode = Global.ACTIONS[action]
			InputMap.action_add_event(action, ev)


func play_sound(sound, timer = 0) -> void:
	var sfx = preload("res://scenes/one_shot.tscn").instantiate()
	sfx.stream = sound
	if timer > 0:
		sfx.get_node("Timer").wait_time = timer
		sfx.get_node("Timer").autostart = true
	get_node("/root/Main").add_child(sfx)
	
