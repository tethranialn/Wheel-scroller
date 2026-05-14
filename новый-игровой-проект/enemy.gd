extends Area2D

@export var damage_amount: float = 10.0
@export var max_health: float = 50.0
var current_health: float = 50.0

var health_bar: ProgressBar

func _ready() -> void:
	current_health = max_health
	create_health_bar()
	collision_layer = 1
	collision_mask = 0
	add_to_group("enemies")

func take_damage(amount: float) -> void:
	print("Enemy took damage: ", amount)
	current_health -= amount
	if current_health <= 0:
		queue_free()
	else:
		update_health_bar()

func create_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.size = Vector2(50, 10)
	health_bar.position = Vector2(-25, -40)
	add_child(health_bar)

func update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
