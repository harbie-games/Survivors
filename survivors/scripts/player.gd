extends CharacterBody2D

signal hp_changed(current_hp: float, max_hp: float)
signal died
signal xp_changed(current_xp: int, xp_required: int, level: int)

@export var speed: float = 260.0
@export var max_hp: float = 100.0
@export var fire_interval: float = 0.5
@export var projectile_damage: float = 5.0
@export var auto_aim_range: float = 260.0
@export var projectile_scene: PackedScene
@export var enemies_path: NodePath
@export var projectile_parent_path: NodePath

var input_vector: Vector2 = Vector2.ZERO
var hp: float = 100.0
var level: int = 0
var xp: int = 0
var xp_required: int = 20
var _is_dead: bool = false
var _last_move_direction: Vector2 = Vector2.RIGHT
var _fire_timer: float = 0.0
var _enemies: Node
var _projectile_parent: Node

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	hp = max_hp
	level = 0
	xp = 0
	xp_required = 20
	_is_dead = false
	_fire_timer = 0.0
	_enemies = get_node_or_null(enemies_path)
	_projectile_parent = get_node_or_null(projectile_parent_path)
	if _projectile_parent == null:
		_projectile_parent = get_parent()
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_required, level)

func _physics_process(delta: float) -> void:
	velocity = input_vector * speed
	move_and_slide()
	_update_facing()
	_update_last_move_direction()
	_fire_timer += delta
	if _fire_timer >= fire_interval:
		_fire_timer = 0.0
		_fire_projectile()

func set_move_vector(value: Vector2) -> void:
	input_vector = value.limit_length(1.0)

func apply_damage(amount: float) -> void:
	if _is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_is_dead = true
		died.emit()

func collect_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required *= 2
	xp_changed.emit(xp, xp_required, level)

func get_hp() -> float:
	return hp

func _update_facing() -> void:
	if abs(input_vector.x) > 0.05:
		sprite.flip_h = input_vector.x < 0.0

func _update_last_move_direction() -> void:
	if input_vector.length_squared() > 0.001:
		_last_move_direction = input_vector.normalized()

func _fire_projectile() -> void:
	if projectile_scene == null or _projectile_parent == null:
		return
	var projectile := projectile_scene.instantiate() as Area2D
	if projectile == null:
		return
	_projectile_parent.add_child(projectile)
	var aim_direction := _get_aim_direction()
	projectile.call("setup", global_position, aim_direction, projectile_damage)

func _get_aim_direction() -> Vector2:
	var nearest_enemy := _get_nearest_enemy()
	if nearest_enemy != null:
		return global_position.direction_to(nearest_enemy.global_position)
	return _last_move_direction

func _get_nearest_enemy() -> Node2D:
	if _enemies == null:
		return null
	var nearest_enemy: Node2D = null
	var nearest_distance := INF
	var max_distance := auto_aim_range * auto_aim_range
	for child in _enemies.get_children():
		var enemy := child as Node2D
		if enemy == null:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance > max_distance:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	return nearest_enemy
