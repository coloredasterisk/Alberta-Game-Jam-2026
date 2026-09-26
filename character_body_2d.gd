class_name Player extends CharacterBody2D
var speed: int = 100
var direction: Vector2
@onready var bee_animation: AnimatedSprite2D = $AnimatedSprite2D

const ACTIONS = {
	"move_left":  [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up":    [KEY_W, KEY_UP],
	"move_down":  [KEY_S, KEY_DOWN],
	"jump":       [KEY_SPACE],
}

func _ready():
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
			

func movement(delta):
	direction = Input.get_vector("move_left", "move_right", 'move_up', 'move_down')
	velocity = velocity.move_toward(direction * speed, 700 * delta)

func animation():
	if direction.x < 0:
		bee_animation.flip_h = true
	elif direction.x > 0:
		bee_animation.flip_h = false

func _physics_process(delta: float) -> void:
	animation()
	print(direction)
	movement(delta)
	move_and_slide()
