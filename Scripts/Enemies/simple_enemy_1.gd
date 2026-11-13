class_name SimpleEnemy1

extends CharacterBody2D

enum STATE {
	IDLE , HURT , FALL , JUMP , RUN , DEATH , ATTACK
}

var fire_file = preload("res://Scenes/Enemies/SimpleEnemy1Fire.tscn")
@export var health : float = 40
@export var damage : float = 10
var state : STATE = STATE.IDLE
@onready var sprite_animation : AnimatedSprite2D = $EnemyAnimatedSprite2D
var direction : float = 1.0
var is_player_entered : bool = false
@export var speed : float = 100
@onready var raycast_left_bottom : RayCast2D = $RayCastsNode2D/RayCastLeftBottom
@onready var raycast_right_bottom : RayCast2D = $RayCastsNode2D/RayCastRightBottom
@onready var raycast_left : RayCast2D = $RayCastsNode2D/RayCastLeft
@onready var raycast_right : RayCast2D = $RayCastsNode2D/RayCastRight
var is_invulnerable_or_dead : bool = false 
@onready var collision_shape : CollisionShape2D = $EnemyCollisionShape2D
@export var can_chase_player : bool = false
@onready var timer_attack : Timer = $TimerNodes/AttackTimer
@export var attack_timer : float = 2
var player : Node2D
var is_player_in_area_left : bool = false
var is_player_in_area_right : bool = false
@onready var target_left : Node2D = $TargetNodes/TargetLeft
@onready var target_right : Node2D = $TargetNodes/TargetRight
@export var first_attack_delay : float = 1

func _ready() -> void:
	timer_attack.wait_time = attack_timer
	if not timer_attack.timeout.is_connected(timer_attack_timeout) :
		timer_attack.timeout.connect(timer_attack_timeout)

func _physics_process(delta: float) -> void:
	velocity.x = 0
	if not is_on_floor() :
		velocity += get_gravity() * delta

	# Handle enemy movement
	if state == STATE.RUN :
		change_direction()
		if is_on_floor() :
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
		if is_player_entered :
			change_state(STATE.RUN)
		
		else:
			change_state(STATE.IDLE)
	
	else :
		if velocity.y > 0 :
			change_state(STATE.FALL)
		else :
			change_state(STATE.JUMP)

func update_flip_h() -> void :
	if velocity.x > 0 :
		if sprite_animation.flip_h :
			sprite_animation.flip_h = false
	elif velocity.x < 0 :
		if not sprite_animation.flip_h :
			sprite_animation.flip_h = true

func match_state() -> void:
	match state :
		STATE.IDLE :
			sprite_animation.play("idle")
		
		STATE.HURT :
			sprite_animation.play("hurt")
			if not timer_attack.is_stopped() :
				timer_attack.paused = true
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
	if can_chase_player :
		player = body
	is_player_entered = true
	change_state(STATE.RUN)

func take_damage(damage_number:float) -> void :
	# DEBUG BEGIN
	if OS.is_debug_build():
		print("Enemy get damage from player : enemy side")
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
			#timer_attack.start()
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
	
	if is_player_in_area_right and not sprite_animation.flip_h :
		spawn_fire(1 , target_right)

func spawn_fire(direction_value : float , target_node : Node2D) -> void :
	var fire : SimpleEnemyFire = fire_file.instantiate()
	fire.direction = direction_value
	fire.global_position = target_node.global_position
	get_tree().current_scene.add_child(fire)

func timer_attack_timeout() -> void :
	if state == STATE.HURT or state == STATE.DEATH :
		return
	#if 
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()


func _on_area_left_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	if state == STATE.DEATH or state == STATE.HURT : 
		return
	is_player_in_area_left = true
	await get_tree().create_timer(first_attack_delay).timeout
	if not is_inside_tree() and state == STATE.HURT or state == STATE.DEATH :
		return
	#if 
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()

func _on_area_left_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	if not timer_attack.is_stopped() and not is_player_in_area_left and not is_player_in_area_right :
		timer_attack.stop()
	is_player_in_area_left = false


func _on_area_right_body_entered(body: Node2D) -> void:
	if body is not Player :
		return
	if state == STATE.DEATH or state == STATE.HURT : 
		return
	is_player_in_area_right = true
	await get_tree().create_timer(first_attack_delay).timeout
	if  not is_inside_tree() and  state == STATE.DEATH or state == STATE.HURT : 
		return
	change_state(STATE.ATTACK)
	if timer_attack.is_stopped() :
		timer_attack.start()


func _on_area_right_body_exited(body: Node2D) -> void:
	if body is not Player :
		return
	if not timer_attack.is_stopped() and not is_player_in_area_left and not is_player_in_area_right :
		timer_attack.stop()
	is_player_in_area_right = false

func _on_enemy_animated_sprite_2d_frame_changed() -> void:
	if state == STATE.ATTACK and sprite_animation.frame == 3 :
		attack()
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("enemy attack to player")
		# END DEBUG
