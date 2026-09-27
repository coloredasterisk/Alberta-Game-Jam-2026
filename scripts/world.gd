extends GridContainer


@onready var players: Array[Dictionary] = [
	{
		sub_viewport = $Player1/SubViewport,
		camera = $Player1/SubViewport/Player/Camera2D,
		player = $Player1/SubViewport/Player,
	},
	{
		sub_viewport = $Player2/SubViewport,
		camera = $Player2/SubViewport/Player/Camera2D,
		player = $Player2/SubViewport/Player,
	},
]


func _ready() -> void:

	players[1].sub_viewport.world_2d = players[0].sub_viewport.world_2d
	
	#for info in players:
	#	var remote_transform := RemoteTransform2D.new()
	##	remote_transform.remote_path = info.camera.get_path()
	#	info.player.add_child(remote_transform)
