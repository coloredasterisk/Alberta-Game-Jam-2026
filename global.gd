extends Node


#power up costs
var stinger_cost: int = 20
var rain_cost: int = 15
var speed_cost: int = 15
var confusion_cost: int = 10
var swarm_cost: int = 30

#power up durations
var stinger_duration: float = 10.0
var rain_duration: float = 10.0
var speed_duration: float = 20.0
var confusion_duration: float = 5.0
var swarm_cooldown_duration: float = 1

var original_max_capacity: int = 5
var win_amount = 10
var max_time = 60
var amount_of_players = 1
var local_mode = false

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
