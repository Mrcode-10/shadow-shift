class_name ContinuousDamageTrap

extends StaticBody2D

@onready var trap_area : Area2D = $TrapArea2D
@export var damage : float = 5
@onready var timer : Timer = $Timer
var can_damage : bool = true

func _physics_process(delta: float) -> void:
	if not can_damage : 
		return
	for body in trap_area.get_overlapping_bodies() :
		if body is Player :
			body.take_damage_for_player(damage)
		elif body.has_method("take_damage") :
			body.take_damage(damage)
	can_damage = false
	if timer.is_stopped() :
		timer.start()
	
func timer_timeout() -> void :
	can_damage = true
