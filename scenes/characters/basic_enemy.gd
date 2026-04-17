class_name  BasicEnemy extends "res://scenes/characters/character.gd"

@export var player :Player
var slot:EnemySlot = null

func handle_evnet():
	if player != null && can_move():
		# 申请槽位
		if slot == null:
			slot = player.reserve_slot(self)
		if slot != null:
			var dist = slot.global_position - global_position
			var direction = dist.normalized()
			if dist.length() < 1:
				velocity = Vector2.ZERO
			else:
				velocity = direction * speed

func on_receive_damage(amount : int, direction:Vector2, hit_type:DamageReceiver.HitType):
	super.on_receive_damage(amount, direction, hit_type)
	if current_health <= 0:
		if slot != null:
			slot.free_up(self)
			slot = null
			
func on_action_completed():
	current_state = State.IDLE
	velocity = Vector2.ZERO
		
