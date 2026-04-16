extends StaticBody2D

@onready var demageReceiver = $DemageReceiver
@onready var sprite = $Sprite2D
@export var knockback_intensity:float

enum State{IDLE, DESTROYED}

var height = 0.0
var velocity := Vector2.ZERO
var height_speed := 0.0
var state = State.IDLE
const GRAVITY = 600.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	demageReceiver.damage_received.connect(on_receive_damage.bind())

func _process(delta:float):
	position += velocity * delta
	handle_air_time(delta)

func on_receive_damage(_damage : int, direction:Vector2):
	if state == State.IDLE:
		velocity = direction * knockback_intensity
		height_speed = knockback_intensity * 2
		state = State.DESTROYED
		sprite.frame = 1

func handle_air_time(delta:float):
	if state == State.DESTROYED:
		sprite.modulate.a -= delta
		height += height_speed * delta
		if height < 0:
			height = 0
			queue_free()
		else:
			height_speed -= GRAVITY * delta
		sprite.position = Vector2.UP * height
