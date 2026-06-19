extends Node2D

signal enemy_spawned(enemy: Node)

@export var enemy_scene: PackedScene
@export var target_path: NodePath
@export var spawn_interval: float = 2.0
@export var spawn_margin: float = 160.0
@export var spawn_parent_path: NodePath
@export var xp_drop_scene: PackedScene
@export var xp_drop_parent_path: NodePath

var _target: Node2D
var _spawn_parent: Node
var _xp_drop_parent: Node
var _timer := 0.0
var _rng := RandomNumberGenerator.new()
var _enabled := false
var _wave := 1
var _max_alive := 10
var _elite_spawned := false

func _ready() -> void:
	_rng.randomize()
	_target = get_node_or_null(target_path) as Node2D
	_spawn_parent = get_node_or_null(spawn_parent_path)
	_xp_drop_parent = get_node_or_null(xp_drop_parent_path)
	if _spawn_parent == null:
		_spawn_parent = self

func _process(delta: float) -> void:
	if not _enabled:
		return
	_timer += delta
	if _timer >= spawn_interval and get_alive_count() < _max_alive:
		_timer = 0.0
		spawn_enemy(_choose_enemy_type())

func start_wave(wave: int) -> void:
	_wave = maxi(wave, 1)
	_max_alive = 8 + _wave * 2
	spawn_interval = maxf(0.35, 1.8 - _wave * 0.1)
	_timer = spawn_interval
	_elite_spawned = false
	_enabled = true

func stop_wave() -> void:
	_enabled = false

func spawn_enemy(type_id: String = "normal") -> Node2D:
	if enemy_scene == null or _target == null:
		return null
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null
	_spawn_parent.add_child(enemy)
	enemy.global_position = _get_spawn_position()
	enemy.set("target_path", enemy.get_path_to(_target))
	enemy.set("xp_drop_scene", xp_drop_scene)
	enemy.set("xp_drop_parent_path", enemy.get_path_to(_xp_drop_parent) if _xp_drop_parent != null else NodePath())
	if enemy.has_method("configure"):
		enemy.call("configure", type_id, _wave)
	if enemy.has_method("set_target"):
		enemy.call("set_target", _target)
	if enemy.has_method("set_xp_drop_parent"):
		enemy.call("set_xp_drop_parent", _xp_drop_parent)
	enemy_spawned.emit(enemy)
	return enemy

func get_alive_count() -> int:
	return _spawn_parent.get_child_count() if _spawn_parent != null else 0

func _choose_enemy_type() -> String:
	if _wave in [5, 10] and not _elite_spawned:
		_elite_spawned = true
		return "elite"
	var fast_chance := minf(0.1 + _wave * 0.04, 0.45)
	return "fast" if _rng.randf() < fast_chance else "normal"

func _get_spawn_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var camera := get_viewport().get_camera_2d()
	var center := _target.global_position
	if camera != null:
		center = camera.get_screen_center_position()
	var half_size := viewport_size * 0.5
	match _rng.randi_range(0, 3):
		0:
			return center + Vector2(_rng.randf_range(-half_size.x, half_size.x), -half_size.y - spawn_margin)
		1:
			return center + Vector2(half_size.x + spawn_margin, _rng.randf_range(-half_size.y, half_size.y))
		2:
			return center + Vector2(_rng.randf_range(-half_size.x, half_size.x), half_size.y + spawn_margin)
		_:
			return center + Vector2(-half_size.x - spawn_margin, _rng.randf_range(-half_size.y, half_size.y))
