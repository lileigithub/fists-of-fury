extends CharacterBody2D

const GRAVITY = 600.0

@onready var animationPlayer := $AnimationPlayer
@onready var characterSprite := $CharacterSprite2D
@onready var demageEmitter := $DemageEmitter
@export var demage:int
@export var health:int
@export var speed:float
@export var jump_intensity:float

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK}
var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.ATTACK: "punch",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
	State.JUMPKICK: "jumpkick"
}
var current_state := State.IDLE
var height = 0.0
var height_speed = 0.0
var speed_scale = 1.0

func _ready() -> void:
	demageEmitter.area_entered.connect(on_emit_damage.bind())

func _process(delta: float) -> void:
	handle_evnet()
	handle_movement()
	flip_sprites()
	handle_air_time(delta)
	handle_animation()
	move_and_slide()
	
func handle_evnet():
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed * speed_scale
	if Input.is_action_just_pressed("attack") && can_attack():
		current_state = State.ATTACK
	if Input.is_action_just_pressed("jump") && can_jump():
		current_state = State.TAKEOFF
	if can_jumpkick() && Input.is_action_just_pressed("attack"):
		current_state = State.JUMPKICK

func handle_movement():
	if can_move():
		if velocity.length() > 0:
			current_state = State.WALK
		else:
			current_state = State.IDLE

func handle_animation():
	if anim_map.has(current_state):
		animationPlayer.play(anim_map[current_state])

func flip_sprites():
	if velocity.x > 0:
		characterSprite.flip_h = 0
		demageEmitter.scale.x = 1
	elif velocity.x < 0:
		characterSprite.flip_h = 1
		demageEmitter.scale.x = -1
		
func can_attack() -> bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_move()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jump()->bool:
	return current_state == State.IDLE || current_state == State.WALK
func can_jumpkick()->bool:
	return current_state == State.JUMP
		
func on_punch_completed():
	current_state = State.IDLE

func on_takeoff_complete():
	current_state = State.JUMP
	height_speed = jump_intensity
	

func on_land_complete():
	current_state = State.IDLE
		
func on_emit_damage(demage_receiver : DamageReceiver):
	prints(demage_receiver)
	var direction = Vector2.LEFT if demage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	demage_receiver.damage_received.emit(demage, direction)

func handle_air_time(delta:float):
	if current_state == State.JUMP || current_state == State.JUMPKICK:
		height += height_speed * delta
		if height < 0:
			height = 0
			current_state = State.LAND
			speed_scale = 1.0
		else:
			height_speed -= GRAVITY * delta
			if current_state == State.JUMPKICK:
				speed_scale = 2
		characterSprite.position = Vector2.UP * height
		
		
		
