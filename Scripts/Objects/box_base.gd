class_name BoxBase

extends StaticBody2D

enum STATE {
	DEFAULT , OPEN , CLOSE
}

var state : STATE = STATE.DEFAULT
@onready var animation_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var target_point : Node2D = $TargetPointNode
@onready var timer : Timer = $Timer
var enemy_file = preload("res://Scenes/Enemies/simple_enemy1.tscn")
@export var timer_time : float = 10
static var flag : bool = true


func _ready() -> void:
	timer.wait_time = timer_time
	flag = true
	

func change_state(new_state : STATE) :
	if new_state != state :
		state = new_state
		match state :
			STATE.DEFAULT :
				animation_sprite.play("default")
				
			STATE.OPEN :
				animation_sprite.play("open")
			
			STATE.CLOSE :
				animation_sprite.play("close")


func timer_timeout() -> void : 
	if flag :
		change_state(STATE.OPEN)

func animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "open" :
		if flag :
			spawn_enemy()
		change_state(STATE.CLOSE)
	elif animation_sprite.animation == "close" :
		change_state(STATE.DEFAULT)

func spawn_enemy() -> void :
	var enemy : Node2D = enemy_file.instantiate()
	enemy.global_position = target_point.global_position
	get_tree().current_scene.add_child(enemy)

static func turn_off() -> void :
	flag = false
