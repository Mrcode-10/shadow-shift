extends Control

@export var animation_duration : float = 0.8
@onready var health_bar : ProgressBar = $MarginContainer/CenterContainer/ProgressBar
@onready var shift_timer_label : Label = $MarginContainer2/Label
@export var shift_animation_time : float = 8
var shift_tween : Tween
var progress_bar_tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not PlayerManager.change_health.is_connected(progress_bar_animation) :
		PlayerManager.change_health.connect(progress_bar_animation)
	if not PlayerManager.shift_signal.is_connected(shift_function) :
		PlayerManager.shift_signal.connect(shift_function)

func progress_bar_animation(health : float) -> void :
	if progress_bar_tween and progress_bar_tween.is_valid() :
		progress_bar_tween.kill()
	progress_bar_tween = create_tween()
	progress_bar_tween .tween_property(
		health_bar , "value" , health , animation_duration
	)
	
func change_label_text(amount : float) -> void :
	shift_timer_label.text = str(int(amount))

func shift_function() -> void :
	if shift_tween and shift_tween.is_valid() :
		shift_tween.kill()
	shift_tween = create_tween()
	shift_tween.tween_method(
		change_label_text , shift_animation_time , 0 , shift_animation_time 
	)
