class_name SimpleEnemy4

extends CharacterBody2D

enum STATE {
	IDLE , HURT , FALL , JUMP , RUN , DEATH , ATTACK
}

## TODO change this to true value
#var fire_file = preload("res://Scenes/Enemies/simple_enemy_3_fire.tscn")
var is_distance_ok : bool = true
var health : float = 60
@export var max_health : float = 60
@export var shift_value : float = 1.2
@export var attack_damage : float = 20
@export var normal_damage : float = 5
var can_use_shift : bool = false
var state : STATE = STATE.IDLE
@onready var sprite_animation : AnimatedSprite2D = $AnimatedSprite2D
var direction : float = 1.0
var is_player_entered : bool = false
var is_edge : bool = false
@export var speed : float = 110
@onready var raycast_left_bottom : RayCast2D = $RayCastNodes/LeftBottomRayCast
@onready var raycast_right_bottom : RayCast2D = $RayCastNodes/RightBottomRayCast
@onready var raycast_left : RayCast2D = $RayCastNodes/LeftRayCast
@onready var raycast_right : RayCast2D = $RayCastNodes/RightRayCast
var is_invulnerable_or_dead : bool = false 
@onready var collision_shape_left : CollisionShape2D = $CollisionShapeLeft
@onready var collision_shape_right : CollisionShape2D = $CollisionShapeRight
@export var can_chase_player : bool = false
@onready var damage_to_player_timer : Timer = $TimerNodes/DamageToPlayer
@onready var damage_to_player_left : Area2D = $DamageToPlayerAreas/DamageToPlayerAreaLeft
@onready var damage_to_player_right : Area2D = $DamageToPlayerAreas/DamageToPlayerAreaRight
@onready var attack_left_area : Area2D = $AttackAreaNodes/AttackLeftArea
@onready var attack_right_area : Area2D = $AttackAreaNodes/AttackRightArea
@onready var timer_attack : Timer = $TimerNodes/AttackTimer
@export var attack_timer : float = 2
var player : Node2D
@export var first_attack_delay : float = 1
@export var distance : float = 30
var should_move : bool = false
var can_attack : bool = false
var is_dead : bool = false

func _ready() -> void:
	
	BossManager.boss_dead.connect(boss_dead_function)
	
	health = max_health
	
	PlayerManager.shift_signal.connect(shift_function)
	
	timer_attack.wait_time = attack_timer
	if not timer_attack.timeout.is_connected(timer_attack_timeout) :
		timer_attack.timeout.connect(timer_attack_timeout)

func _physics_process(delta: float) -> void:
	velocity.x = 0
	if not is_on_floor() :
		velocity += get_gravity() * delta

	# Handle enemy movement
	change_direction()
	if state == STATE.RUN and player != null:
		should_move = true
		if  global_position.distance_to(player.global_position) <= distance :
			if PlayerManager.flip_h and not sprite_animation.flip_h :
				if global_position.x < player.global_position.x :
					should_move = false
			elif not PlayerManager.flip_h and sprite_animation.flip_h :
				if player.global_position.x < global_position.x :
					should_move = false
				
		if is_on_floor() and should_move and not is_edge:
			velocity.x = speed * direction
		
	move_and_slide()
	# Animation Handle
	if not is_edge :
		update_flip_h()
	update_animation()
	
func change_direction() -> void :
	if can_chase_player and player != null :
		if not raycast_left_bottom.is_colliding() and not raycast_right_bottom.is_colliding() :
			return
		
		chase_player() 
		
		if (raycast_left.is_colliding() or not raycast_left_bottom.is_colliding()) and (direction == -1) :
			if state != STATE.DEATH and state != STATE.HURT :
				is_edge = true
					
		elif (raycast_right.is_colliding() or not raycast_right_bottom.is_colliding()) and (direction == 1) :
			if state != STATE.DEATH and state != STATE.HURT :
				is_edge = true
		
		else : 
			is_edge = false
		
	
	else :
		if raycast_left.is_colliding() or not raycast_left_bottom.is_colliding() :
			direction = 1
	
		elif raycast_right.is_colliding() or not raycast_right_bottom.is_colliding() :
			direction = -1
		
