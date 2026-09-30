extends Node2D
## Lobby and phone-controller assignment for the arena. Three ways to play (chosen in the menu,
## see Session):
##
##   LOCAL        Players scan the QR code to use their phones as controllers, or share the
##                keyboard. Supports any number of players (see amount_of_players), one per
##                SubViewport under $World (see world.gd).
##   ONLINE_HOST  This device runs the match and plays Player 1. Other players join through the
##                relay and drive their assigned slots remotely.
##   ONLINE_GUEST A remote player joins the host's match and watches all positions streamed from
##                the host ~30 times a second.

enum Phase { LOBBY, PLAYING }

const MENU_SCENE := "res://scenes/main.tscn"
const SNAPSHOT_SEC := 1.0 / 30.0

## Local mode: how many players share this screen (one keyboard/phone slot each). Must not be
## more than the number of SubViewport slots under $World.
@export var amount_of_players := 2

@onready var world: Node = $World
## Lobby panel: QR code / match code shown while waiting for players (see main.tscn).
@onready var _qr_rect: TextureRect = $CanvasLayer/Screens/PlayerSetup/TextureRect
@onready var _code_label: RichTextLabel = $CanvasLayer/Screens/PlayerSetup/Code
@onready var _player_setup_screen: Control = $CanvasLayer/Screens/PlayerSetup
@onready var _tutorial_screen: Control = $CanvasLayer/Screens/TutorialScreen
## Full-screen menu background. It stays below Screens and is hidden at the
## exact moment the arena becomes interactive.
@onready var _player_labels: Array[RichTextLabel] = [
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player1,
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player2,
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player3,
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player4,
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player5,
	$CanvasLayer/Screens/PlayerSetup/PlayerList/Player6,
]

var players: Array[Player] = []
var _phone_ids: Array[int] = []  # per player slot; 0 = keyboard / not yet assigned

var in_lobby := true
var _phase := Phase.LOBBY

# True once every slot is filled and we're showing the tutorial, waiting for everyone to
# press a button before the match actually starts.
var _waiting_to_start := false
var _ready_to_start: Array[bool] = []

# Online host / guest (slot 0 is the host; relay IDs 1..N-1 map to the other slots)
var _snapshot_timer := 0.0
var _guest: OnlineGuest

# True once begin_session() has actually started PhoneControllers / joined as a guest.
var _session_started := false


func _ready() -> void:
	_show_lobby(true)
	get_tree().paused = false

## Starts phone-controller / relay networking for Session.mode. Called once the player finishes
## the pre-match menu (amount picked in ChoosePlayerAmount, or a join code submitted) - NOT at
## scene load, since Session.mode isn't chosen yet at that point.
func begin_session() -> void:
	if _session_started:
		return
	_session_started = true
	match Session.mode:
		Session.Mode.LOCAL:
			_setup_local()
		Session.Mode.ONLINE_HOST:
			_setup_host()
		Session.Mode.ONLINE_GUEST:
			_setup_guest()


func _setup_players() -> void:
	players.clear()
	_phone_ids.clear()
	var count: int = mini(amount_of_players, world.get_child_count())
	for i in range(count):
		players.append(world.get_child(i).get_node("SubViewport/Player"))
		_phone_ids.append(0)


## Called by canvas_layer.gd once the player picks how many are playing
func set_amount_of_players(amount: int) -> void:
	amount_of_players = amount
	if Global.local_mode:
		_setup_players()
		_show_tutorial() 
		return

	if not _session_started:
		begin_session()
		_setup_players()
		if Session.mode == Session.Mode.LOCAL:
			PhoneControllers.max_players = players.size()
		elif Session.mode == Session.Mode.ONLINE_HOST:
			PhoneControllers.max_players = maxi(players.size(), 0)
	_refresh_names()
	_update_join_info()

	


func _setup_local() -> void:
	_setup_players()
	PhoneControllers.max_players = players.size()
	PhoneControllers.start()
	PhoneControllers.player_joined.connect(_on_phone_joined)
	PhoneControllers.player_left.connect(_on_phone_left)
	PhoneControllers.player_disconnected.connect(func(_id: int) -> void: _refresh_names())
	PhoneControllers.player_reconnected.connect(func(_id: int) -> void: _refresh_names())
	PhoneControllers.button_pressed.connect(_on_phone_button)
	PhoneControllers.status_changed.connect(func(_ok: bool, _msg: String) -> void: _update_join_info())
	_update_join_info()


