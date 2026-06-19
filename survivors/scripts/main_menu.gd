extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://savegame.json"

@onready var play_button: Button = $Panel/VBoxContainer/PlayButton
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton
@onready var exit_button: Button = $Panel/VBoxContainer/ExitButton
@onready var audio_manager: Node = get_node("/root/AudioManager")
@onready var game_manager: Node = get_node("/root/GameManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	audio_manager.play_menu_music()
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	if not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_on_play_pressed()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if play_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_play_pressed()
		elif continue_button.visible and continue_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_continue_pressed()
		elif exit_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_exit_pressed()
	elif event.is_action_pressed("ui_accept"):
		_mark_input_handled()
		_on_play_pressed()

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _on_play_pressed() -> void:
	audio_manager.play_sfx("ui_click")
	game_manager.request_new_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_continue_pressed() -> void:
	audio_manager.play_sfx("ui_click")
	game_manager.request_resume_saved_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_exit_pressed() -> void:
	get_tree().quit()
