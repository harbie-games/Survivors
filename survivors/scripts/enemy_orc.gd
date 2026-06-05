extends CharacterBody2D

@export var speed: float = 150.0
@export var contact_damage_per_second: float = 12.0
@export var max_hp: float = 5.0
@export var xp_drop_scene: PackedScene
@export var xp_drop_parent_path: NodePath
@export var target_path: NodePath

var hp: float = 5.0
var _target: Node2D
var _touching_player: bool = false
var _is_dead: bool = false
var _xp_drop_parent: Node

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	hp = max_hp
	_target = get_node_or_null(target_path) as Node2D
	_xp_drop_parent = get_node_or_null(xp_drop_parent_path)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

func set_target(target: Node2D) -> void:
	_target = target

func set_xp_drop_parent(parent_node: Node) -> void:
	_xp_drop_parent = parent_node

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return
	if _target == null:
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(_target.global_position)
	velocity = direction * speed
	move_and_slide()
	_update_facing(direction)
	_apply_contact_damage(delta)

func apply_damage(amount: float) -> void:
	if _is_dead:
		return
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		_is_dead = true
		_drop_xp()
		queue_free()

func _drop_xp() -> void:
	if xp_drop_scene == null or _target == null:
		return
	var drop_parent := _xp_drop_parent
	if drop_parent == null:
		drop_parent = get_parent()
	var xp_orb := xp_drop_scene.instantiate() as Node2D
	if xp_orb == null:
		return
	drop_parent.add_child(xp_orb)
	xp_orb.global_position = global_position
	if xp_orb.has_method("set_player"):
		xp_orb.call("set_player", _target)

func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) > 0.05:
		sprite.flip_h = direction.x < 0.0

func _apply_contact_damage(delta: float) -> void:
	if not _touching_player or _target == null:
		return
	if _target.has_method("apply_damage"):
		_target.call("apply_damage", contact_damage_per_second * delta)

func _on_hurtbox_body_entered(body: Node) -> void:
	if body == _target:
		_touching_player = true

func _on_hurtbox_body_exited(body: Node) -> void:
	if body == _target:
		_touching_player = false
