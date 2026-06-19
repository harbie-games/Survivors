extends Area2D

var damage: float = 10.0
var orbit_radius: float = 90.0
var rotation_speed: float = 4.0
var active_duration: float = 4.0
var hit_cooldown: float = 0.4
var size_multiplier: float = 1.0
var _owner_player: Node2D
var _angle: float = 0.0
var _life_left: float = 0.0
var _hit_timers: Dictionary = {}

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(owner_player: Node2D, hit_damage: float, radius: float, duration: float, speed: float, hit_interval: float, size_value: float) -> void:
	_owner_player = owner_player
	damage = hit_damage
	orbit_radius = radius
	active_duration = duration
	rotation_speed = speed
	hit_cooldown = hit_interval
	size_multiplier = size_value
	_life_left = active_duration
	_apply_size()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_size()

func _process(delta: float) -> void:
	if _owner_player == null or not is_instance_valid(_owner_player):
		queue_free()
		return
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	_angle += rotation_speed * delta
	global_position = _owner_player.global_position + Vector2.RIGHT.rotated(_angle) * orbit_radius
	rotation += rotation_speed * delta * 2.0
	for enemy in _hit_timers.keys():
		_hit_timers[enemy] = maxf(float(_hit_timers[enemy]) - delta, 0.0)

func _on_body_entered(body: Node) -> void:
	_try_damage(body)

func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	_try_damage(body)

func _try_damage(body: Node) -> void:
	if body == null or not body.has_method("apply_damage"):
		return
	if body.has_method("is_dead") and body.call("is_dead"):
		return
	if float(_hit_timers.get(body, 0.0)) > 0.0:
		return
	_hit_timers[body] = hit_cooldown
	body.call("apply_damage", damage, self)

func _apply_size() -> void:
	var radius := 18.0 * size_multiplier
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	if visual != null:
		var points: PackedVector2Array = []
		for index in range(20):
			var angle := TAU * float(index) / 20.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		visual.polygon = points
