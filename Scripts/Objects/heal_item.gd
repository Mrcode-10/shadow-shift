extends Area2D

@export var heal_value : float = 20

func _on_body_entered(body: Node2D) -> void :
	if body is Player :
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("player health before heal : " + str(PlayerManager.health))
		# EBD DEBUG
		PlayerManager.increase_health(heal_value)
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("player health after heal : " + str(PlayerManager.health))
		# EBD DEBUG
		queue_free()
