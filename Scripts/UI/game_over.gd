extends Control

var main_menu_file := preload("res://Scenes/UI/main_menu.tscn")
@onready var animation_player : AnimationPlayer = $AnimationPlayer

func change_animation() -> void :
	animation_player.play("text_animtion")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("main_menu") :
		get_tree().change_scene_to_packed(main_menu_file)
	
	elif event.is_action_pressed("reload_game") :
		match PlayerManager.level :
			PlayerManager.LEVELS.LEVEL1 :
				PlayerManager.reset()
				get_tree().change_scene_to_file("res://Scenes/Levels/level1.tscn")
				
			PlayerManager.LEVELS.BOSS_LEVEL :
				# TODO write this part
				get_tree().change_scene_to_file("res://Scenes/Levels/boss_level.tscn")
