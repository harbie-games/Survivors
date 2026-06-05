extends Node2D

@export var enemy_scene: PackedScene
@export var target_path: NodePath
@export var spawn_interval: float = 2.0
@export var spawn_margin: float = 160.0
@export var initial_spawn_count: int = 1
@export var spawn_parent_path: NodePath
@export var xp_drop_scene: PackedScene
@export var xp_drop_parent_path: NodePath

var _target: Node2D
var _spawn_parent: Node
var _xp_drop_parent: Node
var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_target = get_node_or_null(target_path) as Node2D
	_spawn_parent = get_node_or_null(spawn_parent_path)
	_xp_drop_parent = get_node_or_null(xp_drop_parent_path)
	if _spawn_parent == null:
		_spawn_parent = self
	for i in range(initial_spawn_count):
		_spawn_enemy()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null or _target == null:
		return

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return

	enemy.global_position = _get_spawn_position()
	_spawn_parent.add_child(enemy)
	enemy.set("target_path", enemy.get_path_to(_target))
	enemy.set("xp_drop_scene", xp_drop_scene)
	enemy.set("xp_drop_parent_path", enemy.get_path_to(_xp_drop_parent) if _xp_drop_parent != null else NodePath())
	if enemy.has_method("set_target"):
		enemy.call("set_target", _target)
	if enemy.has_method("set_xp_drop_parent"):
		enemy.call("set_xp_drop_parent", _xp_drop_parent)

func _get_spawn_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var camera := get_viewport().get_camera_2d()
	var center := _target.global_position
	if camera != null:
		center = camera.get_screen_center_position()

	var half_size := viewport_size * 0.5
	var side := _rng.randi_range(0, 3)
	match side:
		0:
			return center + Vector2(_rng.randf_range(-half_size.x, half_size.x), -half_size.y - spawn_margin)
		1:
			return center + Vector2(half_size.x + spawn_margin, _rng.randf_range(-half_size.y, half_size.y))
		2:
			return center + Vector2(_rng.randf_range(-half_size.x, half_size.x), half_size.y + spawn_margin)
		_:
			return center + Vector2(-half_size.x - spawn_margin, _rng.randf_range(-half_size.y, half_size.y))