func change_state(new_state : STATE) -> void:
	if new_state != state and state != STATE.DEATH :
		if state == STATE.HURT and new_state != STATE.DEATH :
			is_invulnerable_or_dead = false
		state = new_state
		match_state()
		
func update_animation() -> void :
	if state == STATE.HURT or state==STATE.ATTACK:
		return
	# Animation Handle
	if is_on_floor() :
		if not is_edge and is_distance_ok and is_player_entered and global_position.distance_to(player.global_position) > distance :
			change_state(STATE.RUN)
		
		else:
			change_state(STATE.IDLE)
	
	else :
		#TODO fix this part better
		if velocity.y > 0 :
			change_state(STATE.FALL)
		else :
			change_state(STATE.JUMP)

func update_flip_h() -> void :
	if player != null :
		if abs(global_position.x - player.global_position.x) < 25 :
			velocity.x = 0
			if state != STATE.DEATH and state != STATE.HURT and state != STATE.ATTACK :
				change_state(STATE.IDLE)
			is_distance_ok = false
			return
		else :
			is_distance_ok = true
	else :
		is_distance_ok = true
	if velocity.x > 0 :
		if sprite_animation.flip_h :
			sprite_animation.flip_h = false
			collision_shape_left.set_deferred("disabled" , true)
			damage_to_player_left.set_deferred("monitoring" , false)
			attack_left_area.set_deferred("monitoring" , false)
			collision_shape_right.set_deferred("disabled" , false)
			damage_to_player_right.set_deferred("monitoring" , true)
			attack_right_area.set_deferred("monitoring" , true)
	elif velocity.x < 0 :
		if not sprite_animation.flip_h :
			sprite_animation.flip_h = true
			collision_shape_left.set_deferred("disabled" , false)
			damage_to_player_left.set_deferred("monitoring" , true)
			attack_left_area.set_deferred("monitoring" , true)
			collision_shape_right.set_deferred("disabled" , true)
			damage_to_player_right.set_deferred("monitoring" , false)
			attack_right_area.set_deferred("monitoring" , false)
			
func match_state() -> void:
	match state :
		STATE.IDLE :
			sprite_animation.play("idle")
		
		STATE.HURT :
			sprite_animation.play("hurt")
			#if not timer_attack.is_stopped() :
				#timer_attack.paused = true
				#timer_attack.stop()
				
		STATE.FALL :
			sprite_animation.play("fall")
		
		STATE.JUMP :
			sprite_animation.play("jump")
			
		STATE.RUN :
			sprite_animation.play("run")
			
		STATE.DEATH :
			sprite_animation.play("death")

		STATE.ATTACK :
			sprite_animation.play("attack")

		_:
			pass


func _on_wake_up_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	player = body
	is_player_entered = true
	change_state(STATE.RUN)

func take_damage(damage_number:float) -> void :
	# DEBUG BEGIN
	if OS.is_debug_build():
		print("Enemy 3 get damage from player : enemy side")
	# DEBUG END
	if not is_invulnerable_or_dead and not is_dead:
		health = maxf(health-damage_number,0)
		# Death handle
		if health == 0 :
			is_dead = true
			can_attack = false
			finish_attack()
			death()
		# Hurt Handle
		else :
			finish_attack()
			change_state(STATE.HURT)
		
		is_invulnerable_or_dead = true	


func death() -> void :
	collision_shape_left.set_deferred("disabled" , true)
	collision_shape_right.set_deferred("disabled" , true)
	damage_to_player_left.set_deferred("monitoring" , false)
	damage_to_player_right.set_deferred("monitoring" , false)
	if not damage_to_player_timer.is_stopped() :
		damage_to_player_timer.stop()
	change_state(STATE.DEATH)

func _on_enemy_animated_sprite_2d_animation_finished() -> void:
	if sprite_animation.animation == "hurt" :
		is_invulnerable_or_dead = false
		if can_attack :
			timer_attack.start()
		change_state(STATE.RUN)
		update_animation()
	elif sprite_animation.animation == "death" :
		queue_free()
	
	elif sprite_animation.animation == "attack" :
		change_state(STATE.IDLE)
		update_animation()