func _setup_host() -> void:
	_setup_players()
	PhoneControllers.max_players = maxi(players.size(), 0)
	PhoneControllers.start("relay")  # the relay is how the friend's device reaches us
	PhoneControllers.player_joined.connect(_on_guest_joined)
	PhoneControllers.player_left.connect(_on_guest_left)
	PhoneControllers.player_disconnected.connect(func(_id: int) -> void: _refresh_names())
	PhoneControllers.player_reconnected.connect(func(_id: int) -> void: _refresh_names())
	PhoneControllers.button_pressed.connect(_on_phone_button)
	PhoneControllers.status_changed.connect(func(_ok: bool, _msg: String) -> void: _update_join_info())
	_update_join_info()

	


func _setup_guest() -> void:
	amount_of_players = 2
	_setup_players()
	_set_guest_players_physics(false)

	_guest = OnlineGuest.new()
	add_child(_guest)
	_guest.joined.connect(func(_id: int) -> void: _refresh_names())
	_guest.failed.connect(func(reason: String) -> void:
		Session.notice = reason
		_leave())
	_guest.reconnecting.connect(func() -> void: _refresh_names())
	_guest.snapshot.connect(_on_snapshot)
	_guest.message.connect(_on_host_message)
	_guest.join(Session.join_code)
	_update_join_info()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart") and Session.mode != Session.Mode.ONLINE_GUEST:
		_on_start_pressed()
	if _waiting_to_start:
		for i in range(0, players.size()):
			if _phone_ids[i] == 0 and Input.is_action_just_pressed("p%d_interact" % players[i].player_index):
				_mark_ready(i)
	match Session.mode:
		Session.Mode.LOCAL:
			for i in range(0, players.size()):
				if _phone_ids[i] > 0:
					players[i].external_stick = PhoneControllers.get_stick(_phone_ids[i])
		Session.Mode.ONLINE_HOST:
			for i in range(0, players.size()):
				if _phone_ids[i] > 0:
					players[i].external_stick = PhoneControllers.get_stick(_phone_ids[i])
					
			_snapshot_timer += delta
			if _snapshot_timer >= SNAPSHOT_SEC:
				_snapshot_timer = fmod(_snapshot_timer, SNAPSHOT_SEC)
				_send_snapshot()
		Session.Mode.ONLINE_GUEST:
			_send_guest_input()
	if _phase == Phase.PLAYING:
		$CanvasLayer.update_player_stats()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_leave()


func _leave() -> void:
	if _guest:
		_guest.leave()
	PhoneControllers.stop()
	get_tree().change_scene_to_file(MENU_SCENE)


# --- Flow --------------------------------------------------------------------

func _show_lobby(preloading = false) -> void:
	in_lobby = true
	_phase = Phase.LOBBY
	_show_player_setup(preloading)
	$CanvasLayer.visible = true
	$CanvasLayer/Screens.visible = true
	$CanvasLayer/HUD.visible = false
	world.visible = false
	_refresh_names()


func update_split_screen() -> void:
	var pos = Global.SPLIT_SCREEN_DIMENSIONS[amount_of_players - 1]
	for i in range(amount_of_players):
		if i >= $World.get_child_count():
			$World.get_child(i).visible = false
			$CanvasLayer/HUD/Player.get_child(i).visible = false
			
		else:
			$World.get_child(i).visible = true
			$World.get_child(i).size = pos[i]
			$CanvasLayer/HUD/Player.get_child(i).visible = true
		

func _start_match() -> void:
	_phase = Phase.PLAYING
	_enter_playing()


## Hides the menu and reveals the arena once the match is actually starting.
func _enter_playing() -> void:
	update_split_screen()
	in_lobby = false
	_waiting_to_start = false
	$CanvasLayer/Screens.visible = false
	$SplashWorld.visible = false
	$SplashWorld.paused = true
	world.visible = true
	$CanvasLayer/HUD.visible = true
	$World._start_game()


## Enter/Space on the keyboard, or a phone's start button.
func _on_start_pressed() -> void:
	if in_lobby and Session.mode == Session.Mode.LOCAL:
		_start_match()


# --- Phones (local mode) -------------------------------------------------------

