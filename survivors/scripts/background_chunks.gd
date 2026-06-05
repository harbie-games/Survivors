extends Node2D

@export var target_path: NodePath
@export var grass_texture: Texture2D
@export var chunk_size: int = 512
@export var active_radius_chunks: int = 3

var _target: Node2D
var _chunks: Dictionary = {}

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	if grass_texture == null:
		grass_texture = load("res://assets/backgrounds/grass_tile_kenney.png")
	_update_chunks(true)

func _process(_delta: float) -> void:
	_update_chunks(false)

func _update_chunks(force: bool) -> void:
	if _target == null:
		return

	var center_chunk := _world_to_chunk(_target.global_position)
	var needed := {}
	for x in range(center_chunk.x - active_radius_chunks, center_chunk.x + active_radius_chunks + 1):
		for y in range(center_chunk.y - active_radius_chunks, center_chunk.y + active_radius_chunks + 1):
			var coords := Vector2i(x, y)
			needed[coords] = true
			if force or not _chunks.has(coords):
				_spawn_chunk(coords)

	for coords in _chunks.keys():
		if not needed.has(coords):
			var chunk := _chunks[coords] as Node
			_chunks.erase(coords)
			chunk.queue_free()

func _world_to_chunk(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / chunk_size), floori(world_position.y / chunk_size))

func _spawn_chunk(coords: Vector2i) -> void:
	var chunk := Sprite2D.new()
	chunk.name = "GrassChunk_%d_%d" % [coords.x, coords.y]
	chunk.texture = grass_texture
	chunk.centered = false
	chunk.position = Vector2(coords.x * chunk_size, coords.y * chunk_size)
	chunk.region_enabled = true
	chunk.region_rect = Rect2(Vector2.ZERO, Vector2(chunk_size, chunk_size))
	chunk.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	chunk.z_index = -100
	add_child(chunk)
	_chunks[coords] = chunk
