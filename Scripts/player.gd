extends CharacterBody2D

enum STATE {
	IDLE , RUNNING , RUN_ATTACK , DEATH , HURT , ATTACK , JUMP , FALL , LAND
}

var can_jump : bool = true
var can_player_hard_landing : bool = false
var state : STATE = STATE.IDLE
@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var hard_landing_time_number : float = 0.5
@onready var animation_sprite : AnimatedSprite2D = $PlayerAnimatedSprite2D
@onready var hard_landing_timer : Timer = $Timers/HardLandingTimer
@onready var coyote_jump_timer : Timer = $Timers/CoyoteJumpTimer

func _ready() -> void:
	# connect signals to player after simple check connectins
	if not PlayerManager.player_death_signal.is_connected(player_death_function) :
		PlayerManager.player_death_signal.connect(player_death_function)
	
	if not PlayerManager.player_get_hurt_signal.is_connected(player_get_hurt_function) :
		PlayerManager.player_get_hurt_signal.connect(player_get_hurt_function)
		
	# connect signals to player
	if not coyote_jump_timer.timeout.is_connected(coyote_jump_timer_timeout) :
		coyote_jump_timer.timeout.connect(coyote_jump_timer_timeout)
	if not hard_landing_timer.timeout.is_connected(hard_landing_timer_timeout) :
		hard_landing_timer.timeout.connect(hard_landing_timer_timeout)
		
	# set timers wait timer
	hard_landing_timer.wait_time = hard_landing_time_number

func _physics_process(delta: float) -> void:
	update_flip_h()
	
	if state == STATE.DEATH :
		velocity.x = 0
		move_and_slide()
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		# coytote jump
		if coyote_jump_timer.is_stopped() :
			coyote_jump_timer.start()
	
	else :
		# Landing handle
		if can_player_hard_landing and state != STATE.DEATH and state != STATE.HURT :
			change_state(STATE.LAND)
			can_player_hard_landing = false
			
			if OS.is_debug_build() :
				print("player landing")
		if not hard_landing_timer.is_stopped() :
			hard_landing_timer.stop()
						
		if not coyote_jump_timer.is_stopped() :
			coyote_jump_timer.stop()
		can_jump = true
		
	if state == STATE.ATTACK or state == STATE.HURT :
		velocity.x = 0
		move_and_slide()
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = jump_velocity
		can_jump = false

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
	if state == STATE.DEATH or state == STATE.RUN_ATTACK or (state == STATE.LAND and direction == 0):
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
		
		STATE.LAND :
			animation_sprite.play("land")
			# DEBUG
			if OS.is_debug_build() :
				print("landing anmation run")

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
			if hard_landing_timer.is_stopped() :
				hard_landing_timer.start()
			
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
		
	# TEST
	if event.is_action_pressed("TEST_HURT") :
		PlayerManager.decrease_health(10)

func _on_player_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "land" or animation_sprite.animation == "attack" or animation_sprite.animation == "run_attack" or animation_sprite.animation == "hurt":
		update_animation()

func player_get_hurt_function() -> void :
	change_state(STATE.HURT)
	can_player_hard_landing = false
	# DEBUG
	if OS.is_debug_build() :
		print("player can has hard landing = " + str(can_player_hard_landing))
	
func player_death_function() -> void :
	pass
	
func coyote_jump_timer_timeout() -> void : 
	can_jump = false

func hard_landing_timer_timeout() -> void :
	can_player_hard_landing = true