func _on_phone_joined(id: int) -> void:

	var slot := _phone_ids.find(0)
	if slot == -1:
		PhoneControllers.kick(id)
		return
	_phone_ids[slot] = id
	players[slot].phone_id = id
	var p := PhoneControllers.get_player(id)
	players[slot].username = p.name if p else ""
	var color_name: String = Global.COLOR_NAMES[slot % Global.COLOR_NAMES.size()]
	print("line 254: " + color_name)
	PhoneControllers.set_player_theme(id, Color.WHITE, "P%d · %s" % [slot, p.name])
	PhoneControllers.send_text(id, "You're Player %d (%s)" % [slot, color_name])
	PhoneControllers.vibrate(id, 60)
	_refresh_names()
	_check_all_joined()

func _on_phone_left(id: int) -> void:
	var slot := _phone_ids.find(id)
	if slot != -1:
		_phone_ids[slot] = 0
		players[slot].phone_id = 0
		players[slot].username = ""
		players[slot].external_stick = Vector2.ZERO
	if _waiting_to_start:
		_show_player_setup()
	_refresh_names()


func _on_phone_button(id: int, button: StringName) -> void:
	if not _waiting_to_start:
		if button == &"start":
			_on_start_pressed()
		elif button == &"interact":
			players[id-1].apply_interact()
		return
	var slot := _phone_ids.find(id)
	_mark_ready(slot)


func _refresh_names() -> void:
	var joined_count := 0
	for i in _player_labels.size():
		if i >= players.size():
			_player_labels[i].visible = false
			continue
		_player_labels[i].visible = true
		var is_ready: bool
		match Session.mode:
			Session.Mode.LOCAL:
				is_ready = _phone_ids[i] > 0
			Session.Mode.ONLINE_HOST:
				is_ready = _phone_ids[i] > 0
			Session.Mode.ONLINE_GUEST:
				is_ready = _guest != null and _guest.is_connected_to_host()
		print("line 298:" + str(i) + str(_phone_ids[i]))
		var status := players[i].username if is_ready and players[i].username != "" else ("Ready" if is_ready else "Empty")
		_player_labels[i].text = "[center]Player %d - %s" % [i + 1, status]
		if is_ready:
			joined_count += 1


## Everyone has a slot: show the tutorial and wait for each player to press a button.
func _check_all_joined() -> void:
	if in_lobby and not _waiting_to_start and _all_slots_filled():
		_show_tutorial()


func _all_slots_filled() -> bool:
	match Session.mode:
		Session.Mode.LOCAL:
			return _phone_ids.all(func(pid: int) -> bool: return pid > 0)
		Session.Mode.ONLINE_HOST:
			for i in range(0, _phone_ids.size()):
				if _phone_ids[i] == 0:
					return false
			return true
		_:
			return true


func _show_tutorial() -> void:
	_waiting_to_start = true
	_ready_to_start.resize(players.size())
	_ready_to_start.fill(false)
	_player_setup_screen.visible = false
	_tutorial_screen.visible = true

	for i in range(world.get_child_count()):
		if i >= players.size():
			$CanvasLayer/Screens/TutorialScreen/PlayerSection/PlayerReady.get_node("Player" + str(i+1)).visible = false
		else:
			var username = players[i].username
			if username == "":
				username = "P" + str(i+1)
			$CanvasLayer/Screens/TutorialScreen/PlayerSection/PlayerReady.get_node("Player" + str(i+1)).text = "[center]" + username + "\nWaiting"
			$CanvasLayer/Screens/TutorialScreen/PlayerSection/PlayerReady.get_node("Player" + str(i+1)).visible = true


func _show_player_setup(preloading = false) -> void:
	_waiting_to_start = false
	if not preloading:
		_player_setup_screen.visible = true


func _mark_ready(slot: int) -> void:
	print("line 350 slot " + str(slot))
	if slot < 0 or slot >= _ready_to_start.size() or _ready_to_start[slot]:
		return
	_ready_to_start[slot] = true

	$CanvasLayer/Screens/TutorialScreen/PlayerSection/PlayerReady.get_node("Player" + str(slot+1)).text = "[center]" + players[slot].username + "\nReady!"
	if _ready_to_start.all(func(r: bool) -> bool: return r):
		_start_match()


