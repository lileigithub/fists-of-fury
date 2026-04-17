class_name Character extends CharacterBody2D

const GRAVITY = 600.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite2D
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver = $DamageReceiver
@onready var collision_shape := $CollisionShape2D

@export var damage:int
@export var max_health:int
@export var speed:float
@export var jump_intensity:float
@export var knockback_intensity:float
@export var knockdown_intensity:float
@export var duration_ground_ms:float

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT, FALL, GROUNDED, DEATH}
var attak_animations : Array = ["punch", "punch_alt", "kick", "roundkick"]
var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
	State.JUMPKICK: "jumpkick",
	State.HURT: "hurt",
	State.FALL: "fall",
	State.GROUNDED: "grounded",
	State.DEATH: "grounded"
}
var current_state := State.IDLE
var height = 0.0
var height_speed = 0.0
var speed_scale = 1.0
var current_health
var time_since_ground = Time.get_ticks_msec()
var combo_index : int = 0
var last_attack_hited : bool = false

func _ready() -> void:
	current_health = max_health
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())

func _process(delta: float) -> void:
	handle_evnet()
	handle_movement()
	flip_sprites()
	handle_air_time(delta)
	handle_ground()
	handle_death(delta)
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
	if current_state == State.ATTACK and animation_player.has_animation(attak_animations[combo_index]):
		animation_player.play(attak_animations[combo_index])
	elif animation_player.has_animation(anim_map[current_state]):
		animation_player.play(anim_map[current_state])

func handle_ground():
	collision_shape.disabled = current_state == State.GROUNDED
	if current_state == State.GROUNDED \
		&& (Time.get_ticks_msec() - time_since_ground) >= duration_ground_ms:
		if current_health <= 0:
			current_state = State.DEATH
		else:
			current_state = State.LAND

func handle_death(delta:float):
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		collision_shape.disabled = true
		modulate.a -= delta /2
		if modulate.a <= 0:
			queue_free()

func on_receive_damage(amount : int, direction:Vector2, hit_type: DamageReceiver.HitType):
	if can_get_hurt():
		current_health = clamp(current_health - amount, 0, max_health)
		if current_health <= 0 || hit_type == DamageReceiver.HitType.KICKDOWN:
			current_state = State.FALL
			height_speed = knockdown_intensity
		else:
			current_state = State.HURT
		velocity = direction * knockback_intensity

func on_action_completed():
	current_state = State.IDLE

func on_takeoff_complete():
	current_state = State.JUMP
	height_speed = jump_intensity

func on_land_complete():
	current_state = State.IDLE
		
func on_emit_damage(damage_receiver : DamageReceiver):
	var hit_type = DamageReceiver.HitType.NORMAL
	# todo last_attack_hited = true
	if current_state == State.JUMPKICK:
		hit_type = DamageReceiver.HitType.KICKDOWN
	var direction = Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	damage_receiver.damage_received.emit(damage, direction, hit_type)

func handle_air_time(delta:float):
	if [State.JUMP,State.JUMPKICK,State.FALL].has(current_state):
		height += height_speed * delta
		if height < 0:
			height = 0
			speed_scale = 1.0
			if current_state == State.FALL:
				current_state = State.GROUNDED
				time_since_ground = Time.get_ticks_msec()
			else:
				current_state = State.LAND
			velocity = Vector2.ZERO
		else:
			height_speed -= GRAVITY * delta
			if current_state == State.JUMPKICK:
				speed_scale = 2
		character_sprite.position = Vector2.UP * height

func can_get_hurt() -> bool:
	return not [State.JUMPKICK, State.HURT, State.FALL, State.GROUNDED, State.DEATH].has(current_state)
		
func can_attack() -> bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_move()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jump()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jumpkick()->bool:
	return current_state == State.JUMP
	
func flip_sprites():
	if velocity.x > 0:
		character_sprite.flip_h = 0
		damage_emitter.scale.x = 1
	elif velocity.x < 0:
		character_sprite.flip_h = 1
		damage_emitter.scale.x = -1
		

	
		
		
