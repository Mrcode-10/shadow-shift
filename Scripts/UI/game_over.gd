extends Control


@onready var animation_player : AnimationPlayer = $AnimationPlayer

func change_animation() -> void :
	animation_player.play("text_animtion")
