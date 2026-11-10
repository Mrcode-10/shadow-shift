extends Node

var health : float = 100 :
	set(value) :
		health = value
		change_health.emit(health)
		
var killed_enemy_number : int = 0 :
	set(value) :
		killed_enemy_number = value
		change_killed_enemy_number.emit(killed_enemy_number)
		
var playing_time : float = 0.0 :
	set(value) :
		playing_time = value
		change_playing_timer.emit(playing_time)


func decrease_health(value : float ) -> void :
	health = max(0 , health - value)
	if health == 0 :
		player_death_signal.emit()
		
	else :
		player_get_hurt_signal.emit()
	
func increase_health(value : float) -> void :
	health = min(health + value , 100)
	
func increase_killed_enemy_number() -> void : 
	killed_enemy_number += 1
	
func increase_playing_timer() -> void :
	playing_time += 1

func reset() -> void :
	health = 100
	killed_enemy_number = 0
	playing_time = 0
	
signal change_health(value)
signal change_killed_enemy_number(value)
signal change_playing_timer(value)
signal player_get_hurt_signal
signal player_death_signal
