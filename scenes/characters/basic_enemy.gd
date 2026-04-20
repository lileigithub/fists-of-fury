class_name  BasicEnemy extends "res://scenes/characters/character.gd"

const EDGE_SCREEN_BUGGER:int = 10

@export var player :Player
@export var duration_melle_attacks_ms:int
@export var duration_pre_melle_attack_ms:int
@export var duration_range_attacks_ms:int
@export var duration_pre_range_attack_ms:int

var last_melle_attack_time:int = Time.get_ticks_msec()
var last_prd_melle_attack_time:int = Time.get_ticks_msec()
var last_prd_range_attack_time:int = Time.get_ticks_msec()

var slot:EnemySlot = null

#给新开发者的建议：
#第一步。跟着类似的教程做。
#第二步。想一个非常简单的游戏创意。
#第三步。试着用你掌握的知识来做那个游戏。
#第四步。当你不可避免地遇到一个你不知道该怎么添加的功能时，可以专门看那个功能相关的教程。
#步骤5。做多个小项目，少做教程，开始更多依赖文档，直到你变得更独立。
#第六步。你现在已经流利掌握游戏开发了。干得好！


func _ready() -> void:
	super._ready()
	attak_animations = ["punch", "punch_alt"]
	assert(player != null)

func handle_evnet():
	if player != null && can_move():
		if can_respawn_knife or has_knife:
			goto_range_position()
		else:
			goto_melle_position()
	pass

func goto_range_position():
	var camera := get_viewport().get_camera_2d()
	var screen_width := get_viewport_rect().size.x
	var left_posizion := Vector2(camera.position.x - screen_width/2 + EDGE_SCREEN_BUGGER, player.position.y)
	var right_posizion := Vector2(camera.position.x + screen_width/2 - EDGE_SCREEN_BUGGER, player.position.y)
	var dist = left_posizion - position if (left_posizion - position).length() < (right_posizion - position).length() else right_posizion - position
	if dist.length() < 1:
		velocity = Vector2.ZERO
	else:
		velocity = dist.normalized() * speed
	if can_throw():
		current_state = State.THROW

func goto_melle_position():
	# 申请槽位
	if can_pickup_colletible():
		current_state = State.PICKUP
		if slot != null:
			player.free_slot(self)
	elif slot == null:
	#if slot == null:
		slot = player.reserve_slot(self)
	if slot != null:
		var dist = slot.global_position - global_position
		if dist.length() < 1:
			velocity = Vector2.ZERO
			if can_attack():
				last_prd_melle_attack_time = Time.get_ticks_msec()
				current_state = State.PRE_HIT
		else:
			velocity = dist.normalized() * speed

func handle_heading():
	if can_move() and player != null :
		if player.position.x < position.x:
			heading = Vector2.LEFT
		else:
			heading = Vector2.RIGHT
			
func handle_pre_hit():
	if current_state == State.PRE_HIT:
		if Time.get_ticks_msec() - last_prd_melle_attack_time > duration_pre_melle_attack_ms:
			current_state = State.ATTACK
			attak_animations.shuffle()
			last_melle_attack_time = Time.get_ticks_msec()

func on_receive_damage(amount : int, direction:Vector2, hit_type:DamageReceiver.HitType):
	super.on_receive_damage(amount, direction, hit_type)
	if current_health <= 0:
		if slot != null:
			slot.free_up(self)
			slot = null
			
func on_action_completed():
	current_state = State.IDLE
	velocity = Vector2.ZERO

func can_attack() -> bool:
	return Time.get_ticks_msec() - last_melle_attack_time > duration_melle_attacks_ms and super.can_attack()
	
func can_throw() -> bool:
	return has_knife and  Time.get_ticks_msec() - last_miss_knife_time > duration_range_attacks_ms \
	and projectile_aim.is_colliding() and super.can_attack() 
