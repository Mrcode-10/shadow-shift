class_name PlayerCamera

extends Camera2D

@export var hurt_stregth : float = 10
@export var hurt_duration : float = 0.25
@export var dead_stregth : float = 20
@export var dead_duration : float = 0.5
@export var shift_zoom_factor : float = 0.9
@export var shift_zoom_out_time : float = 0.12
@export var shift_zoom_back_time : float = 0.35

var zoom_tween : Tween
var base_camera_zoom : Vector2
var tween : Tween

func _ready() -> void:
	base_camera_zoom = zoom
	
	if not PlayerManager.player_get_hurt_signal.is_connected(player_get_hurt_function) :
		PlayerManager.player_get_hurt_signal.connect(player_get_hurt_function)
		
	if not PlayerManager.player_death_signal.is_connected(player_dead_function) :
		PlayerManager.player_death_signal.connect(player_dead_function)
	
	if not PlayerManager.shift_signal.is_connected(shift_zoom_function) :
		PlayerManager.shift_signal.connect(shift_zoom_function)
	
func shake(stregth : float , duration : float) -> void :
	if tween and tween.is_valid() :
		tween.kill()
	tween = create_tween()
	tween.tween_method(add_shake_to_camera.bind(stregth) , 1.0 , 0.0 , duration)
	tween.tween_callback(reset_camera_shake)
	
func add_shake_to_camera(amount : float , stregth : float ) -> void :
	offset = Vector2(randf_range(-1.0 , 1) , randf_range(-1.0 , 1)) * stregth * amount
	
func reset_camera_shake() -> void :
	offset = Vector2.ZERO

func player_get_hurt_function() -> void :
	shake(hurt_stregth , hurt_duration)
	
func player_dead_function() -> void :
	shake(dead_stregth , dead_duration)
	
func shift_zoom_function() -> void :
	if zoom_tween and zoom_tween.is_valid() :
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(
		self , "zoom" , base_camera_zoom * shift_zoom_factor , shift_zoom_out_time  
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(
		self , "zoom" , base_camera_zoom , shift_zoom_back_time ,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
