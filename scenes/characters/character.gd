class_name Character extends CharacterBody2D

const GRAVITY = 600.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite2D
@onready var damage_emitter := $DamageEmitter
@onready var collateralDemageEmitter : Area2D = $CollateralDemageEmitter
@onready var damage_receiver :DamageReceiver = $DamageReceiver
@onready var collision_shape :CollisionShape2D = $CollisionShape2D
@onready var knife_sprite:Sprite2D = $KnifeSprite
@onready var projectile_aim:RayCast2D = $ProjectileAim
@onready var collectible_senser : Area2D = $ColletibleSenser
@onready var weapen_position : Node2D = $KnifeSprite/WeapenPosition

@export var damage:int
@export var power_damage:int
@export var max_health:int
@export var speed:float
@export var jump_intensity:float
@export var knockback_intensity:float
@export var knockdown_intensity:float
@export var fly_intensity:float
@export var duration_ground_ms:float = 2000
@export var has_knife:= false:
	set(value):
		if has_knife and not value:
			last_miss_knife_time = Time.get_ticks_msec()
		has_knife = value
@export var can_respawn_knife:= false
@export var duration_respawn_knife_ms:int = 2000

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT, FALL, GROUNDED, DEATH, FLY, PRE_HIT, THROW, PICKUP}
var attak_animations : Array
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
	State.DEATH: "grounded",
	State.FLY: "fly",
	State.PRE_HIT: "idle",
	State.THROW:"throw",
	State.PICKUP:"pickup"
}
var current_state := State.IDLE
var height = 0.0
var height_speed = 0.0
var speed_scale = 1.0
var current_health
var time_since_ground = Time.get_ticks_msec()
var combo_index : int = 0
var last_attack_hited : bool = false
var heading := Vector2.RIGHT
var last_miss_knife_time = Time.get_ticks_msec()


func _ready() -> void:
	current_health = max_health
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	collateralDemageEmitter.area_entered.connect(on_emit_collateral_damge.bind())
	collateralDemageEmitter.body_entered.connect(on_wall_hit.bind())

func _process(delta: float) -> void:
	handle_evnet()
	handle_movement()
	handle_air_time(delta)
	handle_pre_hit()
	handle_ground()
	handle_respawn_knife()
	handle_death(delta)
	handle_collision()
	handle_knife()
	flip_sprites()
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
	if current_state == State.GROUNDED \
		&& (Time.get_ticks_msec() - time_since_ground) >= duration_ground_ms:
		if current_health <= 0:
			current_state = State.DEATH
		else:
			current_state = State.LAND

func handle_death(delta:float):
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		modulate.a -= delta /2
		if modulate.a <= 0:
			queue_free()

func handle_collision():
	# 一些状态不应该碰撞
	collision_shape.disabled =  [State.GROUNDED, State.DEATH, State.FALL, State.FLY].has(current_state)
	# 一些状态不应该发送攻击
	damage_receiver.get_child(0).disabled = [State.GROUNDED, State.DEATH].has(current_state)
	
func handle_heading():
	pass
	
func handle_knife():
	knife_sprite.visible = has_knife
	knife_sprite.position = Vector2.UP * height
	
func handle_respawn_knife():
	if not has_knife and can_respawn_knife and  Time.get_ticks_msec() - last_miss_knife_time > duration_respawn_knife_ms:
		has_knife = true
		
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
		# 这里的position是精灵相对于父节点的位置，只变高度就可以（父节点的globle position没有改变）。
		character_sprite.position = Vector2.UP * height
		
func handle_pre_hit():
	pass
	
func on_emit_damage(receiver : DamageReceiver):
	var hit_type = DamageReceiver.HitType.NORMAL
	last_attack_hited = true
	if current_state == State.JUMPKICK:
		hit_type = DamageReceiver.HitType.KICKDOWN
	if current_state == State.ATTACK and combo_index == attak_animations.size()-1:
		hit_type = DamageReceiver.HitType.POWER
	var direction = Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
	receiver.damage_received.emit(damage, direction, hit_type)
	
func on_receive_damage(amount : int, direction:Vector2, hit_type: DamageReceiver.HitType):
	if can_get_hurt():
		if can_respawn_knife:
			can_respawn_knife = false
		if has_knife:
			has_knife = false
		current_health = clamp(current_health - amount, 0, max_health)
		if hit_type == DamageReceiver.HitType.KICKDOWN:
			current_state = State.FLY
			height_speed = knockdown_intensity
			velocity = direction * fly_intensity
		elif current_health <= 0 || hit_type == DamageReceiver.HitType.POWER:
			current_state = State.FALL
			height_speed = knockdown_intensity
			velocity = direction * knockback_intensity
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
	
func on_wall_hit(_wall : StaticBody2D):
	current_state = State.FALL
	height_speed = knockdown_intensity
	velocity = -velocity/2

func on_throw_complete():
	has_knife = false
	current_state = State.IDLE
	EntityManager.spawn_collectible.emit(Collectible.Type.KNIFE, Collectible.State.FLY, \
	weapen_position.global_position, heading)

func on_emit_collateral_damge(receiver : DamageReceiver):
	if receiver != damage_receiver:
		var direction = Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
		receiver.damage_received.emit(0, direction, DamageReceiver.HitType.POWER)

func on_pickup_complete():
	current_state = State.IDLE
	# 拾取物品
	pickup_colletible()
	pass

func pickup_colletible():
	if can_pickup_colletible():
		var collectible_areas := collectible_senser.get_overlapping_areas()
		var collectible : Collectible = collectible_areas[0]
		if collectible.type == Collectible.Type.KNIFE and not has_knife:
			has_knife = true
			collectible.queue_free()

func can_pickup_colletible() -> bool:
	var collectible_areas := collectible_senser.get_overlapping_areas()
	if collectible_areas.size() == 0:
		return false
	var collectible : Collectible = collectible_areas[0]
	if collectible.type == Collectible.Type.KNIFE and not has_knife:
		return true
	return false

func can_get_hurt() -> bool:
	return [State.IDLE, State.WALK, State.TAKEOFF, State.LAND].has(current_state)
		
func can_attack() -> bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_move()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jump()->bool:
	return current_state == State.IDLE || current_state == State.WALK

func can_jumpkick()->bool:
	return current_state == State.JUMP
	
func flip_sprites():
	handle_heading()
	if heading == Vector2.RIGHT:
		character_sprite.flip_h = false
		knife_sprite.flip_h = false
		damage_emitter.scale.x = 1
		projectile_aim.scale.x = 1
	else:
		character_sprite.flip_h = true
		knife_sprite.flip_h = true
		damage_emitter.scale.x = -1
		projectile_aim.scale.x = -1

		

	
		
		
