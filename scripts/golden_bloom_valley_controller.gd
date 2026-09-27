class_name GoldenBloomValleyController
extends Control
## Runtime composition for the approved Bloom Market title background.
##
## The shader draws only scalable terrain. This controller intentionally uses
## the repository's original PNG textures for every recognizable object, which
## keeps the menu art exactly consistent with the in-game pixel assets.

const DESIGN_SIZE := Vector2(640.0, 360.0)

## Final values selected with the in-chat tuner on 2026-09-27.
const SHOP_SCALE := 3.0
## The tuner kept the shop centred, but the real menu buttons occupy that exact
## column. Moving it to 82% keeps the approved height/scale visibly usable.
const SHOP_X_PERCENT := 0.82
const SHOP_Y_PERCENT := 0.47
const FLOWER_COUNT := 8
const BEE_COUNT := 5
const HIVE_SCALE := 2.0

const SHOP_TEXTURE := preload("res://art/Shop.png")
const BLUE_HIVE_TEXTURE := preload("res://art/Blue_Beehive.png")
const MONO_HIVE_TEXTURE := preload("res://art/Mono_Beehive.png")
const BLUE_FLOWER_TEXTURE := preload("res://art/Blue_Flower.png")
const RED_FLOWER_TEXTURE := preload("res://art/Red_Flower.png")
const MONO_FLOWER_TEXTURE := preload("res://art/Mono_Flower.png")
const BEE_FRAMES := preload("res://resources/bee_sprite.tres")

@export_node_path("ColorRect") var background_path := NodePath("Background")
@export var pointer_reaction := true
@export var reduced_motion := false

@onready var background: ColorRect = get_node(background_path)

var _material: ShaderMaterial
var _asset_layer: Node2D
var _pointer_uv := Vector2(0.5, 0.5)
var _joined_players := 0
var _ready_state := [false, false, false, false]
var _hives: Array[Sprite2D] = []
var _animated_assets: Array[CanvasItem] = []


func _ready() -> void:
	# Duplicate the material so runtime interaction never mutates the reusable
	# resource or another open menu instance.
	_material = background.material.duplicate() as ShaderMaterial
	background.material = _material
	_material.set_shader_parameter("motion_amount", 0.0 if reduced_motion else 1.0)
	_build_exact_asset_layer()
	set_process(true)


func _build_exact_asset_layer() -> void:
	_asset_layer = Node2D.new()
	_asset_layer.name = "ExactPixelAssets"
	_asset_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_asset_layer)

	# Shop: approved scale 3 and vertical position 47%.
	var shop := _make_sprite(SHOP_TEXTURE, Vector2(DESIGN_SIZE.x * SHOP_X_PERCENT, DESIGN_SIZE.y * SHOP_Y_PERCENT), SHOP_SCALE, 0.34)
	shop.name = "BloomMarketShop"

	# Rival hives frame the menu without entering its 46% safe column.
	var left_hive := _make_sprite(MONO_HIVE_TEXTURE, Vector2(74.0, 302.0), HIVE_SCALE, 0.88)
	left_hive.name = "LeftHive"
	var right_hive := _make_sprite(BLUE_HIVE_TEXTURE, Vector2(566.0, 302.0), HIVE_SCALE, 0.88)
	right_hive.name = "RightHive"
	_hives.assign([left_hive, right_hive])

	_build_flowers()
	_build_bees()
	_update_hive_state()


func _build_flowers() -> void:
	# Eight flowers remain outside the menu-safe area and, importantly, outside
	# both hive/flag footprints. Nothing is layered in front of either hive.
	var positions := [
		Vector2(150, 326), Vector2(190, 278), Vector2(205, 345), Vector2(145, 255),
		Vector2(490, 326), Vector2(450, 278), Vector2(435, 345), Vector2(495, 255),
	]
	var textures: Array[Texture2D] = [BLUE_FLOWER_TEXTURE, RED_FLOWER_TEXTURE, MONO_FLOWER_TEXTURE]
	for i in FLOWER_COUNT:
		var flower_scale := 2.0 if i % 4 == 0 else 1.0
		var flower := _make_sprite(textures[i % textures.size()], positions[i], flower_scale, 1.0)
		flower.name = "Flower%d" % (i + 1)


