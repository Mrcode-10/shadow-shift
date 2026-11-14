class_name SimpleEnemy2

extends CharacterBody2D

enum STATE {
	IDLE , HURT , ON_AIR , JUMP , RUN , DEATH , ATTACK , LANDING
}

# TODO change this to true value
var fire_file = preload("res://Scenes/Enemies/SimpleEnemy1Fire.tscn")
@export var health : float = 60
@export var damage : float = 20
var state : STATE = STATE.IDLE
@onready var sprite_animation : AnimatedSprite2D = $SimpleEnemy2AnimatedSprite2D
var direction : float = 1.0
var is_player_entered : bool = false
@export var speed : float = 60
@onready var raycast_left_bottom : RayCast2D = $RayCastNodes/RayCastLeftBottom
@onready var raycast_right_bottom : RayCast2D = $RayCastNodes/RayCastRightBottom
@onready var raycast_left : RayCast2D = $RayCastNodes/RayCastLeft
@onready var raycast_right : RayCast2D = $RayCastNodes/RayCastRight
var is_invulnerable_or_dead : bool = false 
@onready var collision_shape_left : CollisionShape2D = $SimpleEnemy2CollisionShapeLeft
@onready var collision_shape_right : CollisionShape2D = $SimpleEnemy2CollisionShapeRight
@export var can_chase_player : bool = false
@onready var timer_attack : Timer = $Timers/AttackTimer
@export var attack_timer : float = 4
var player : Node2D
var is_player_in_area_left : bool = false
var is_player_in_area_right : bool = false
@onready var target_left : Node2D = $TargetNodes/LeftTarget
@onready var target_right : Node2D = $TargetNodes/RightTarget
@export var first_attack_delay : float = 2
@export var distance : float = 200
var should_move : bool = false
@onready var area_left : Area2D = $AreaNodes/AreaLeft
@onready var area_right : Area2D = $AreaNodes/AreaRight

func _ready() -> void:
	timer_attack.wait_time = attack_timer
	if not timer_attack.timeout.is_connected(timer_attack_timeout) :
		timer_attack.timeout.connect(timer_attack_timeout)

func _physics_process(delta: float) -> void:
	velocity.x = 0
	if not is_on_floor() :
		velocity += get_gravity() * delta

	# Handle enemy movement
	if state == STATE.RUN and player != null:
		should_move = true
		change_direction()
		if  global_position.distance_to(player.global_position) <= distance :
			if PlayerManager.flip_h and not sprite_animation.flip_h :
				if global_position.x < player.global_position.x :
					should_move = false
			elif not PlayerManager.flip_h and sprite_animation.flip_h :
				if player.global_position.x < global_position.x :
					should_move = false
				
		if is_on_floor() and should_move:
			velocity.x = speed * direction
		
	move_and_slide()
	# Animation Handle
	update_flip_h()
	update_animation()
	
func change_direction() -> void :
	# Handle direction
	if not raycast_left_bottom.is_colliding() and not raycast_right_bottom.is_colliding() :
		return
		
	elif raycast_left.is_colliding() or not raycast_left_bottom.is_colliding() :
		direction = 1
	
	elif raycast_right.is_colliding() or not raycast_right_bottom.is_colliding() :
		direction = -1
	
	if can_chase_player and player != null :
		chase_player()
		
func change_state(new_state : STATE) -> void:
	if new_state != state and state != STATE.DEATH :
		state = new_state
		match_state()
		
func update_animation() -> void :
	if state == STATE.HURT or state==STATE.ATTACK:
		return
	# Animation Handle
	if is_on_floor() :
		if is_player_entered and global_position.distance_to(player.global_position) > distance :
			change_state(STATE.RUN)
		
		else:
			change_state(STATE.IDLE)
	
	else :
		#TODO fix this part better
		if velocity.y > 0 :
			change_state(STATE.ON_AIR)
		else :
			change_state(STATE.JUMP)

func update_flip_h() -> void :
	if velocity.x > 0 :
		if sprite_animation.flip_h :
			sprite_animation.flip_h = false
			collision_shape_left.set_deferred("disabled" , true)
			collision_shape_right.set_deferred("disabled" , false)
	elif velocity.x < 0 :
		if not sprite_animation.flip_h :
			sprite_animation.flip_h = true
			collision_shape_left.set_deferred("disabled" , false)
			collision_shape_right.set_deferred("disabled" , true)
			
