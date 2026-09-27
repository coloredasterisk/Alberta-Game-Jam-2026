extends CanvasLayer

var network_mode = "local"
var is_hosting = false


func set_player_amount(amount : int) -> void:
	Global.amount_of_players = amount
	get_parent().set_amount_of_players(amount)
	$Screens/PlayerSetup.visible = true

func _on_local_pressed() -> void:
	network_mode = "local"
	Session.mode = Session.Mode.LOCAL
	$Screens/ChoosePlayerAmount.visible = true
	$"Screens/ChoosePlayerAmount/Amount/6".visible = false

func _on_online_pressed() -> void:
	network_mode = "online"
	$Screens/OnlineMultiplayerSetup.visible = true
	$"Screens/ChoosePlayerAmount/Amount/6".visible = true


func _on_code_back_pressed() -> void:
	$Screens/OnlineMultiplayerSetup.visible = true
	
func send_code() -> void:
	pass


func _on_player_count_back_pressed() -> void:
	$Screens/TitleScreen.visible = true


func _on_cancel_pressed() -> void:
	$Screens/OnlineMultiplayerSetup.visible = true
