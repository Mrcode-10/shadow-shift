extends StaticBody2D

enum STATE {
	DEFUALT , HIT
}

var state : STATE = STATE.DEFUALT
@onready var animation_sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var damage : float = 10
@onready var trap_area : Area2D = $TrapArea2D


func change_state(new_state : STATE) : 
	if state != new_state :
		state = new_state
		match state :
			STATE.DEFUALT :
				animation_sprite.play("default")
			
			STATE.HIT :
				animation_sprite.play("hit")

func _on_trap_area_2d_body_entered(body: Node2D) -> void:
	if state == STATE.HIT :
		return
	change_state(STATE.HIT)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "hit" :
		change_state(STATE.DEFUALT)


func _on_animated_sprite_2d_frame_changed() -> void:
	if state == STATE.HIT and animation_sprite.frame == 5 :
		for body in trap_area.get_overlapping_bodies() :
			if body is Player :
				body.take_damage_for_player(damage)
			elif body.has_method("take_damage") :
				body.take_damage(damage)
