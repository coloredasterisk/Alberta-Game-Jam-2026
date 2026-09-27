extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Exported (binary) scenes restore current_tab before the tab children exist, and with
	# deselect_enabled that leaves no tab selected (-1) -> blank menu. Select the title here.
	if current_tab == -1:
		current_tab = 0
	# Browsers can't close their tab from the game, so Quit would do nothing there.
	if OS.has_feature("web"):
		$TitleScreen/Selection/QuitGame.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_game_pressed() -> void:
	get_tree().quit()