func match_state() -> void:
	match state :
		STATE.IDLE :
			sprite_animation.play("idle")
		
		STATE.HURT :
			sprite_animation.play("hurt")
			if not timer_attack.is_stopped() :
				timer_attack.paused = true
				#timer_attack.stop()
				
		STATE.ON_AIR :
			sprite_animation.play("on_air")
		
		STATE.JUMP :
			sprite_animation.play("jump")
			
		STATE.RUN :
			sprite_animation.play("run")
			
		STATE.DEATH :
			sprite_animation.play("death")

		STATE.ATTACK :
			sprite_animation.play("attack")
			
		STATE.LANDING :
			sprite_animation.play("landing")
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
		print("Enemy 2 get damage from player : enemy side")
	# DEBUG END
	if not is_invulnerable_or_dead :
		health = maxf(health-damage_number,0)
		# Death handle
		if health == 0 :
			death()
		# Hurt Handle
		else :
			change_state(STATE.HURT)
		
		is_invulnerable_or_dead = true	


func death() -> void :
	change_state(STATE.DEATH)

func _on_enemy_animated_sprite_2d_animation_finished() -> void:
	if sprite_animation.animation == "hurt" :
		is_invulnerable_or_dead = false
		if is_player_in_area_left or is_player_in_area_right :
			timer_attack.paused = false
			timer_attack.start()
		change_state(STATE.RUN)
		update_animation()
	elif sprite_animation.animation == "death" :
		queue_free()
	
	elif sprite_animation.animation == "attack" :
		change_state(STATE.RUN)
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

func attack() -> void :
	# Attack handle
	if is_player_in_area_left and sprite_animation.flip_h :
		spawn_fire(-1 , target_left)
		#DEBUG BEGIN
		if OS.is_debug_build() :
			print("Player in left" + " enemy flip h : " + str(sprite_animation.flip_h))
		#DEBUG END
	
	if is_player_in_area_right and not sprite_animation.flip_h :
		spawn_fire(1 , target_right)
		#DEBUG BEGIN
		if OS.is_debug_build() :
			print("Player in right" + " enemy flip h : " + str(sprite_animation.flip_h))
		#DEBUG END
		
func spawn_fire(direction_value : float , target_node : Node2D) -> void :
	var fire : SimpleEnemyFire = fire_file.instantiate()
	fire.direction = direction_value
	fire.global_position = target_node.global_position
	get_tree().current_scene.add_child(fire)

func timer_attack_timeout() -> void :
	if state == STATE.HURT or state == STATE.DEATH :
		return
	if is_player_in_area_left and not sprite_animation.flip_h :
		return
	elif is_player_in_area_right and sprite_animation.flip_h :
		return
	change_state(STATE.ATTACK)
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("enemy attack t")
	# DEBUG END


func _on_area_left_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	if state == STATE.DEATH or state == STATE.HURT : 
		return
	is_player_in_area_left = true
	await get_tree().create_timer(first_attack_delay).timeout
	if not is_inside_tree() or not area_left.overlaps_body(body) or state == STATE.HURT or state == STATE.DEATH or not sprite_animation.flip_h:
		return
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("Player enter left area")
	# DEBUG END

func _on_area_left_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	if not timer_attack.is_stopped()  :
		timer_attack.stop()
	is_player_in_area_left = false
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("Player exited left area")
	# DEBUG END


func _on_area_right_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	if state == STATE.DEATH or state == STATE.HURT : 
		return
	is_player_in_area_right = true
	await get_tree().create_timer(first_attack_delay).timeout
	if not is_inside_tree() or not area_right.overlaps_body(body) or state == STATE.DEATH or state == STATE.HURT or sprite_animation.flip_h: 
		return
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("Player enter right area")
	# DEBUG END
	
func _on_area_right_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	if not timer_attack.is_stopped() :
		timer_attack.stop()
	is_player_in_area_right = false
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("Player exited right area")
	# DEBUG END

func _on_enemy_animated_sprite_2d_frame_changed() -> void:
	if state == STATE.ATTACK and sprite_animation.frame == 3 :
		attack()
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("enemy attack to player")
		# END DEBUG
