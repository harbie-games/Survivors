extends CharacterBody2D

signal hp_changed(current_hp: float, max_hp: float)
signal died
signal xp_changed(current_xp: int, xp_required: int, level: int)
signal leveled_up(level: int)
signal damaged(amount: float)
signal weapon_fired(weapon_id: String)

const SOLDIER_PATH := "res://assets/Characters(100x100)/Soldier/Soldier/"
const SAW_SCENE_PATH := "res://scenes/weapons/Saw.tscn"
const ANIMATION_FILES := {
	"idle": "Soldier-Idle.png",
	"walk": "Soldier-Walk.png",
	"attack": "Soldier-Attack01.png",
	"hurt": "Soldier-Hurt.png",
	"death": "Soldier-Death.png"
}

@export var speed: float = 260.0
@export var max_hp: float = 100.0
@export var projectile_scene: PackedScene
@export var saw_scene: PackedScene
@export var enemies_path: NodePath
@export var projectile_parent_path: NodePath
@export var invulnerability_duration: float = 0.35
@export var pickup_radius: float = 120.0
@export var auto_aim_range: float = 320.0

var input_vector: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO
var hp: float = 100.0
var level: int = 0
var xp: int = 0
var xp_required: int = 20
var fire_rate_upgrade_level: int = 0
var arrow_damage_upgrade_level: int = 0
var unlocked_weapons := {"melee": true, "arrow": false, "saw": false}
var upgrade_levels := {
	"unlock_arrow": 0,
	"unlock_saw": 0,
	"arrow_damage": 0,
	"fire_rate": 0,
	"move_speed": 0,
	"max_health": 0,
	"pickup_radius": 0,
	"armor": 0,
	"melee_damage": 0,
	"melee_range": 0,
	"saw_damage": 0,
	"saw_size": 0
}
var melee_damage: float = 15.0
var melee_cooldown: float = 0.8
var melee_range: float = 70.0
var melee_arc_angle: float = PI
var projectile_damage: float = 5.0
var fire_interval: float = 1.0
var saw_damage: float = 10.0
var saw_orbit_radius: float = 90.0
var saw_active_duration: float = 4.0
var saw_inactive_duration: float = 3.0
var saw_rotation_speed: float = 4.0
var saw_hit_cooldown: float = 0.4
var saw_size_multiplier: float = 1.0
var _is_dead: bool = false
var _invulnerability_left: float = 0.0
var _last_move_direction: Vector2 = Vector2.RIGHT
var _melee_timer: float = 0.0
var _arrow_timer: float = 0.0
var _saw_timer: float = 0.0
var _active_saw: Node
var _enemies: Node
var _projectile_parent: Node
var _animation_name := ""
var _animation_frame := 0
var _animation_time := 0.0
var _animation_locked := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var AudioManager: Node = get_node("/root/AudioManager")

func _ready() -> void:
	hp = max_hp
	_enemies = get_node_or_null(enemies_path)
	_projectile_parent = get_node_or_null(projectile_parent_path)
	if _projectile_parent == null:
		_projectile_parent = get_parent()
	if saw_scene == null and ResourceLoader.exists(SAW_SCENE_PATH):
		saw_scene = load(SAW_SCENE_PATH)
	_play_animation("idle")
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_required, level)

func _physics_process(delta: float) -> void:
	_invulnerability_left = maxf(_invulnerability_left - delta, 0.0)
	_update_animation(delta)
	if _is_dead:
		velocity = Vector2.ZERO
		return
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_vector = joystick_vector if joystick_vector.length_squared() > 0.01 else keyboard
	velocity = input_vector.limit_length(1.0) * speed
	move_and_slide()
	_update_facing()
	if input_vector.length_squared() > 0.001:
		_last_move_direction = input_vector.normalized()
		if not _animation_locked:
			_play_animation("walk")
	elif not _animation_locked:
		_play_animation("idle")
	_process_weapons(delta)

func set_move_vector(value: Vector2) -> void:
	joystick_vector = value.limit_length(1.0)

