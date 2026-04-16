class_name Character extends CharacterBody2D

const GRAVITY = 600.0

@onready var animationPlayer := $AnimationPlayer
@onready var characterSprite := $CharacterSprite2D
@onready var damageEmitter := $damageEmitter
@onready var damageReceiver = $damageReceiver

@export var damage:int
@export var max_health:int
@export var speed:float
@export var jump_intensity:float
@export var knockback_intensity:float

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT}
var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.ATTACK: "punch",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
	State.JUMPKICK: "jumpkick",
	State.HURT: "hurt"
}
var current_state := State.IDLE
var height = 0.0
var height_speed = 0.0
var speed_scale = 1.0
var current_health

func _ready() -> void:
	current_health = max_health
	damageEmitter.area_entered.connect(on_emit_damage.bind())
	damageReceiver.damage_received.connect(on_receive_damage.bind())

func _process(delta: float) -> void:
	handle_evnet()
	handle_movement()
	flip_sprites()
	handle_air_time(delta)
	handle_animation()
	move_and_slide()
	
func handle_evnet():
	pass

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
		damageEmitter.scale.x = 1
	elif velocity.x < 0:
		characterSprite.flip_h = 1
		damageEmitter.scale.x = -1
		
func can_attack() -> bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_move()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jump()->bool:
	return current_state == State.IDLE || current_state == State.WALK
func can_jumpkick()->bool:
	return current_state == State.JUMP
func can_hurt()->bool:
	return current_state != State.HURT
		
func on_action_completed():
	current_state = State.IDLE

func on_takeoff_complete():
	current_state = State.JUMP
	height_speed = jump_intensity
	

func on_land_complete():
	current_state = State.IDLE
		
func on_emit_damage(damage_receiver : DamageReceiver):
	prints(damage_receiver)
	var direction = Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	damage_receiver.damage_received.emit(damage, direction)

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
	

func on_receive_damage(amount : int, direction:Vector2):
	if can_hurt():
		current_health = clamp(current_health - amount, 0, max_health)
		prints(current_health)
		if current_health <=0:
			queue_free()
		else:
			current_state = State.HURT
			velocity = direction * knockback_intensity
		
		
