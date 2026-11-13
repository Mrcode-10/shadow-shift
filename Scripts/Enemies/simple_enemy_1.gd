class_name SimpleEnemy1

extends CharacterBody2D

enum STATE {
	IDLE , HURT , FALL , JUMP , RUN , DEATH , ATTACK
}

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
		
func change_state(new_state : STATE) -> void:
	if new_state != state and state != STATE.DEATH :
		state = new_state
		match_state()
		
func update_animation() -> void :
	if state == STATE.HURT :
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
	is_player_entered = true
	change_state(STATE.RUN)

func take_damage(damage:float) -> void :
	# DEBUG BEGIN
	if OS.is_debug_build():
		print("Enemy get damage from player : enemy side")
	# DEBUG END
	if not is_invulnerable_or_dead :
		health = maxf(health-damage,0)
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
		change_state(STATE.RUN)
		update_animation()
	elif sprite_animation.animation == "death" :
		queue_free()
