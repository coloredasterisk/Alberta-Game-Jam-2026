extends GridContainer




func _ready() -> void:
	
		
			
	# get 2D scene (= 2D world) to share
	var world = $Player1/SubViewport.find_world_2d()
	# give it to render to the viewport of Player 2
	$Player2/SubViewport.world_2d = world
