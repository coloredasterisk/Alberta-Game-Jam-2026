extends TabContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if current_tab == -1:
		current_tab = 0

func _on_quit_game_pressed() -> void:
	get_tree().quit()
