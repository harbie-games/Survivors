extends Node

signal run_started
signal run_finished(victory: bool)
signal kills_changed(value: int)
signal state_changed(value: StringName)

const STATE_MENU: StringName = &"menu"
const STATE_PLAYING: StringName = &"playing"
const STATE_PAUSED: StringName = &"paused"
const STATE_LEVEL_UP: StringName = &"level_up"
const STATE_GAME_OVER: StringName = &"game_over"
const STATE_VICTORY: StringName = &"victory"

var state: StringName = STATE_MENU
var elapsed_time: float = 0.0
var kills: int = 0
var current_wave: int = 0
var resume_saved_run: bool = false

func request_new_run() -> void:
	resume_saved_run = false

func request_resume_saved_run() -> void:
	resume_saved_run = true

func _process(delta: float) -> void:
	if state == STATE_PLAYING:
		elapsed_time += delta

func start_run() -> void:
	resume_saved_run = false
	elapsed_time = 0.0
	kills = 0
	current_wave = 0
	set_state(STATE_PLAYING)
	run_started.emit()

func set_state(value: StringName) -> void:
	state = value
	get_tree().paused = value in [STATE_PAUSED, STATE_LEVEL_UP]
	state_changed.emit(state)

func register_kill() -> void:
	kills += 1
	kills_changed.emit(kills)

func finish_run(victory: bool) -> void:
	set_state(STATE_VICTORY if victory else STATE_GAME_OVER)
	run_finished.emit(victory)

func format_time(seconds: float = elapsed_time) -> String:
	var total := maxi(int(seconds), 0)
	return "%02d:%02d" % [total / 60, total % 60]
