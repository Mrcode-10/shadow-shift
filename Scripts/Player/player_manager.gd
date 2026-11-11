extends Node

var invincibility_frames_time : float = 0.5

var player_alive : bool = true

var player_can_get_damage : bool = true

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
	if player_can_get_damage and player_alive :
		health = maxf(0 , health - value)
		if health == 0 :
			player_death_signal.emit()
			player_alive = false
		
		else :
			player_get_hurt_signal.emit()
		player_can_get_damage = false
		# DEBUG
		if OS.is_debug_build() :
			print("player can't get hurt now ")
			print("player health : " + str(health))
		invincibility_frames()
	
func increase_health(value : float) -> void :
	health = minf(health + value , 100)
	
func increase_killed_enemy_number() -> void : 
	killed_enemy_number += 1
	
func increase_playing_timer() -> void :
	playing_time += 1

func reset() -> void :
	health = 100
	killed_enemy_number = 0
	playing_time = 0
	player_alive = true
	player_can_get_damage = true

func  invincibility_frames() -> void :
	#  Add a short invincibility window after taking damage 
	await get_tree().create_timer(invincibility_frames_time).timeout
	player_can_get_damage = true
	# DEBUG
	if OS.is_debug_build() :
		print("player can get hurt now ")
	 
	
signal change_health(value)
signal change_killed_enemy_number(value)
signal change_playing_timer(value)
signal player_get_hurt_signal
signal player_death_signal
