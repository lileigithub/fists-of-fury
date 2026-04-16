class_name EnemySlot extends Node2D

var occupant : BasicEnemy = null

func is_free()->bool:
	return occupant == null
	
func free_up(enemy : BasicEnemy):
	if occupant != null && occupant == enemy:
		occupant = null
		
func occupy(enemy : BasicEnemy):
	if is_free():
		occupant = enemy
