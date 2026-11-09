extends CharacterBody2D

enum STATE {
	IDLE , RUNNING , RUN_ATTACK , DEATH , HURT , ATTACK , JUMP , FALL
}

var state : STATE = STATE.IDLE
@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@onready var animation_sprite : AnimatedSprite2D = $PlayerAnimatedSprite2D

func _physics_process(delta: float) -> void:
	update_flip_h()
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if state == STATE.ATTACK or state == STATE.HURT :
		move_and_slide()
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	
	# Handle stop running when player use attack
	if direction == 0 and state == STATE.RUN_ATTACK:
		update_animation()
		# TODO
		# finish attack
		
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	move_and_slide()
	# Handle animation
	if state == STATE.DEATH or state == STATE.RUN_ATTACK :
		return
	update_animation()

func change_state(new_state : STATE) -> void :
	if state != new_state :
		state = new_state
		check_state()

func check_state() -> void :
	# Handle state functions
	match state : 
		STATE.IDLE :
			animation_sprite.play("idle")
		
		STATE.RUNNING :
			animation_sprite.play("running")
		
		STATE.RUN_ATTACK :
			animation_sprite.play("run_attack")
			
		STATE.DEATH :
			animation_sprite.play("death")
		
		STATE.HURT :
			animation_sprite.play("hurt")
		
		STATE.ATTACK :
			animation_sprite.play("attack")
		
		STATE.FALL :
			animation_sprite.play("fall")
		
		STATE.JUMP :
			animation_sprite.play("jump")

func update_animation() -> void :
	# Handle running and jump and fall and idle animation
	if is_on_floor() :
		if abs(velocity.x) > 0.1 :
			change_state(STATE.RUNNING)
		else :
			change_state(STATE.IDLE)
	
	else :
		if velocity.y > 0 :
			change_state(STATE.FALL)
			
		else :
			change_state(STATE.JUMP)
	
func update_flip_h() -> void :
	# Handle player rotation to left and right
	if velocity.x > 0.1 :
		if animation_sprite.flip_h :
			animation_sprite.flip_h = false
	
	elif velocity.x < -0.1 :
		if not animation_sprite.flip_h :
			animation_sprite.flip_h = true
	
	
func _unhandled_input(event: InputEvent) -> void:
	# Handle player input actions
	if event.is_action_pressed("attack") and state != STATE.DEATH and state != STATE.HURT :
		if abs(velocity.x) < 0.1 :
			change_state(STATE.ATTACK)
		
		else : 
			change_state(STATE.RUN_ATTACK)
		


func _on_player_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "attack" or animation_sprite.animation == "run_attack":
		update_animation()
