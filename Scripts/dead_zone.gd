class_name DeadZone

extends Area2D


func dead_zone_player_entered(body : Node2D) -> void :
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("player enterd dead zone")
	# DEBUG END
	if body is Player :
		PlayerManager.decrease_health(1000)
		# DEBUG BEGIN
		if OS.is_debug_build() :
			print("player health : "+ str(PlayerManager.health))
		# DEBUG END
