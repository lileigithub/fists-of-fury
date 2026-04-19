class_name Player extends "res://scenes/characters/character.gd"

@onready var enemy_slots: Array = $EnemySlots.get_children()

func _ready() -> void:
	super._ready()
	attak_animations = ["punch", "punch_alt", "kick", "roundkick"]

func handle_evnet():
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed * speed_scale
	if Input.is_action_just_pressed("attack") && can_attack():
		if has_knife:
			current_state = State.THROW
		else:
			current_state = State.ATTACK
			if last_attack_hited:
				combo_index = (combo_index + 1) % attak_animations.size()
			else:
				combo_index = 0
			last_attack_hited = false
	if Input.is_action_just_pressed("jump") && can_jump():
		current_state = State.TAKEOFF
	if can_jumpkick() && Input.is_action_just_pressed("attack"):
		current_state = State.JUMPKICK
		last_attack_hited = false

func reserve_slot(enemy: BasicEnemy) -> EnemySlot:
	assert(enemy != null)
	var empty_slops = enemy_slots.filter(
		func(slot:EnemySlot): return slot.is_free()
	)
	if empty_slops.is_empty():
		return null
	# 取最近的一个
	empty_slops.sort_custom(
		func(a:EnemySlot, b: EnemySlot):
			var a_dist = (a.global_position - enemy.global_position).length()
			var b_dist = (b.global_position - enemy.global_position).length()
			return a_dist < b_dist
	)
	empty_slops[0].occupy(enemy)
	return empty_slops[0]
	
func free_slot(enemy: BasicEnemy):
	for slot in enemy_slots:
		slot.free_up(enemy)

func handle_heading():
	if velocity.x > 0:
		heading = Vector2.RIGHT
	elif velocity.x < 0:
		heading = Vector2.LEFT
