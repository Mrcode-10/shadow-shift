extends StaticBody2D

enum STATE {
	DEFUALT , HIT
}

var state : STATE = STATE.DEFUALT
@onready var animation_sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var damage : float = 10
var player : Player

func change_state(new_state : STATE) : 
	if state != new_state :
		state = new_state
		match state :
			STATE.DEFUALT :
				animation_sprite.play("defualt")
			
			STATE.HIT :
				animation_sprite.play("hit")

func _on_trap_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and state == STATE.DEFUALT:
		player = body as Player
		change_state(STATE.HIT)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "hit" :
		queue_free()


func _on_animated_sprite_2d_frame_changed() -> void:
	if state == STATE.HIT and animation_sprite.frame == 5 and player != null :
		player.take_damage_for_player(damage)


func _on_trap_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and player != null :
		player = null
