class_name GoldenBloomValleyController
extends Control
## Runtime bridge for the Golden Bloom Valley menu shader.
##
## The shader deliberately knows nothing about game nodes. This controller converts
## mouse/touch, lobby readiness, countdowns, and optional music information
## into shader uniforms. You can use this script as-is or call the public methods from
## the existing menu/lobby controller.

@export_node_path("ColorRect") var background_path := NodePath("Background")
@export var pointer_reaction := true
@export var reduced_motion := false
@export_enum("Low", "Medium", "High") var quality_level := 2

@onready var background: ColorRect = get_node(background_path)

var _material: ShaderMaterial
var _pointer_uv := Vector2(0.5, 0.5)
var _ready_state := Vector4.ZERO
var _joined_players := 0


func _ready() -> void:
	# Duplicate the scene material so changing this screen never changes the shared
	# .tres resource or another open menu instance.
	_material = background.material.duplicate() as ShaderMaterial
	background.material = _material
	_material.set_shader_parameter("quality_level", quality_level)
	_material.set_shader_parameter("motion_amount", 0.0 if reduced_motion else 1.0)
	_material.set_shader_parameter("pointer_influence", 0.0 if not pointer_reaction else 0.58)
	set_process(true)


func _process(delta: float) -> void:
	if not pointer_reaction:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Smooth the cursor so pollen and parallax react organically instead of snapping.
	var target := get_viewport().get_mouse_position() / viewport_size
	target = target.clamp(Vector2.ZERO, Vector2.ONE)
	_pointer_uv = _pointer_uv.lerp(target, 1.0 - exp(-delta * 7.0))
	_material.set_shader_parameter("pointer_position", _pointer_uv)
	_material.set_shader_parameter("parallax_offset", (_pointer_uv - Vector2(0.5, 0.5)) * 0.7)


func _input(event: InputEvent) -> void:
	# Touch devices use the most recent finger location as the interaction point.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var viewport_size := get_viewport_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			_pointer_uv = (event.position / viewport_size).clamp(Vector2.ZERO, Vector2.ONE)
			_material.set_shader_parameter("pointer_position", _pointer_uv)


## Lights the first `count` distant hives. Expected range: 0 to 4.
func set_joined_players(count: int) -> void:
	_joined_players = clampi(count, 0, 4)
	_material.set_shader_parameter("joined_players", _joined_players)


## Sets a player's lobby-ready glow. Player indices are 0=red, 1=blue,
## 2=yellow, and 3=green.
func set_player_ready(player_index: int, is_ready: bool) -> void:
	if player_index < 0 or player_index > 3:
		push_warning("GoldenBloomValleyController received an invalid player index.")
		return
	var value := 1.0 if is_ready else 0.0
	# Assign named Vector4 components explicitly for compatibility across Godot
	# versions; indexed compound assignment is less portable.
	match player_index:
		0: _ready_state.x = value
		1: _ready_state.y = value
		2: _ready_state.z = value
		3: _ready_state.w = value
	_material.set_shader_parameter("player_ready_state", _ready_state)


## Animates the environment through a 3-2-1-GO style energy build-up.
## Call this alongside the game's existing countdown UI.
func play_countdown(duration := 3.0) -> void:
	var tween := create_tween()
	tween.tween_method(_set_countdown_energy, 0.0, 0.72, duration * 0.82)
	tween.tween_method(_set_countdown_energy, 0.72, 1.0, duration * 0.18)
	tween.tween_method(_set_countdown_energy, 1.0, 0.0, 0.45)


func _set_countdown_energy(value: float) -> void:
	_material.set_shader_parameter("countdown_energy", value)


## A smoothed 0..1 music-energy value can make the sun and flowers pulse.
func set_music_energy(value: float) -> void:
	_material.set_shader_parameter("music_energy", clampf(value, 0.0, 1.0))


## Progresses the sun from early Golden Bloom toward sunset.
func set_sunset_progress(value: float) -> void:
	_material.set_shader_parameter("sunset_progress", clampf(value, 0.0, 1.0))


## Sets the background's accessibility motion level without stopping Godot's TIME.
func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_material.set_shader_parameter("motion_amount", 0.0 if enabled else 1.0)


## 0=low, 1=medium, 2=high. Use low on slower web/mobile devices.
func set_quality(level: int) -> void:
	quality_level = clampi(level, 0, 2)
	_material.set_shader_parameter("quality_level", quality_level)

