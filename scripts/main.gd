extends Node2D
## Lobby and phone-controller assignment for the arena. Three ways to play (chosen in the menu,
## see Session):
##
##   LOCAL        Players scan the QR code to use their phones as controllers, or share the
##                keyboard. Supports any number of players (see amount_of_players), one per
##                SubViewport under $World (see world.gd).
##   ONLINE_HOST  Phone vs phone: this device runs the match and plays Player 1. The friend
##                joins with the match code through the relay, like a phone controller would,
##                and drives Player 2 remotely.
##   ONLINE_GUEST The friend's side: watches a position snapshot of both players streamed from
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

# Online host / guest (phone vs phone is always exactly 2 players: 0 = host, 1 = guest)
var _guest_id := 0
var _snapshot_timer := 0.0
var _guest: OnlineGuest


func _ready() -> void:
	match Session.mode:
		Session.Mode.LOCAL:
			_setup_local()
		Session.Mode.ONLINE_HOST:
			_setup_host()
		Session.Mode.ONLINE_GUEST:
			_setup_guest()
	_show_lobby()


func _setup_players() -> void:
	players.clear()
	_phone_ids.clear()
	var count: int = mini(amount_of_players, world.get_child_count())
	for i in range(count):
		players.append(world.get_child(i).get_node("SubViewport/Player"))
		_phone_ids.append(0)


## Called by canvas_layer.gd once the player picks how many are playing (local mode only).
func set_amount_of_players(amount: int) -> void:
	amount_of_players = amount
	_setup_players()
	if Session.mode == Session.Mode.LOCAL:
		PhoneControllers.max_players = players.size()
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
	amount_of_players = 2
	_setup_players()
	PhoneControllers.max_players = 1
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
	for p in players:
		p.set_physics_process(false)  # positions come from the host's snapshots instead

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
		for i in players.size():
			if _phone_ids[i] == 0 and Input.is_action_just_pressed("p%d_interact" % players[i].player_index):
				_mark_ready(i)
	match Session.mode:
		Session.Mode.LOCAL:
			for i in players.size():
				if _phone_ids[i] > 0:
					players[i].external_stick = PhoneControllers.get_stick(_phone_ids[i])
		Session.Mode.ONLINE_HOST:
			if _guest_id > 0:
				players[1].external_stick = PhoneControllers.get_stick(_guest_id)
			_snapshot_timer += delta
			if _snapshot_timer >= SNAPSHOT_SEC:
				_snapshot_timer = fmod(_snapshot_timer, SNAPSHOT_SEC)
				_send_snapshot()
		Session.Mode.ONLINE_GUEST:
			_send_guest_input()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_leave()


func _leave() -> void:
	if _guest:
		_guest.leave()
	PhoneControllers.stop()
	get_tree().change_scene_to_file(MENU_SCENE)


# --- Flow --------------------------------------------------------------------

func _show_lobby() -> void:
	in_lobby = true
	_phase = Phase.LOBBY
	_show_player_setup()
	$CanvasLayer.visible = true
	world.visible = false
	_refresh_names()


func _start_match() -> void:
	_phase = Phase.PLAYING
	_enter_playing()


## Hides the menu and reveals the arena once the match is actually starting.
func _enter_playing() -> void:
	in_lobby = false
	_waiting_to_start = false
	$CanvasLayer.visible = false
	world.visible = true


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
	var color_name: String = Global.COLOR_NAMES[slot % Global.COLOR_NAMES.size()]
	PhoneControllers.set_player_theme(id, Color.WHITE, "P%d · %s" % [slot + 1, p.name])
	PhoneControllers.send_text(id, "You're Player %d (%s)" % [slot + 1, color_name])
	PhoneControllers.vibrate(id, 60)
	_refresh_names()
	_check_all_joined()


func _on_phone_left(id: int) -> void:
	var slot := _phone_ids.find(id)
	if slot != -1:
		_phone_ids[slot] = 0
		players[slot].phone_id = 0
		players[slot].external_stick = Vector2.ZERO
	if _waiting_to_start:
		_show_player_setup()
	_refresh_names()


func _on_phone_button(id: int, button: StringName) -> void:
	if not _waiting_to_start:
		if button == &"start":
			_on_start_pressed()
		return
	var slot := _phone_ids.find(id)
	if slot == -1 and id == _guest_id:
		slot = 1
	_mark_ready(slot)


