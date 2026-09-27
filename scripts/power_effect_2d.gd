class_name PowerEffect2D extends Node2D

## Runtime host for the five procedural power-up shaders. The host is attached
## to the affected bee or hive, owns its material instance, and removes itself
## after the gameplay effect has finished.

const EFFECT_SHADERS := {
	"stinger": preload("res://shaders/stinger_strike.gdshader"),
	"rain": preload("res://shaders/rain_cloud.gdshader"),
	"swarm": preload("res://shaders/swarm_raid.gdshader"),
	"speed": preload("res://shaders/speedy_bee.gdshader"),
	"confusion": preload("res://shaders/confusion_cover.gdshader"),
}

const EFFECT_SIZES := {
	"stinger": Vector2(72, 44),
	"rain": Vector2(84, 84),
	"swarm": Vector2(104, 84),
	"speed": Vector2(88, 54),
	"confusion": Vector2(78, 78),
}

const EFFECT_OFFSETS := {
	"stinger": Vector2(0, 0),
	"rain": Vector2(0, -20),
	"swarm": Vector2(0, -12),
	"speed": Vector2(0, 0),
	"confusion": Vector2(0, -2),
}

var effect_name: StringName
var effect_duration: float
var target: Node2D
var effect_material: ShaderMaterial


static func spawn(target_node: Node2D, new_effect_name: StringName, duration: float) -> PowerEffect2D:
	if not EFFECT_SHADERS.has(new_effect_name):
		push_error("Unknown power shader: %s" % new_effect_name)
		return null

	var effect := PowerEffect2D.new()
	effect.effect_name = new_effect_name
	effect.effect_duration = maxf(duration, 0.05)
	effect.target = target_node
	target_node.add_child(effect)
	return effect


func _ready() -> void:
	position = EFFECT_OFFSETS[effect_name]
	z_index = 100

	var effect_rect := ColorRect.new()
	var effect_size: Vector2 = EFFECT_SIZES[effect_name]
	effect_rect.position = -effect_size * 0.5
	effect_rect.size = effect_size
	effect_rect.color = Color.WHITE
	effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	effect_material = ShaderMaterial.new()
	effect_material.shader = EFFECT_SHADERS[effect_name]
	effect_material.set_shader_parameter("progress", 0.0)
	effect_rect.material = effect_material
	add_child(effect_rect)

	_play_lifetime()


func _process(_delta: float) -> void:
	if effect_name in [&"stinger", &"speed"] and is_instance_valid(target):
		var horizontal_direction: float = target.direction.x if target is Player else 1.0
		if not is_zero_approx(horizontal_direction):
			effect_material.set_shader_parameter("facing", signf(horizontal_direction))


func _play_lifetime() -> void:
	var fade_time := minf(0.2, effect_duration * 0.25)
	var hold_time := maxf(0.0, effect_duration - fade_time * 2.0)
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 0.5, fade_time)
	if hold_time > 0.0:
		tween.tween_interval(hold_time)
	tween.tween_method(_set_progress, 0.5, 1.0, fade_time)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	effect_material.set_shader_parameter("progress", value)
