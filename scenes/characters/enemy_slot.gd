class_name EnemySlot extends Node2D

var occupant : BasicEnemy = null

func is_free()->bool:
	return occupant == null
	
func free_up(enemy : BasicEnemy) -> bool:
	if occupant != null && occupant == enemy:
		occupant = null
		return true
	return false
		
func occupy(enemy : BasicEnemy) -> bool:
	if is_free():
		occupant = enemy
		return true
	return false
