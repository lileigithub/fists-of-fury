class_name  BasicEnemy extends "res://scenes/characters/character.gd"

@export var player :Player
var slot

func handle_evnet():
	if player != null && can_move():
		# 申请槽位
		if slot == null:
			slot = player.reserve_slot(self)
		else:
			var dist = slot.global_position - global_position
			var direction = dist.normalized()
			if dist.length() < 1:
				velocity = Vector2.ZERO
			else:
				velocity = direction * speed
	else:
			velocity = Vector2.ZERO

func on_receive_damage(amount : int, direction:Vector2):
	super.on_receive_damage(amount, direction)
	if current_health <= 0:
		# todo
		pass
		