func _build_bees() -> void:
	# Five animated bees follow two edge routes, leaving the centre quiet.
	var positions := [Vector2(112, 245), Vector2(158, 222), Vector2(202, 197), Vector2(480, 218), Vector2(526, 248)]
	for i in BEE_COUNT:
		var bee := AnimatedSprite2D.new()
		bee.name = "Bee%d" % (i + 1)
		bee.sprite_frames = BEE_FRAMES
		bee.animation = &"blue" if i % 2 == 0 else &"red"
		bee.autoplay = bee.animation
		bee.position = positions[i]
		bee.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bee.set_meta("base_position", positions[i])
		bee.set_meta("parallax_depth", 1.12)
		bee.set_meta("motion_phase", float(i) * 1.37)
		_asset_layer.add_child(bee)
		_animated_assets.append(bee)


func _make_sprite(texture: Texture2D, position: Vector2, sprite_scale: float, depth: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.set_meta("base_position", position)
	sprite.set_meta("parallax_depth", depth)
	sprite.set_meta("motion_phase", float(_animated_assets.size()) * 0.91)
	_asset_layer.add_child(sprite)
	_animated_assets.append(sprite)
	return sprite


func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	if pointer_reaction:
		var target := get_viewport().get_mouse_position() / viewport_size
		target = target.clamp(Vector2.ZERO, Vector2.ONE)
		_pointer_uv = _pointer_uv.lerp(target, 1.0 - exp(-delta * 7.0))

	var pointer_delta := _pointer_uv - Vector2(0.5, 0.5)
	_material.set_shader_parameter("pointer_offset", pointer_delta if pointer_reaction else Vector2.ZERO)
	_update_asset_motion(pointer_delta)


func _update_asset_motion(pointer_delta: Vector2) -> void:
	var time_value := Time.get_ticks_msec() * 0.001
	for item in _animated_assets:
		var base_position: Vector2 = item.get_meta("base_position")
		var depth: float = item.get_meta("parallax_depth")
		var phase: float = item.get_meta("motion_phase")
		var parallax := pointer_delta * Vector2(10.0, 6.0) * depth if pointer_reaction else Vector2.ZERO
		var bob := Vector2.ZERO
		if not reduced_motion and item is AnimatedSprite2D:
			bob.y = sin(time_value * 1.7 + phase) * 2.0
		item.position = base_position + parallax + bob


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var viewport_size := get_viewport_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			_pointer_uv = (event.position / viewport_size).clamp(Vector2.ZERO, Vector2.ONE)


## Lobby integration retained from the previous background. The approved scene
## always shows both hives; joining and readiness only adjust their brightness.
func set_joined_players(count: int) -> void:
	_joined_players = clampi(count, 0, 4)
	_update_hive_state()


func set_player_ready(player_index: int, is_ready: bool) -> void:
	if player_index < 0 or player_index > 3:
		return
	_ready_state[player_index] = is_ready
	_update_hive_state()


func _update_hive_state() -> void:
	if _hives.is_empty():
		return
	for i in _hives.size():
		var joined := _joined_players > i
		var ready := bool(_ready_state[i])
		_hives[i].modulate = Color(1.18, 1.18, 1.18, 1.0) if ready else (Color.WHITE if joined else Color(0.82, 0.82, 0.82, 1.0))


## Accessibility setting retained in code; it is not exposed as an on-screen control.
func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_material.set_shader_parameter("motion_amount", 0.0 if enabled else 1.0)


## Compatibility methods retained for existing menu/lobby callers. The focused
## background intentionally has no gameplay power-up or audio-reactive effects.
func play_countdown(_duration := 3.0) -> void:
	pass


func set_music_energy(_value: float) -> void:
	pass


func set_sunset_progress(_value: float) -> void:
	pass


func set_quality(_level: int) -> void:
	pass
