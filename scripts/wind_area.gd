extends Area2D

var color = ""
var active = false
var radius = 96
var power = 150

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape2D.shape.radius = radius


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		for player in get_overlapping_bodies():
			if player is Player and player.player_color != color:
				player.velocity += (power * radius * global_position.direction_to(player.global_position) * delta) / (global_position - player.global_position).length()

func enable(timer):
	active = true
	visible = true
	monitoring = true
	$CPUParticles2D.emitting = true
	$Timer.wait_time = timer
	
func disable():
	active = false
	visible = false
	monitoring = false
	$CPUParticles2D.emitting = false
	queue_free()
