extends CharacterBody2D

@export var scroll_speed: float = 630.0
@export var acceleration: float = 300.0
@export var friction: float = 140.0
@export var wheel_window_time: float = 0.12
@export var opposite_brake_multiplier: float = 4.5
@export var boost_until_ratio: float = 0.7
@export var brake_strength: float = 800.0
@export var reverse_speed_ratio: float = 0.5
@export var reverse_accel_ratio: float = 0.85
@export var dash_threshold: float = 600.0
@export var dash_color: Color = Color.RED

var target_velocity: Vector2 = Vector2.ZERO
var wheel_timer: float = 0.0
var boost_active: bool = false
var dash: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speed_label: Label = $"SpeedLabel"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos := get_global_mouse_position()
		var direction := (mouse_pos - global_position).normalized()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_velocity = direction * scroll_speed
			wheel_timer = wheel_window_time
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_velocity = -direction * scroll_speed * reverse_speed_ratio
			wheel_timer = wheel_window_time
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	var look_direction := (mouse_pos - global_position).normalized()
	animated_sprite.rotation = look_direction.angle() - deg_to_rad(90)
	
	if wheel_timer > 0.0:
		var accel: float
		var current_target := target_velocity
		
		var moving_opposite := velocity.dot(current_target) < 0.0
		var is_braking_forward := target_velocity.length_squared() > 0.0 and moving_opposite and velocity.length() > 10.0
		
		if current_target.length_squared() < 0.1:
			accel = brake_strength
		elif is_braking_forward:
			accel = brake_strength
		else:
			var below_boost_threshold := velocity.length() < current_target.length() * boost_until_ratio
			
			if moving_opposite:
				boost_active = true
			elif boost_active and below_boost_threshold:
				boost_active = true
			else:
				boost_active = false
			
			accel = acceleration
			if boost_active:
				accel *= opposite_brake_multiplier
			elif current_target.length() < scroll_speed * reverse_speed_ratio * 1.1:
				accel *= reverse_accel_ratio
		
		velocity = velocity.move_toward(current_target, accel * delta)
		wheel_timer -= delta
	else:
		target_velocity = Vector2.ZERO
		boost_active = false
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	var current_speed := velocity.length()
	var current_accel: float
	if wheel_timer > 0.0:
		if target_velocity.length_squared() < 0.1:
			current_accel = brake_strength
		elif velocity.dot(target_velocity) < 0.0 and velocity.length() > 10.0:
			current_accel = brake_strength
		else:
			current_accel = acceleration
			if boost_active:
				current_accel *= opposite_brake_multiplier
			elif target_velocity.length() < scroll_speed * reverse_speed_ratio * 1.1:
				current_accel *= reverse_accel_ratio
	else:
		current_accel = friction

	speed_label.text = "Speed: %.1f" % current_speed
	
	dash = current_speed >= dash_threshold
	if dash:
		animated_sprite.modulate = dash_color
	else:
		animated_sprite.modulate = Color.WHITE
