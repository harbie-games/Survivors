extends CharacterBody2D

signal enemy_died(enemy: Node, xp_value: int)

const ORC_PATH := "res://assets/Characters(100x100)/Orc/Orc/"
const TYPE_PATHS := {
	"normal": ORC_PATH,
	"fast": "res://assets/characters/fast_enemy/",
	"elite": "res://assets/characters/elite_enemy/"
}
const FILE_PREFIX := {"normal": "Orc-", "fast": "fast_enemy_", "elite": "elite_enemy_"}

@export var speed: float = 110.0
@export var contact_damage: float = 10.0
@export var attack_cooldown: float = 0.75
@export var max_hp: float = 12.0
@export var xp_value: int = 1
@export var xp_drop_scene: PackedScene
@export var xp_drop_parent_path: NodePath
@export var target_path: NodePath

var hp: float = 12.0
var enemy_type := "normal"
var _target: Node2D
var _touching_player := false
var _is_dead := false
var _attack_timer := 0.0
var _xp_drop_parent: Node

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var AudioManager: Node = get_node("/root/AudioManager")
@onready var GameManager: Node = get_node("/root/GameManager")

func _ready() -> void:
	hp = max_hp
	_target = get_node_or_null(target_path) as Node2D
	_xp_drop_parent = get_node_or_null(xp_drop_parent_path)
	_configure_animations()
	_play("walk")

func configure(type_id: String, wave: int) -> void:
	enemy_type = type_id
	match enemy_type:
		"fast":
			max_hp = 7.0
			speed = 175.0
			contact_damage = 7.0
			xp_value = 1
		"elite":
			max_hp = 80.0
			speed = 85.0
			contact_damage = 18.0
			xp_value = 10
		_:
			max_hp = 12.0
			speed = 110.0
			contact_damage = 10.0
			xp_value = 1
	var wave_index := maxi(wave - 1, 0)
	max_hp *= pow(1.15, wave_index)
	contact_damage *= pow(1.08, wave_index)
	speed *= minf(pow(1.02, wave_index), 1.2)
	hp = max_hp
	if is_node_ready():
		_configure_animations()

func set_target(target: Node2D) -> void:
	_target = target

func set_xp_drop_parent(parent_node: Node) -> void:
	_xp_drop_parent = parent_node

func _physics_process(delta: float) -> void:
	if _is_dead or _target == null:
		velocity = Vector2.ZERO
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _touching_player:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			_play("attack")
			AudioManager.play_sfx("enemy_attack")
			if _target.has_method("apply_damage"):
				_target.call("apply_damage", contact_damage, self)
		return
	var direction := global_position.direction_to(_target.global_position)
	velocity = direction * speed
	move_and_slide()
	if abs(direction.x) > 0.05:
		sprite.flip_h = direction.x < 0.0
	_play("walk")

func apply_damage(amount: float, _source: Node = null) -> void:
	if _is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	AudioManager.play_sfx("enemy_hurt")
	if hp <= 0.0:
		_die()
	else:
		_play("hurt")

func is_dead() -> bool:
	return _is_dead

func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	_drop_xp()
	GameManager.register_kill()
	enemy_died.emit(self, xp_value)
	AudioManager.play_sfx("enemy_death")
	_play("death")
	await get_tree().create_timer(0.55).timeout
	queue_free()

func _drop_xp() -> void:
	if xp_drop_scene == null or _target == null:
		return
	var drop_parent := _xp_drop_parent if _xp_drop_parent != null else get_parent()
	var xp_orb := xp_drop_scene.instantiate() as Node2D
	if xp_orb == null:
		return
	drop_parent.add_child(xp_orb)
	xp_orb.global_position = global_position
	xp_orb.set("value", xp_value)
	if xp_orb.has_method("set_player"):
		xp_orb.call("set_player", _target)

func _on_hurtbox_body_entered(body: Node) -> void:
	if body == _target:
		_touching_player = true

func _on_hurtbox_body_exited(body: Node) -> void:
	if body == _target:
		_touching_player = false

func _configure_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in ["idle", "walk", "attack", "hurt", "death"]:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 10.0)
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk"])
		var texture := _load_animation_texture(animation_name)
		if texture == null:
			continue
		var frame_count := maxi(1, int(texture.get_width() / 100.0))
		for index in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(index * 100.0, 0.0, 100.0, 100.0)
			frames.add_frame(animation_name, atlas)
	sprite.sprite_frames = frames

func _load_animation_texture(animation_name: String) -> Texture2D:
	var prefix := String(FILE_PREFIX.get(enemy_type, "Orc-"))
	var suffix := animation_name.capitalize() if enemy_type == "normal" else animation_name
	var path := String(TYPE_PATHS.get(enemy_type, ORC_PATH)) + prefix + suffix + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var fallback := ORC_PATH + "Orc-" + animation_name.capitalize() + ".png"
	return load(fallback) as Texture2D if ResourceLoader.exists(fallback) else null

func _play(animation_name: String) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation == animation_name and sprite.is_playing():
		return
	sprite.play(animation_name)
