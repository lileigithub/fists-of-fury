extends Node2D

var prefab_map : Dictionary[Collectible.Type, Resource]= {
	Collectible.Type.KNIFE : preload("res://scenes/props/knife.tscn")
}

func _ready() -> void:
	EntityManager.spawn_collectible.connect(on_spawn_collectible.bind())
	pass # Replace with function body.

func on_spawn_collectible(type:Collectible.Type, state:Collectible.State,\
	globle_position:Vector2, direction:Vector2):
	var collectible :Collectible = prefab_map[type].instantiate()
	collectible.type = type
	collectible.current_state = state
	collectible.global_position = globle_position
	collectible.direction = direction
	add_child(collectible)
