class_name Player extends "res://scenes/characters/character.gd"

@onready var enemy_slots: Array = $EnemySlots.get_children()

func handle_evnet():
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed * speed_scale
	if Input.is_action_just_pressed("attack") && can_attack():
		current_state = State.ATTACK
	if Input.is_action_just_pressed("jump") && can_jump():
		current_state = State.TAKEOFF
	if can_jumpkick() && Input.is_action_just_pressed("attack"):
		current_state = State.JUMPKICK

func reserve_slot(enemy: BasicEnemy) -> EnemySlot:
	var emputy_slops = enemy_slots.filter(
		func(slot:EnemySlot): return slot.is_free()
	)
	if emputy_slops.is_empty():
		return null
	# 取最近的一个
	enemy_slots.sort_custom(
		func(a:EnemySlot, b: EnemySlot):
			var a_dist = (a.global_position - enemy.global_position).length()
			var b_dist = (b.global_position - enemy.global_position).length()
			return a_dist < b_dist
	)
	enemy_slots[0].occupy(enemy)
	return enemy_slots[0]
	
func free_slot(enemy: BasicEnemy):
	for slot in enemy_slots:
		slot.free_up(enemy)
