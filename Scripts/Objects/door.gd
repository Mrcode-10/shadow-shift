extends Area2D

enum STATE {
	DEFAULT , OPEN , CLOSE
}

@onready var animation_sprite : AnimatedSprite2D = $AnimatedSprite2D
var open_animation_playing : bool = false
var close_animation_playing : bool = false
var want_to_play_open_animation : bool = false
var want_to_play_close_animation : bool = false
var can_change_scene : bool = false
var state : STATE = STATE.DEFAULT
var player : Node2D = null
var is_player_in_open_area : bool = false
var next_level = preload("res://Scenes/Levels/boss_level.tscn")

func change_state(new_state : STATE) :
	if state != new_state :
		state = new_state
		match state :
			STATE.DEFAULT :
				animation_sprite.play("default")
				
			STATE.OPEN :
				open_animation_playing = true
				animation_sprite.play("open")
			
			STATE.CLOSE :
				can_change_scene = false
				close_animation_playing = true
				animation_sprite.play("close")

func _on_body_entered(body: Node2D) -> void:
	if body is Player and can_change_scene :
		#DEBUG BEGIN
		if OS.is_debug_build() :
			print("level changed")
		# END DEBUG
		get_tree().change_scene_to_packed(next_level)


func _on_body_exited(body: Node2D) -> void:
	if body is Player :
		pass


func _on_open_close_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		is_player_in_open_area = true
		if PlayerManager.has_key:
			if not close_animation_playing :
				change_state(STATE.OPEN)
			else :
				want_to_play_open_animation = true
			debug()

func _on_open_close_area_body_exited(body: Node2D) -> void:
	if body is Player :
		is_player_in_open_area = false
		player = null
		if not PlayerManager.has_key :
			return
		if not open_animation_playing :
				change_state(STATE.CLOSE)
		else :
			want_to_play_close_animation = true
		debug()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animation_sprite.animation == "open" :
		open_animation_playing = false
		if want_to_play_close_animation and not is_player_in_open_area :
			want_to_play_close_animation = false
			change_state(STATE.CLOSE)
		debug()
		can_change_scene = true
		if player != null and overlaps_body(player) :
			#DEBUG BEGIN
			if OS.is_debug_build() :
				print("level changed")
			# END DEBUG
			get_tree().reload_current_scene()
		
	elif animation_sprite.animation == "close" :
		close_animation_playing = false
		if want_to_play_open_animation and is_player_in_open_area:
			want_to_play_open_animation = false
			change_state(STATE.OPEN)
		else :
			change_state(STATE.DEFAULT)
		debug()

#DEBUG BEGIN
func debug() -> void :
	if OS.is_debug_build() :
		print("open animation playing : " + str(open_animation_playing))
		print("open animation want to play : " + str(want_to_play_open_animation))
		print("close animation playing : " + str(close_animation_playing))
		print("close animation playing : " + str(want_to_play_close_animation))
# END DEBUG
