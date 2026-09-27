extends Panel

var round_time = 120.0
var timer = 10.0
var playing = false
var round_over = false
var hives = []
var players = []

func _ready() -> void:
	# get 2D scene (= 2D world) to share
	var world = $Player1/SubViewport.find_world_2d()
	# give it to render to the viewport of Player 2
	$Player2/SubViewport.world_2d = world
	$Player3/SubViewport.world_2d = world
	$Player4/SubViewport.world_2d = world
	
	players = [
		$Player1/SubViewport/Player,
		$Player2/SubViewport/Player,
		$Player3/SubViewport/Player,
		$Player4/SubViewport/Player,
	]
	get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").max_value = round_time
	get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").value = round_time

func _process(delta: float) -> void:
	if playing:
		timer -= delta
		if timer <= 0:
			playing = false
			timer = 0
			_on_round_timer_timeout()
		get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar").value = timer
		get_node("../CanvasLayer/HUD/TimerDisplay/TextureProgressBar/TimeText").text = str(int(timer))
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("p1_interact") and round_over:
		get_tree().reload_current_scene()

func _start_game() -> void:
	
	hives = $Player1/SubViewport/Map1/Hives.get_children()
	
	for i in range(hives.size()):
		players[i].global_position = hives[i].global_position
	
	get_node("../BackgroundMusic").play()
	get_node("../CanvasLayer/321Go").visible = true
	get_node("../CanvasLayer/321Go").play()

func _on_start_countdown_timeout() -> void:
	playing = true
	get_node("../CanvasLayer/321Go").visible = false
	for player in players:
		player.enable()
		
func _on_round_timer_timeout() -> void:
	var hives = get_tree().get_nodes_in_group("hives")
	hives.sort_custom(func(a, b): return a.current_amount > b.current_amount)

	var place := 0
	for i in hives.size():
		# only move down a place if this hive has less than the one before it
		if i == 0 or hives[i].current_amount < hives[i - 1].current_amount:
			place = i + 1
		var result = place_name(place)
		var score =  hives[i].current_amount
		get_node("/root/Main/World").get_child(i).get_node("SubViewport/BG/Placement").update_display(result, score)
	get_tree().paused = true
	round_over = true

func place_name(place: int) -> String:
	return ["1st", "2nd", "3rd", "4th"][place - 1]
