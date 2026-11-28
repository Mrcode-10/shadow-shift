extends Control

@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer

func _on_you_tube_button_pressed() -> void:
	OS.shell_open("https://www.youtube.com/@ShadowCoreStudio-i7r")

func _on_studio_button_pressed() -> void:
	OS.shell_open("https://mrcode-10.github.io/my-awesome-site/")


func _on_git_hub_button_pressed() -> void:
	OS.shell_open("https://github.com/Mrcode-10")


func _on_play_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level1.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

const __GOOD_VIBE_UPBEAT_ROCK__JELLY_BLOB = preload("uid://dpc0v1raikti2")

func _on_audio_stream_player_finished() -> void:
	audio_stream_player.stream = __GOOD_VIBE_UPBEAT_ROCK__JELLY_BLOB
	audio_stream_player.play()
