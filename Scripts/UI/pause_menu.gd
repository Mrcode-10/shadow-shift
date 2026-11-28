extends Control

@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer


func resume_game_button() -> void :
	get_tree().paused = false
	queue_free()
	
func quit_game_button() -> void :
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") :
		resume_game_button()
		
		
		
const __GOOD_VIBE_UPBEAT_PIXEL_POP__LIFE_IS_FULL_OF_JOY = preload("uid://dus8v0l2q4lfk")
func _on_audio_stream_player_finished() -> void:
	audio_stream_player.stream = __GOOD_VIBE_UPBEAT_PIXEL_POP__LIFE_IS_FULL_OF_JOY
	audio_stream_player.play()
