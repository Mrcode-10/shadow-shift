class_name Player

extends CharacterBody2D

enum STATE {
	IDLE , RUNNING , RUN_ATTACK , DEATH , HURT , ATTACK , JUMP , FALL , LAND
}

@export var stomp_damage : float = 5
var can_jump : bool = true
var can_player_hard_landing : bool = false
var state : STATE = STATE.IDLE
var is_player_dead : bool = false
var can_use_shift : bool = true
var fire_file := preload("res://Scenes/Player/fire.tscn")
var stomp_count : int = 0
var game_over_file := preload("res://Scenes/UI/game_over.tscn")
@export var stomp_timer_wait_time : float = 5
@export var reload_time : float = 3
@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var hard_landing_time_number : float = 0.5
@export var max_stomp : int = 3
@onready var stomp_timer : Timer = $Timers/StompTimer
@onready var animation_sprite : AnimatedSprite2D = $PlayerAnimatedSprite2D
@onready var hard_landing_timer : Timer = $Timers/HardLandingTimer
@onready var coyote_jump_timer : Timer = $Timers/CoyoteJumpTimer
@onready var fire_right_target : Node2D = $FireTargetNodes/FireRightTarget
@onready var fire_left_target : Node2D = $FireTargetNodes/FireLeftTarget
@onready var shift_timer : Timer = $Timers/ShiftTimer
@onready var stomp_area_2d: Area2D = $StompArea2D
var pause_menu_file := preload("res://Scenes/UI/pause_menu.tscn")
@export var shift_timer_time : float = 8

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
	if not shift_timer.timeout.is_connected(shift_timer_timeout) :
		shift_timer.timeout.connect(shift_timer_timeout)
	# set timers wait timer
	hard_landing_timer.wait_time = hard_landing_time_number
	# set stomp timer wait time
	stomp_timer.wait_time = stomp_timer_wait_time
	shift_timer.wait_time = shift_timer_time

func _physics_process(delta: float) -> void:
	update_flip_h()
	
	if is_player_dead :
		if is_on_floor() :
			change_state(STATE.DEATH)
		else :
			velocity += get_gravity() * delta
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
		stomp_count_reset()
		if not stomp_timer.is_stopped() :
			stomp_timer.stop()
			stomp_area_2d.set_deferred("monitoring" , true)
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
		
	if state == STATE.HURT :
		velocity.x = 0
		move_and_slide()
		return
	
	elif state == STATE.ATTACK :
		if is_on_floor() :
			velocity.x = 0
		else :
			velocity += get_gravity() * delta
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
		disconnect_attack_functions_when_animation_finished()
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
			PlayerManager.flip_h = animation_sprite.flip_h
			
	elif velocity.x < -0.1 :
		if not animation_sprite.flip_h :
			animation_sprite.flip_h = true
			if shift_timer.is_stopped() :
				shift_timer.start()
			PlayerManager.flip_h = animation_sprite.flip_h
	
func _unhandled_input(event: InputEvent) -> void:
	# Handle player input actions
	if event.is_action_pressed("attack") and not is_player_dead and state != STATE.HURT :
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("Preesed attack button")
		# END DEBUG
		if abs(velocity.x) > 0.1 and is_on_floor():
			change_state(STATE.RUN_ATTACK)
			if not animation_sprite.frame_changed.is_connected(run_attack_frame_changed) :
				animation_sprite.frame_changed.connect(run_attack_frame_changed)
			# BEGIN DEBUG
			if OS.is_debug_build() :
				print("State changed to run attack")
		# END DEBUG
		else : 
			change_state(STATE.ATTACK)
			if not animation_sprite.frame_changed.is_connected(attack_frame_changed) :
				animation_sprite.frame_changed.connect(attack_frame_changed)
			# BEGIN DEBUG
			if OS.is_debug_build() :
				print("State changed to attack")
			# END DEBUG
	
	if event.is_action_pressed("shift") and not is_player_dead and state != STATE.HURT and can_use_shift :
		PlayerManager.shift_signal.emit()
		can_use_shift = false
		
	if event.is_action_pressed("pause") and not is_player_dead and state !=STATE.HURT and not get_tree().paused :
		pause_game_function()
	
	# TEST
	if event.is_action_pressed("TEST_HURT") and OS.is_debug_build() :
		PlayerManager.decrease_health(10)

