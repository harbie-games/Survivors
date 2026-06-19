extends Node

signal wave_changed(wave: int, max_waves: int)
signal timer_changed(seconds_left: float)
signal banner_requested(text: String)
signal run_completed

@export var spawner_path: NodePath
@export var enemies_path: NodePath
@export var wave_duration: float = 45.0
@export var rest_duration: float = 5.0
@export var preparation_duration: float = 2.0
@export var max_waves: int = 10

var current_wave := 0
var time_left := 0.0
var state: StringName = &"idle"
var _spawner: Node
var _enemies: Node

@onready var GameManager: Node = get_node("/root/GameManager")
@onready var AudioManager: Node = get_node("/root/AudioManager")

func _ready() -> void:
	_spawner = get_node_or_null(spawner_path)
	_enemies = get_node_or_null(enemies_path)

func start_run() -> void:
	current_wave = 0
	_begin_preparation()

func _process(delta: float) -> void:
	if state == &"idle" or GameManager.state != GameManager.STATE_PLAYING:
		return
	time_left = maxf(time_left - delta, 0.0)
	timer_changed.emit(time_left)
	match state:
		&"preparing":
			if time_left <= 0.0:
				_start_active_wave()
		&"active":
			if time_left <= 0.0:
				_spawner.call("stop_wave")
				state = &"cleanup"
		&"cleanup":
			if _enemies == null or _enemies.get_child_count() == 0:
				_finish_wave()
		&"rest":
			if time_left <= 0.0:
				_begin_preparation()

func export_save_data() -> Dictionary:
	return {"current_wave": current_wave, "time_left": time_left, "state": String(state)}

func import_save_data(data: Dictionary) -> void:
	current_wave = int(data.get("current_wave", 0))
	time_left = float(data.get("time_left", preparation_duration))
	state = StringName(data.get("state", "preparing"))
	GameManager.current_wave = current_wave
	wave_changed.emit(current_wave, max_waves)
	if state == &"active" and _spawner != null:
		_spawner.call("start_wave", current_wave)

func _begin_preparation() -> void:
	if current_wave >= max_waves:
		_complete_run()
		return
	current_wave += 1
	GameManager.current_wave = current_wave
	state = &"preparing"
	time_left = preparation_duration
	wave_changed.emit(current_wave, max_waves)
	banner_requested.emit("OLEADA %d" % current_wave)

func _start_active_wave() -> void:
	state = &"active"
	time_left = wave_duration
	if _spawner != null:
		_spawner.call("start_wave", current_wave)
	AudioManager.play_sfx("wave_start")

func _finish_wave() -> void:
	AudioManager.play_sfx("wave_complete")
	banner_requested.emit("OLEADA COMPLETADA")
	if current_wave >= max_waves:
		_complete_run()
		return
	state = &"rest"
	time_left = rest_duration

func _complete_run() -> void:
	state = &"idle"
	if _spawner != null:
		_spawner.call("stop_wave")
	GameManager.finish_run(true)
	run_completed.emit()
