extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color = Color(randf(), randf(), randf())
	if color.get_luminance() <= 0.5:
		color.lightened(0.25)
	modulate = color