func apply_damage(amount: float, _source: Node = null) -> void:
	if _is_dead or _invulnerability_left > 0.0:
		return
	var armor_multiplier := maxf(0.2, 1.0 - get_upgrade_level("armor") * 0.08)
	var final_amount := amount * armor_multiplier
	hp = maxf(hp - final_amount, 0.0)
	_invulnerability_left = invulnerability_duration
	hp_changed.emit(hp, max_hp)
	damaged.emit(final_amount)
	AudioManager.play_sfx("player_hurt")
	if hp <= 0.0:
		_is_dead = true
		velocity = Vector2.ZERO
		hp_changed.emit(0.0, max_hp)
		_play_animation("death", true)
		AudioManager.play_sfx("player_death")
		died.emit()
	else:
		_play_animation("hurt", true)

func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

func is_dead() -> bool:
	return _is_dead

func collect_xp(amount: int) -> void:
	if _is_dead:
		return
	xp += amount
	AudioManager.play_sfx("xp_collect")
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required = int(ceil(float(xp_required) * 1.45))
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_required, level)

func has_weapon(id: String) -> bool:
	return bool(unlocked_weapons.get(id, false))

func get_upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func apply_upgrade(id: String) -> bool:
	if id == "unlock_arrow":
		if has_weapon("arrow"):
			return false
		unlocked_weapons["arrow"] = true
		upgrade_levels[id] = 1
		return true
	if id == "unlock_saw":
		if has_weapon("saw"):
			return false
		unlocked_weapons["saw"] = true
		upgrade_levels[id] = 1
		_saw_timer = 0.0
		return true
	if not upgrade_levels.has(id) or get_upgrade_level(id) >= 5:
		return false
	if _requires_weapon(id, "arrow") and not has_weapon("arrow"):
		return false
	if _requires_weapon(id, "saw") and not has_weapon("saw"):
		return false
	upgrade_levels[id] = get_upgrade_level(id) + 1
	match id:
		"arrow_damage":
			projectile_damage *= 1.4
			arrow_damage_upgrade_level = get_upgrade_level(id)
		"fire_rate":
			fire_interval = maxf(fire_interval * 0.88, 0.12)
			fire_rate_upgrade_level = get_upgrade_level(id)
		"move_speed":
			speed *= 1.1
		"max_health":
			max_hp += 20.0
			heal(20.0)
		"pickup_radius":
			pickup_radius += 35.0
		"melee_damage":
			melee_damage *= 1.35
		"melee_range":
			melee_range += 18.0
		"saw_damage":
			saw_damage *= 1.35
		"saw_size":
			saw_size_multiplier += 0.22
			saw_orbit_radius += 8.0
	return true

func can_upgrade_fire_rate() -> bool:
	return has_weapon("arrow") and get_upgrade_level("fire_rate") < 5

func apply_fire_rate_upgrade() -> void:
	apply_upgrade("fire_rate")

func can_upgrade_arrow_damage() -> bool:
	return has_weapon("arrow") and get_upgrade_level("arrow_damage") < 5

func apply_arrow_damage_upgrade() -> void:
	apply_upgrade("arrow_damage")

func get_hp() -> float:
	return hp

func export_save_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y], "hp": hp, "max_hp": max_hp,
		"level": level, "xp": xp, "xp_required": xp_required, "speed": speed,
		"fire_interval": fire_interval, "projectile_damage": projectile_damage,
		"melee_damage": melee_damage, "melee_range": melee_range,
		"saw_damage": saw_damage, "saw_size_multiplier": saw_size_multiplier, "saw_orbit_radius": saw_orbit_radius,
		"pickup_radius": pickup_radius, "upgrades": upgrade_levels.duplicate(true),
		"weapons": unlocked_weapons.duplicate(true)
	}

