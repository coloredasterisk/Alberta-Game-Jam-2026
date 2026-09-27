extends Control
## Online Multiplayer screen: host a match, join a friend's, or go back.
## Buttons and labels are predefined in main.tscn under this node.

@onready var _host_button: Button = $Selection/HostGame
@onready var _join_button: Button = $Selection/JoinGame
@onready var _back_button: Button = $Selection/QuitGame


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _on_host_pressed() -> void:
	Session.mode = Session.Mode.ONLINE_HOST
	Session.join_code = ""
	get_parent().get_parent().is_hosting = true
	get_node("../ChoosePlayerAmount").visible = true
	#_start_match()


func _on_join_pressed() -> void:
	Session.mode = Session.Mode.ONLINE_GUEST
	get_parent().is_hosting = true
	get_parent().get_node("EnterCode").visible = true


func _on_back_pressed() -> void:
	get_parent().get_node("TitleScreen").visible = true
