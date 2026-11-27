extends Control

func resume_game_button() -> void :
	get_tree().paused = false
	queue_free()
	
func quit_game_button() -> void :
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") :
		resume_game_button()
