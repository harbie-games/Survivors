extends Area2D

@export var speed: float = 520.0
@export var damage: float = 5.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func setup(start_position: Vector2, move_direction: Vector2, hit_damage: float) -> void:
	global_position = start_position
	direction = move_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = hit_damage
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.call("apply_damage", damage)
	queue_free()
