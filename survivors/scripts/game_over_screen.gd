extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

@onready var retry_button: Button = $Panel/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	title_label.text = "GAME OVER"
	if not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if not main_menu_button.pressed.is_connected(_on_main_menu_pressed):
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if retry_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_retry_pressed()
		elif main_menu_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_main_menu_pressed()
	elif event.is_action_pressed("ui_accept"):
		_mark_input_handled()
		_on_retry_pressed()

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