func import_save_data(data: Dictionary) -> void:
	var position_data: Array = data.get("position", [640.0, 360.0])
	global_position = Vector2(float(position_data[0]), float(position_data[1]))
	max_hp = float(data.get("max_hp", 100.0))
	hp = clampf(float(data.get("hp", max_hp)), 0.0, max_hp)
	level = int(data.get("level", 0))
	xp = int(data.get("xp", 0))
	xp_required = int(data.get("xp_required", 20))
	speed = float(data.get("speed", 260.0))
	fire_interval = float(data.get("fire_interval", 1.0))
	projectile_damage = float(data.get("projectile_damage", 5.0))
	melee_damage = float(data.get("melee_damage", 15.0))
	melee_range = float(data.get("melee_range", 70.0))
	saw_damage = float(data.get("saw_damage", 10.0))
	saw_size_multiplier = float(data.get("saw_size_multiplier", 1.0))
	saw_orbit_radius = float(data.get("saw_orbit_radius", 90.0))
	pickup_radius = float(data.get("pickup_radius", 120.0))
	var saved_upgrades: Dictionary = data.get("upgrades", {})
	for id in upgrade_levels:
		upgrade_levels[id] = int(saved_upgrades.get(id, 0))
	var saved_weapons: Dictionary = data.get("weapons", {"melee": true, "arrow": false, "saw": false})
	for id in unlocked_weapons:
		unlocked_weapons[id] = bool(saved_weapons.get(id, id == "melee"))
	fire_rate_upgrade_level = get_upgrade_level("fire_rate")
	arrow_damage_upgrade_level = get_upgrade_level("arrow_damage")
	_is_dead = false
	joystick_vector = Vector2.ZERO
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_required, level)

func reset_run_state() -> void:
	global_position = Vector2(640.0, 360.0)
	max_hp = 100.0
	hp = max_hp
	level = 0
	xp = 0
	xp_required = 20
	speed = 260.0
	pickup_radius = 120.0
	melee_damage = 15.0
	melee_range = 70.0
	fire_interval = 1.0
	projectile_damage = 5.0
	saw_damage = 10.0
	saw_orbit_radius = 90.0
	saw_size_multiplier = 1.0
	unlocked_weapons = {"melee": true, "arrow": false, "saw": false}
	for id in upgrade_levels:
		upgrade_levels[id] = 0
	_is_dead = false
	_invulnerability_left = 0.0
	_melee_timer = 0.0
	_arrow_timer = 0.0
	_saw_timer = 0.0
	if _active_saw != null and is_instance_valid(_active_saw):
		_active_saw.queue_free()
	_active_saw = null
	joystick_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_required, level)
	_play_animation("idle")

func _requires_weapon(id: String, weapon_id: String) -> bool:
	if weapon_id == "arrow":
		return id in ["arrow_damage", "fire_rate"]
	if weapon_id == "saw":
		return id in ["saw_damage", "saw_size"]
	return false

func _process_weapons(delta: float) -> void:
	_melee_timer += delta
	_arrow_timer += delta
	_saw_timer += delta
	if has_weapon("melee") and _melee_timer >= melee_cooldown:
		_melee_timer = 0.0
		_perform_melee_attack()
	if has_weapon("arrow") and _arrow_timer >= fire_interval:
		_arrow_timer = 0.0
		_fire_projectile()
	if has_weapon("saw") and _active_saw == null and _saw_timer >= saw_inactive_duration:
		_saw_timer = 0.0
		_spawn_saw()

func _perform_melee_attack() -> void:
	var direction := _get_aim_direction(melee_range * 3.0)
	var hit_any := false
	if _enemies != null:
		for child in _enemies.get_children():
			var enemy := child as Node2D
			if enemy == null or (enemy.has_method("is_dead") and enemy.call("is_dead")):
				continue
			var offset := enemy.global_position - global_position
			if offset.length() > melee_range or offset.length() <= 0.01:
				continue
			if direction.dot(offset.normalized()) >= cos(melee_arc_angle * 0.5):
				enemy.call("apply_damage", melee_damage, self)
				hit_any = true
	_show_melee_arc(direction)
	_play_animation("attack", true)
	weapon_fired.emit("melee")
	if hit_any:
		AudioManager.play_sfx("player_shoot")

