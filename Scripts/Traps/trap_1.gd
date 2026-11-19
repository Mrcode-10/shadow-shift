extends Traps

func _on_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "hit" :
		queue_free()