func _on_player_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "death" :
		await get_tree().create_timer(reload_time).timeout
		#PlayerManager.reset()
		#get_tree().reload_current_scene()
		game_over_function()
		return
		
	if is_player_dead : 
		return
	
	if animation_sprite.animation == "land" or animation_sprite.animation == "attack" or animation_sprite.animation == "run_attack" or animation_sprite.animation == "hurt":
		disconnect_attack_functions_when_animation_finished()
		update_animation()
		
func player_get_hurt_function() -> void :
	change_state(STATE.HURT)
	can_player_hard_landing = false
	disconnect_attack_functions_when_get_hurt_die()
	# DEBUG
	if OS.is_debug_build() :
		print("player can has hard landing = " + str(can_player_hard_landing))
	
func player_death_function() -> void :
	is_player_dead = true
	stomp_area_2d.set_deferred("monitoring" , false)
	disconnect_attack_functions_when_get_hurt_die()
	
func coyote_jump_timer_timeout() -> void : 
	can_jump = false

func hard_landing_timer_timeout() -> void :
	can_player_hard_landing = true

func attack_frame_changed() -> void :
	if animation_sprite.animation == "attack" and animation_sprite.frame == 2 :
		spawn_fire()
		# DEBUG
		if OS.is_debug_build() :
			print("Attack fire")

func run_attack_frame_changed() -> void :
	if animation_sprite.animation == "run_attack" and animation_sprite.frame == 4 :
		spawn_fire()
		# DEBUG
		if OS.is_debug_build() :
			print("Run attack fire")
	
func disconnect_attack_functions_when_animation_finished() -> void :
	if animation_sprite.animation == "attack" and animation_sprite.frame_changed.is_connected(attack_frame_changed) :
		animation_sprite.frame_changed.disconnect(attack_frame_changed)
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("disconnected functions from player when animation finished")
		# END DEBUG
	elif animation_sprite.animation == "run_attack" and animation_sprite.frame_changed.is_connected(run_attack_frame_changed):
		animation_sprite.frame_changed.disconnect(run_attack_frame_changed)
		# BEGIN DEBUG
		if OS.is_debug_build() :
			print("disconnected functions from player when animation finished")
		# END DEBUG
		
func disconnect_attack_functions_when_get_hurt_die() -> void :
	if animation_sprite.frame_changed.is_connected(attack_frame_changed) :
		animation_sprite.frame_changed.disconnect(attack_frame_changed)
	if animation_sprite.frame_changed.is_connected(run_attack_frame_changed) :
		animation_sprite.frame_changed.disconnect(run_attack_frame_changed)
	# DEBUG
	if OS.is_debug_build() :
		print("disconnected functions from player when die or get hurt")

func spawn_fire() -> void :
	var fire : Fire = fire_file.instantiate()
	fire.direction = -1 if animation_sprite.flip_h else 1
	fire.global_position = fire_left_target.global_position if animation_sprite.flip_h else fire_right_target.global_position
	get_tree().current_scene.add_child(fire)

func take_damage_for_player(damage : float) -> void :
	PlayerManager.decrease_health(damage)


func _on_stomp_area_2d_body_entered(body: Node2D) -> void:
	if is_player_dead : 
		return
	# DEBUG BEGIN
	if OS.is_debug_build() :
		print("Stomp")
	# DEBUG END 
	if body.has_method("take_damage") and velocity.y > 0:
		body.take_damage(stomp_damage)
		stomp_count += 1
		velocity.y += jump_velocity * 2
		if stomp_count == max_stomp :
			stomp_area_2d.set_deferred("monitoring" , false)
			stomp_timer.start()
		# DEBUG BEGIN
		if OS.is_debug_build() :
			print("Stomp Damage")
		# DEBUG END 

#----------------------------------  Shift timer handle
func shift_timer_timeout() -> void :
	if is_player_dead : 
		return
	can_use_shift = true

#--------------------------------- stomp jump part

func _on_stomp_timer_timeout() -> void:
	if not is_player_dead :
		stomp_area_2d.set_deferred("monitoring" , true)
		stomp_count_reset()
		
		
func stomp_count_reset() -> void :
	stomp_count = 0
	
#------------------------------------- pause menu part
	
func pause_game_function() -> void :
	var pause_menu = pause_menu_file.instantiate()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	%CanvasLayer.add_child(pause_menu)
	get_tree().paused = true


#------------------------------------- game over add to scene

func game_over_function() -> void :
	var game_over_menu : Control = game_over_file.instantiate()
	%CanvasLayer.add_child(game_over_menu)
	