func _refresh_names() -> void:
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
				is_ready = i == 0 or _guest_id > 0
			Session.Mode.ONLINE_GUEST:
				is_ready = i == 0 or (_guest != null and _guest.is_connected_to_host())
		_player_labels[i].text = "Player %d - %s" % [i + 1, "Ready" if is_ready else "Empty"]


## Everyone has a slot: show the tutorial and wait for each player to press a button.
func _check_all_joined() -> void:
	if in_lobby and not _waiting_to_start and _all_slots_filled():
		_show_tutorial()


func _all_slots_filled() -> bool:
	match Session.mode:
		Session.Mode.LOCAL:
			return _phone_ids.all(func(pid: int) -> bool: return pid > 0)
		Session.Mode.ONLINE_HOST:
			return _guest_id > 0
		_:
			return true


func _show_tutorial() -> void:
	_waiting_to_start = true
	_ready_to_start.resize(players.size())
	_ready_to_start.fill(false)
	_player_setup_screen.visible = false
	_tutorial_screen.visible = true


func _show_player_setup() -> void:
	_waiting_to_start = false
	_tutorial_screen.visible = false
	_player_setup_screen.visible = true


func _mark_ready(slot: int) -> void:
	if slot < 0 or slot >= _ready_to_start.size() or _ready_to_start[slot]:
		return
	_ready_to_start[slot] = true
	if _ready_to_start.all(func(r: bool) -> bool: return r):
		_start_match()


func _update_join_info() -> void:
	match Session.mode:
		Session.Mode.LOCAL:
			if PhoneControllers.can_join:
				_qr_rect.texture = PhoneControllers.make_qr_texture(10) 
				_code_label.text = "Scan to join!\n\nOr input the code: " + PhoneControllers.session_code
			else:
				_qr_rect.texture = null
				_code_label.text = PhoneControllers.status_message
		Session.Mode.ONLINE_HOST:
			if PhoneControllers.can_join:
				var code := PhoneControllers.session_code
				_qr_rect.texture = QrCode.make_texture(Session.invite_url(code), 8)
				_code_label.text = "Host Match Code: %s" % code
			else:
				_qr_rect.texture = null
				_code_label.text = "Creating a match…"
		Session.Mode.ONLINE_GUEST:
			_qr_rect.texture = null
			_code_label.text = "Joining match %s…" % Session.join_code


# --- Online: host ------------------------------------------------------------

func _on_guest_joined(id: int) -> void:
	if _guest_id > 0 and _guest_id != id:
		PhoneControllers.kick(id)
		return
	_guest_id = id
	players[1].phone_id = id
	PhoneControllers.send_text(id, "You're Player 2 (%s)" % Global.COLOR_NAMES[1])
	PhoneControllers.vibrate(id, 60)
	_refresh_names()
	_check_all_joined()


func _on_guest_left(id: int) -> void:
	if id != _guest_id:
		return
	_guest_id = 0
	players[1].phone_id = 0
	players[1].external_stick = Vector2.ZERO
	_show_lobby()


func _send_snapshot() -> void:
	if _guest_id == 0:
		return
	var phase := Phase.LOBBY if in_lobby else Phase.PLAYING
	PhoneControllers.send_fast(_guest_id, {
		"t": "st",
		"ts": Time.get_ticks_msec(),
		"ph": phase,
		"p": players.map(func(p: Player) -> Array: return [p.global_position.x, p.global_position.y]),
	})


# --- Online: guest -------------------------------------------------------------

func _send_guest_input() -> void:
	if _guest == null or not _guest.is_connected_to_host():
		return
	if Input.is_action_just_pressed("restart"):
		_guest.send({"t": "in", "b": ["start"]})
	var move := Input.get_vector("p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down")
	_guest.send_fast({"t": "in", "x": snappedf(move.x, 0.01), "y": snappedf(move.y, 0.01)})


func _on_host_message(msg: Dictionary) -> void:
	if str(msg.get("t", "")) == "msg":
		_code_label.text = str(msg.get("text", ""))


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
		for i in mini(positions.size(), players.size()):
			var pos: Array = positions[i]
			players[i].global_position = Vector2(pos[0], pos[1])
