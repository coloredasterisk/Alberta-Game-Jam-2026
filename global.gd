extends Node


var win_amount = 10
var max_time = 60

var num_to_art = [
	
]



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
	"p2_interact": KEY_ENTER

}
	

func _ready() -> void:
	for action in Global.ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = Global.ACTIONS[action]
			InputMap.action_add_event(action, ev)
