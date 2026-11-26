extends Control

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
