extends CanvasLayer

var is_hosting = false


func set_player_amount(amount : int) -> void:
	Global.amount_of_players = amount
	$Screens/PlayerSetup.visible = true
	get_parent().set_amount_of_players(amount)

func _on_local_pressed() -> void:
	Global.local_mode = true
	Session.mode = Session.Mode.LOCAL
	$Screens/ChoosePlayerAmount.visible = true

func _on_online_pressed() -> void:
	Global.local_mode = false
	$Screens/OnlineMultiplayerSetup.visible = true


func _on_code_back_pressed() -> void:
	$Screens/OnlineMultiplayerSetup.visible = true

func send_code(code: String) -> void:
	Session.join_code = code
	get_parent().begin_session()
	$Screens/TutorialScreen.visible = true


func _on_player_count_back_pressed() -> void:
	$Screens/TitleScreen.visible = true


func _on_cancel_pressed() -> void:
	$Screens/OnlineMultiplayerSetup.visible = true


func update_player_stats() -> void:
	# Update the player stats UI elements here
	for i in range(Global.amount_of_players):
		var player = get_node("/root/Main").players[i]
		var player_stats_node = get_node("HUD/Player/Player" + str(i + 1))
		player_stats_node.get_node("CapacityDisplay").text = str(player.nectar) + "/" + str(player.current_nectar_capacity) 
		player_stats_node.get_node("MoneyDisplay").text = str(player.money_counter)
		player_stats_node.get_node("HoneyDisplay").text = str(0)
