extends Node2D

@export var value: int = 1
@export var magnet_distance: float = 120.0
@export var collect_distance: float = 18.0
@export var magnet_speed: float = 220.0
@export var player_path: NodePath

var _player: Node2D
var _time: float = 0.0

@onready var sparkle: Node2D = $Sparkle

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D

func set_player(target: Node2D) -> void:
	_player = target

func _process(delta: float) -> void:
	_time += delta
	sparkle.scale = Vector2.ONE * (1.0 + 0.12 * sin(_time * 8.0))
	if _player == null:
		return
	var offset := _player.global_position - global_position
	var distance := offset.length()
	if distance <= collect_distance:
		if _player.has_method("collect_xp"):
			_player.call("collect_xp", value)
		queue_free()
		return
	if distance <= magnet_distance and distance > 0.0:
		global_position += offset.normalized() * magnet_speed * delta