func _fire_projectile() -> void:
	if projectile_scene == null or _projectile_parent == null:
		return
	var nearest_enemy := _get_nearest_enemy(auto_aim_range)
	if nearest_enemy == null:
		return
	var projectile := projectile_scene.instantiate() as Area2D
	if projectile == null:
		return
	_projectile_parent.add_child(projectile)
	var aim_direction := global_position.direction_to(nearest_enemy.global_position)
	projectile.call("setup", global_position, aim_direction, projectile_damage)
	_play_animation("attack", true)
	weapon_fired.emit("arrow")
	AudioManager.play_sfx("player_shoot")

func _spawn_saw() -> void:
	if saw_scene == null:
		return
	var saw := saw_scene.instantiate()
	_projectile_parent.add_child(saw)
	_active_saw = saw
	if not saw.tree_exited.is_connected(_on_active_saw_tree_exited):
		saw.tree_exited.connect(_on_active_saw_tree_exited)
	if saw.has_method("setup"):
		saw.call("setup", self, saw_damage, saw_orbit_radius, saw_active_duration, saw_rotation_speed, saw_hit_cooldown, saw_size_multiplier)
	weapon_fired.emit("saw")

func _on_active_saw_tree_exited() -> void:
	_active_saw = null

func _get_aim_direction(search_range: float) -> Vector2:
	var nearest_enemy := _get_nearest_enemy(search_range)
	if nearest_enemy != null:
		return global_position.direction_to(nearest_enemy.global_position)
	if _last_move_direction.length_squared() > 0.001:
		return _last_move_direction.normalized()
	return Vector2.RIGHT

func _get_nearest_enemy(search_range: float = 320.0) -> Node2D:
	if _enemies == null:
		return null
	var nearest_enemy: Node2D
	var nearest_distance := search_range * search_range
	for child in _enemies.get_children():
		var enemy := child as Node2D
		if enemy == null or (enemy.has_method("is_dead") and enemy.call("is_dead")):
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	return nearest_enemy

func _show_melee_arc(direction: Vector2) -> void:
	var arc := Polygon2D.new()
	arc.name = "MeleeArc"
	arc.z_index = 10
	arc.color = Color(1.0, 0.85, 0.25, 0.35)
	var points: PackedVector2Array = [Vector2.ZERO]
	var base_angle := direction.angle()
	for index in range(13):
		var t := float(index) / 12.0
		var angle := base_angle - melee_arc_angle * 0.5 + melee_arc_angle * t
		points.append(Vector2(cos(angle), sin(angle)) * melee_range)
	arc.polygon = points
	add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.15)
	tween.tween_callback(arc.queue_free)

func _update_facing() -> void:
	if abs(input_vector.x) > 0.05:
		sprite.flip_h = input_vector.x < 0.0

func _play_animation(name: String, lock_animation: bool = false) -> void:
	if _animation_name == name:
		return
	var file := String(ANIMATION_FILES.get(name, ""))
	var path := SOLDIER_PATH + file
	if file.is_empty() or not ResourceLoader.exists(path):
		return
	_animation_name = name
	_animation_frame = 0
	_animation_time = 0.0
	_animation_locked = lock_animation
	sprite.texture = load(path)
	sprite.hframes = maxi(1, int(sprite.texture.get_width() / 100.0))
	sprite.vframes = 1
	sprite.frame = 0

func _update_animation(delta: float) -> void:
	if sprite.texture == null or sprite.hframes <= 1:
		return
	_animation_time += delta
	if _animation_time < 0.1:
		return
	_animation_time = 0.0
	_animation_frame += 1
	if _animation_frame >= sprite.hframes:
		if _animation_name == "death":
			_animation_frame = sprite.hframes - 1
		elif _animation_locked:
			_animation_locked = false
			_play_animation("idle")
			return
		else:
			_animation_frame = 0
	sprite.frame = _animation_frame
