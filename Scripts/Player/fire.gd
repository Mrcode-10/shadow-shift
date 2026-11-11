class_name Fire

extends Area2D

enum STATE {
	IDLE , HIT
}

var direction : float = 1
var tween : Tween
var state : STATE = STATE.IDLE
var distance : float = 10000
@export var animation_time : float = 10
@onready var animation_sprite : AnimatedSprite2D = $FireAnimatedSprite2D

func _ready() -> void:
	# BEGIN DEBUG
	if OS.is_debug_build() :
		print("fire")
	# END DEBUG
	# Animation flip_h handle
	if direction < 0 :
		animation_sprite.flip_h = true
	# set distance with viewport size and create tween for fire movement
	tween = create_tween()
	tween.tween_property(
		self , "global_position:x" ,  global_position.x + direction * distance , animation_time
	)
	if not tween.finished.is_connected(tween_finished_function) :
		tween.finished.connect(tween_finished_function)

func change_state( new_state : STATE ) -> void :
	if new_state != state and state != STATE.HIT :
		state = new_state
		match_state()

func match_state() -> void :
	match state :
		STATE.IDLE :
			animation_sprite.play("idle")
		STATE.HIT :
			animation_sprite.play("hit")

func tween_finished_function() -> void :
	queue_free()


func _on_fire_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "hit" :
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# TODO
	# add a simple check for know body is enemy
	# aplly damage to enemy
	if state == STATE.HIT :
		return
	if tween :
		tween.kill()
	set_deferred("monitoring" , false )
	change_state(STATE.HIT)