## Shows the QR code / match code, or the connection status while there's none. The QR
## TextureRect in main.tscn scales the code to fit a fixed square (expand_mode Ignore Size,
## stretch Keep Aspect Centered): the join URL's length changes the code's size (it lists the
## backup relays, see PhoneControllers.get_join_url()) and must not push it off screen.
func _update_join_info() -> void:
	match Session.mode:
		Session.Mode.LOCAL:
			if PhoneControllers.can_join:
				_qr_rect.texture = PhoneControllers.make_qr_texture(10) 
				_set_code_label("Scan to join!\n\nOr input the code: " + PhoneControllers.session_code)
			else:
				_qr_rect.texture = null
				_set_code_label(PhoneControllers.status_message)
		Session.Mode.ONLINE_HOST:
			if PhoneControllers.can_join:
				var code := PhoneControllers.session_code
				# Phones scan into the controller page (name entry, INTERACT, player view), served
				# by the relay. Session.invite_url(code) would open the whole game on the phone
				# instead (the ONLINE_GUEST path, which friends reach with Join + this code).
				_qr_rect.texture = PhoneControllers.make_qr_texture(10)
				_set_code_label("Host Match Code: %s" % code)
			else:
				_qr_rect.texture = null
				_set_code_label("Creating a match…")
		Session.Mode.ONLINE_GUEST:
			_qr_rect.texture = null
			_set_code_label("Joining match %s…" % Session.join_code)


## Player-setup code/status copy is always centred in its right-hand column.
func _set_code_label(value: String) -> void:
	_code_label.text = "[center]" + value


# --- Online: host ------------------------------------------------------------

func _on_guest_joined(id: int) -> void:
	if id <= 0 or id > players.size():
		PhoneControllers.kick(id)
		return
	_phone_ids[id-1] = id
	players[id-1].phone_id = id
	var p := PhoneControllers.get_player(id)
	players[id-1].username = p.name if p else ""
	var color_name: String = Global.COLOR_NAMES[(id-1) % Global.COLOR_NAMES.size()]
	print("line 402: " + color_name)
	PhoneControllers.set_player_theme(id, color_name, "P%d" % (id))
	PhoneControllers.send_text(id, "You're Player %d (%s)" % [id, color_name])
	PhoneControllers.vibrate(id, 60)
	_refresh_names()
	_check_all_joined()


func _on_guest_left(id: int) -> void:
	if id <= 0 or id >= _phone_ids.size() or _phone_ids[id] != id:
		return
	_phone_ids[id] = 0
	players[id].phone_id = 0
	players[id].username = ""
	players[id].external_stick = Vector2.ZERO
	if _waiting_to_start:
		_show_lobby()
	_refresh_names()


func _send_snapshot() -> void:
	var phase := Phase.LOBBY if in_lobby else Phase.PLAYING
	var snapshot := {
		"t": "st",
		"ts": Time.get_ticks_msec(),
		"ph": phase,
		"n": players.size(),
		"p": players.map(func(p: Player) -> Array: return [(p.global_position.x / 2) + 170, (p.global_position.y / 2) + 180]),
	}
	for id in _phone_ids:
		if id > 0:
			PhoneControllers.send_fast(id, snapshot)


# --- Online: guest -------------------------------------------------------------

func _send_guest_input() -> void:
	if _guest == null or not _guest.is_connected_to_host():
		return
	if Input.is_action_just_pressed("p1_interact"):
		_guest.send({"t": "in", "b": ["interact"]})
	var move := Input.get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")
	_guest.send_fast({"t": "in", "x": snappedf(move.x, 0.01), "y": snappedf(move.y, 0.01)})


func _on_host_message(msg: Dictionary) -> void:
	if str(msg.get("t", "")) == "msg":
		_set_code_label(str(msg.get("text", "")))


func _on_snapshot(msg: Dictionary) -> void:
	var phase := int(msg.get("ph", Phase.LOBBY)) as Phase
	if phase != _phase:
		_phase = phase
		if phase == Phase.LOBBY:
			_show_lobby()
		else:
			_enter_playing()
	var positions: Variant = msg.get("p")
	if positions is Array:
		var player_count := int(msg.get("n", positions.size()))
		if player_count != players.size():
			amount_of_players = player_count
			_setup_players()
			_set_guest_players_physics(false)
		for i in mini(positions.size(), players.size()):
			if positions[i] is Array and positions[i].size() >= 2:
				var pos: Array = positions[i]
				players[i].global_position = Vector2(pos[0], pos[1])
	


func _set_guest_players_physics(enabled: bool) -> void:
	for player in players:
		player.set_physics_process(enabled)
