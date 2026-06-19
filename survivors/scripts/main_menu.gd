extends Control

const GAME_SCENE := "res://scenes/main.tscn"

@onready var play_button: Button = $Panel/VBoxContainer/PlayButton
@onready var exit_button: Button = $Panel/VBoxContainer/ExitButton
@onready var audio_manager: Node = get_node("/root/AudioManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	audio_manager.play_menu_music()
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
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
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_exit_pressed() -> void:
	get_tree().quit()
