extends GridContainer




func _ready() -> void:
	for action in Global.ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = Global.ACTIONS[action]
			InputMap.action_add_event(action, ev)
		
			
	# get 2D scene (= 2D world) to share
	var world = $Player1/SubViewport.find_world_2d()
	# give it to render to the viewport of Player 2
	$Player2/SubViewport.world_2d = world