func chase_player() -> void :
	if player.global_position.x > global_position.x :
		direction = 1
	
	elif player.global_position.x < global_position.x :
		direction = -1
		


func _on_wake_up_area_2d_body_exited(body: Node2D) -> void:
	if body is Player :
		player = null
		is_player_entered = false
		change_state(STATE.IDLE)

# Damage To Player Handle

func _on_damage_to_player_area_right_body_entered(body: Node2D) -> void:
	# BEGIN DEBUG
	if OS.is_debug_build() :
		print("area work good right!")
	# END DEBUG
	if body.has_method("take_damage_for_player") :
		body.take_damage_for_player(normal_damage)
		if damage_to_player_timer.is_stopped() :
			damage_to_player_timer.start()
			# BRGIN DEBUG
			if OS.is_debug_build() :
				print("enemy attack to player 😎")
			# END DEBUG


func _on_damage_to_player_area_left_body_exited(body: Node2D) -> void:
	if not damage_to_player_timer.is_stopped() :
			damage_to_player_timer.stop()


func _on_damage_to_player_area_right_body_exited(body: Node2D) -> void:
	if not damage_to_player_timer.is_stopped() :
		damage_to_player_timer.stop()
	
func _on_damage_to_player_area_left_body_entered(body: Node2D) -> void:
	# BEGIN DEBUG
	if OS.is_debug_build() :
		print("area work good left !")
	# END DEBUG
	if body.has_method("take_damage_for_player") :
		body.take_damage_for_player(normal_damage)
		if damage_to_player_timer.is_stopped() :
			damage_to_player_timer.start()
			# BEGIN DEBUG
			if OS.is_debug_build() :
				print("enemy attack to player 😎")
			# END DEBUG


func _on_damage_to_player_timeout() -> void:
	if player == null :
		return
	player.take_damage_for_player(normal_damage)



# Attack Handle

func attack() -> void :
	# check player isn't null
	if player == null or not can_attack :
		return
		
	if player.has_method("take_damage_for_player") :
		player.take_damage_for_player(attack_damage)
			
func finish_attack() -> void :
	if not timer_attack.is_stopped() :
		timer_attack.stop()
	
func _on_attack_right_area_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	# after little delay attack to player
	await get_tree().create_timer(first_attack_delay).timeout
	if not is_inside_tree() or not attack_right_area.overlaps_body(body) or player == null or state==STATE.HURT or state == STATE.DEATH :
		return
	change_state(STATE.ATTACK)
	can_attack = true
	if timer_attack.is_stopped() :
		timer_attack.start()
	


func _on_attack_right_area_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	finish_attack()
	can_attack = false


func _on_attack_left_area_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	# after little delay attack to player
	await get_tree().create_timer(first_attack_delay).timeout
	if not is_inside_tree() or not attack_left_area.overlaps_body(body) or player == null or state==STATE.HURT or state == STATE.DEATH :
		return
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()
	can_attack = true


func _on_attack_left_area_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	finish_attack()
	can_attack = false


func _on_animated_sprite_2d_frame_changed() -> void:
	if state == STATE.ATTACK and sprite_animation.frame == 4 :
		attack()

func timer_attack_timeout() -> void :
	if not is_inside_tree() or player == null or state==STATE.HURT or state == STATE.DEATH or not can_attack:
		return
	change_state(STATE.ATTACK)


func shift_function() -> void : 
	if not can_use_shift :
		return
	
	if health > max_health / 2 :
		health = max_health
		attack_damage *= shift_value
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("shift up enemy4")
		# END DEBUG
	else : 
		take_damage(100)
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("shift down enemy4")
		# END DEBUG



func _on_shift_area_area_entered(area: Area2D) -> void:
	can_use_shift = true


func _on_shift_area_area_exited(area: Area2D) -> void:
	can_use_shift = false



func boss_dead_function() -> void :
	if state == STATE.DEATH :
		return
	is_invulnerable_or_dead = false
	take_damage(1000)
