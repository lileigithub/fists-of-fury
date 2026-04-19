class_name Collectible extends Area2D

const GRAVITY := 600.0

@onready var collectible_sprite : Sprite2D = $CollectibleSprite
@onready var animation_player : AnimationPlayer = $AnimationPlayer

@export var knockdown_intensity : float = 150
@export var type = Type.KNIFE

enum Type {KNIFE, GUN, FOOD}
enum State {FALL, GROUNDED, FLY}
var anim_map := {
	State.FALL : "fall",
	State.GROUNDED : "grounded",
	State.FLY : "fly"
}
var current_state := State.FALL
var height:=0.0
var height_speed:= 0.0

func _ready() -> void:
	height_speed = knockdown_intensity 


func _process(delta: float) -> void:
	handle_fall(delta)
	handle_animations()
	
func handle_fall(delta: float):
	if current_state == State.FALL:
		height += height_speed * delta
		if height < 0:
			height = 0
			current_state = State.GROUNDED
		else:
			height_speed -= GRAVITY * delta
		collectible_sprite.position = Vector2.UP * height
	
func handle_animations():
	animation_player.play(anim_map[current_state])
