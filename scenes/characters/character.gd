extends CharacterBody2D
@onready var animationPlayer := $AnimationPlayer
@onready var characterSprite := $CharacterSprite2D
@onready var demageEmitter := $DemageEmitter
@export var demage:int
@export var health:int
@export var speed:float

enum State {IDLE, WALK, ATTACK}

var current_state := State.IDLE

func _ready() -> void:
	demageEmitter.area_entered.connect(on_emit_demage.bind())

func _process(_delta: float) -> void:
	handle_evnet()
	handle_movement()
	flip_sprites()
	handle_animation()
	move_and_slide()
	#position = position.round()
	
func handle_evnet():
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	if Input.is_action_pressed("punch") && can_attack():
		current_state = State.ATTACK

func handle_movement():
	if can_move():
		if velocity.length() > 0:
			current_state = State.WALK
		else:
			current_state = State.IDLE
	else:
		velocity = Vector2.ZERO

func handle_animation():
	if current_state == State.IDLE:
		animationPlayer.play("idle")
	elif current_state == State.WALK:
		animationPlayer.play("walk")
	elif current_state == State.ATTACK:
		animationPlayer.play("attack")
	else:
		animationPlayer.play("idle")

func flip_sprites():
	if velocity.x > 0:
		characterSprite.flip_h = 0
	elif velocity.x < 0:
		characterSprite.flip_h = 1
		
func can_attack() -> bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_move()->bool:
	return current_state == State.IDLE || current_state == State.WALK
		
func on_action_completed():
	current_state = State.IDLE
		
func on_emit_demage(area : Area2D):
	prints(area)
	pass
		
		
		
