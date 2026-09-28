extends GridContainer

var stored_map = {}
var grid_size = 4
var mini_player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func create_map(space, walls) -> void:
	for cell in space:
		var rect = ColorRect.new()
		rect.color = Color.WEB_GREEN
		rect.size = Vector2.ONE * grid_size
		rect.position = space * grid_size
		stored_map[space] = rect
		$World.add_child(rect)
	for cell in walls:
		if stored_map.has(cell):
			stored_map[cell].color = Color.DIM_GRAY
		else:
			var rect = ColorRect.new()
			rect.color = Color.DIM_GRAY
			rect.size = Vector2.ONE * grid_size
			rect.position = space * grid_size
			stored_map[space] = rect
			$World.add_child(rect)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
