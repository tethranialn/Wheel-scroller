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

@export var max_health: float = 100.0
var current_health: float = 100.0

@export var invincibility_duration: float = 2.0
var is_invincible: bool = false
var invincibility_timer: float = 0.0

@export var blink_speed: float = 0.1
var blink_timer: float = 0.0
var original_modulate: Color = Color.WHITE

var target_velocity: Vector2 = Vector2.ZERO
var wheel_timer: float = 0.0
var boost_active: bool = false
var dash: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var speed_label: Label = $"SpeedLabel"
@onready var health_label: Label = $"HealthLabel"
@onready var coordinates_label: Label = $"CoordinatesLabel"

func _ready() -> void:
	update_health_display()
	original_modulate = animated_sprite.modulate

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
	
	update_invincibility(delta)
	
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
	speed_label.text = "Speed: %.1f" % current_speed
	coordinates_label.text = "X: %.0f Y: %.0f" % [global_position.x, global_position.y]
	
	dash = current_speed >= dash_threshold
	if dash:
		animated_sprite.modulate = dash_color
	elif not is_invincible:
		animated_sprite.modulate = original_modulate

func take_damage(amount: float) -> void:
	if is_invincible:
		return
	
	if current_health <= 0:
		return
	
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		die()
	else:
		start_invincibility()
	
	update_health_display()

func heal(amount: float) -> void:
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	update_health_display()

func update_health_display() -> void:
	if health_label:
		health_label.text = "HP: %.0f / %.0f" % [current_health, max_health]

func die() -> void:
	print("Player died!")
	set_process(false)
	set_physics_process(false)

func is_alive() -> bool:
	return current_health > 0

func start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = invincibility_duration
	blink_timer = 0.0

func update_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	
	invincibility_timer -= delta
	
	if invincibility_timer <= 0.0:
		is_invincible = false
		animated_sprite.modulate = original_modulate
		return
	
	blink_timer += delta
	if blink_timer >= blink_speed:
		blink_timer = 0.0
		if animated_sprite.modulate == original_modulate:
			animated_sprite.modulate = Color.TRANSPARENT
		else:
			animated_sprite.modulate = original_modulate
