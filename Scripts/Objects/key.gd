extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player :
		PlayerManager.has_key = true
		queue_free()
