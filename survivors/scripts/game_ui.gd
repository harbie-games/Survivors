extends CanvasLayer

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1
const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/GameOver.tscn"

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var enemies_path: NodePath
@export var projectiles_path: NodePath
@export var xp_drops_path: NodePath
@export var wave_manager_path: NodePath = NodePath("../WaveManager")

var _player: CharacterBody2D
var _enemy_spawner: Node
var _enemies: Node
var _projectiles: Node
var _xp_drops: Node
var _wave_manager: Node
var _pending_level_ups := 0
var _option_buttons: Array[Button] = []
var _autosave_timer := 0.0
var _banner_timer := 0.0
var _options_return_state: StringName = &"menu"

@onready var GameManager: Node = get_node("/root/GameManager")
@onready var AudioManager: Node = get_node("/root/AudioManager")
@onready var UpgradeManager: Node = get_node("/root/UpgradeManager")
@onready var hud: Control = $HUD
@onready var joystick: Control = get_node("../JoystickLayer/TouchJoystick")
@onready var start_screen: Control = $StartScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var level_up_screen: Control = $LevelUpScreen
@onready var pause_screen: Control = $PauseScreen
@onready var options_screen: Control = $OptionsScreen
@onready var health_bar: ColorRect = $HUD/HealthBar
@onready var health_fill: ColorRect = $HUD/HealthBar/Fill
@onready var xp_bar: ColorRect = $HUD/XpBar
@onready var xp_fill: ColorRect = $HUD/XpBar/Fill
@onready var level_label: Label = $HUD/XpBar/LevelLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var kills_label: Label = $HUD/KillsLabel
@onready var banner_label: Label = $HUD/BannerLabel
@onready var start_button: Button = $StartScreen/Panel/VBoxContainer/StartButton
@onready var continue_button: Button = $StartScreen/Panel/VBoxContainer/ContinueButton
@onready var options_button: Button = $StartScreen/Panel/VBoxContainer/OptionsButton
@onready var main_exit_button: Button = $StartScreen/Panel/VBoxContainer/MainExitButton
@onready var restart_button: Button = $GameOverScreen/Panel/VBoxContainer/RestartButton
@onready var game_over_title: Label = $GameOverScreen/Panel/VBoxContainer/Title
@onready var option_button_1: Button = $LevelUpScreen/Panel/VBoxContainer/Options/OptionButton1
@onready var option_button_2: Button = $LevelUpScreen/Panel/VBoxContainer/Options/OptionButton2
@onready var option_button_3: Button = $LevelUpScreen/Panel/VBoxContainer/Options/OptionButton3
@onready var maxed_button: Button = $LevelUpScreen/Panel/VBoxContainer/MaxedButton
@onready var pause_button: Button = $PauseButton
@onready var resume_button: Button = $PauseScreen/Panel/VBoxContainer/ResumeButton
@onready var exit_button: Button = $PauseScreen/Panel/VBoxContainer/ExitButton
@onready var music_slider: HSlider = $OptionsScreen/Panel/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $OptionsScreen/Panel/VBoxContainer/SfxSlider
@onready var options_back_button: Button = $OptionsScreen/Panel/VBoxContainer/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_node_or_null(player_path) as CharacterBody2D
	_enemy_spawner = get_node_or_null(enemy_spawner_path)
	_enemies = get_node_or_null(enemies_path)
	_projectiles = get_node_or_null(projectiles_path)
	_xp_drops = get_node_or_null(xp_drops_path)
	_wave_manager = get_node_or_null(wave_manager_path)
	_option_buttons = [option_button_1, option_button_2, option_button_3]
	_connect_ui()
	_connect_gameplay()
	call_deferred("_enter_gameplay_from_menu")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if GameManager.state == GameManager.STATE_PLAYING:
			_on_pause_pressed()
		elif GameManager.state == GameManager.STATE_PAUSED:
			_on_resume_pressed()
	if GameManager.state == GameManager.STATE_PLAYING:
		_autosave_timer += delta
		timer_label.text = "TIEMPO %s" % GameManager.format_time()
		if _autosave_timer >= 15.0:
			_autosave_timer = 0.0
			_save_game()
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.state == GameManager.STATE_PLAYING and pause_button.visible and pause_button.get_global_rect().has_point(event.position):
			_mark_input_handled()
			_on_pause_pressed()
			return
		if GameManager.state == GameManager.STATE_PAUSED and pause_screen.visible:
			if resume_button.get_global_rect().has_point(event.position):
				_mark_input_handled()
				_on_resume_pressed()
				return
			if exit_button.get_global_rect().has_point(event.position):
				_mark_input_handled()
				_save_and_return_to_menu()
				return
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and key_event.keycode == KEY_C and GameManager.state == GameManager.STATE_MENU and continue_button.visible:
		_mark_input_handled()
		_on_continue_pressed()
		return
	if event.is_action_pressed("ui_accept") and GameManager.state == GameManager.STATE_MENU and start_screen.visible:
		_mark_input_handled()
		_on_start_pressed()
		return
	var escape_pressed: bool = event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)
	if event.is_action_pressed("pause") or escape_pressed:
		if GameManager.state == GameManager.STATE_PLAYING:
			_on_pause_pressed()
		elif GameManager.state == GameManager.STATE_PAUSED:
			_on_resume_pressed()

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _connect_ui() -> void:
	_safe_connect(start_button.pressed, _on_start_pressed)
	_safe_connect(continue_button.pressed, _on_continue_pressed)
	_safe_connect(options_button.pressed, _on_options_pressed)
	_safe_connect(main_exit_button.pressed, _on_quit_pressed)
	_safe_connect(restart_button.pressed, _on_restart_pressed)
	_safe_connect(pause_button.pressed, _on_pause_pressed)
	_safe_connect(resume_button.pressed, _on_resume_pressed)
	_safe_connect(exit_button.pressed, _save_and_return_to_menu)
	_safe_connect(options_back_button.pressed, _close_options)
	_safe_connect(music_slider.value_changed, _on_music_volume_changed)
	_safe_connect(sfx_slider.value_changed, _on_sfx_volume_changed)
	for button in _option_buttons:
		var callback := _on_upgrade_option_pressed.bind(button)
		_safe_connect(button.pressed, callback)
	_safe_connect(maxed_button.pressed, _resolve_level_up_choice)

func _safe_connect(signal_value: Signal, callback: Callable) -> void:
	if not signal_value.is_connected(callback):
		signal_value.connect(callback)

func _on_options_pressed() -> void:
	_open_options(GameManager.STATE_MENU)

func _connect_gameplay() -> void:
	if _player != null:
		_player.hp_changed.connect(_on_player_hp_changed)
		_player.xp_changed.connect(_on_player_xp_changed)
		_player.leveled_up.connect(_on_player_leveled_up)
		_player.died.connect(_on_player_died)
	if _wave_manager != null:
		_wave_manager.wave_changed.connect(_on_wave_changed)
		_wave_manager.timer_changed.connect(_on_wave_timer_changed)
		_wave_manager.banner_requested.connect(_show_banner)
	GameManager.kills_changed.connect(_on_kills_changed)
	GameManager.run_finished.connect(_on_run_finished)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_start_new_gameplay_run()

func _enter_gameplay_from_menu() -> void:
	if bool(GameManager.get("resume_saved_run")) and _has_save_game():
		_continue_saved_gameplay_run()
	else:
		_start_new_gameplay_run()

func _start_new_gameplay_run() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	GameManager.set("resume_saved_run", false)
	_clear_save_game()
	_clear_world()
	_reset_player()
	GameManager.start_run()
	AudioManager.play_gameplay_music()
	_show_gameplay()
	if _wave_manager != null:
		_wave_manager.call_deferred("start_run")

func _continue_saved_gameplay_run() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	GameManager.set("resume_saved_run", false)
	_clear_world()
	if not _load_game():
		_start_new_gameplay_run()
		return
	GameManager.set_state(GameManager.STATE_PLAYING)
	AudioManager.play_gameplay_music()
	_show_gameplay()
	_update_bars()

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if not _load_game():
		continue_button.visible = false
		return
	GameManager.set_state(GameManager.STATE_PLAYING)
	_show_gameplay()

func _on_restart_pressed() -> void:
	_start_new_gameplay_run()

func _on_pause_pressed() -> void:
	if GameManager.state != GameManager.STATE_PLAYING:
		return
	_save_game()
	GameManager.set_state(GameManager.STATE_PAUSED)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_screen.visible = true
	pause_button.visible = false
	AudioManager.play_sfx("pause_open")

func _on_resume_pressed() -> void:
	pause_screen.visible = false
	pause_button.visible = true
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	GameManager.set_state(GameManager.STATE_PLAYING)

func _save_and_return_to_menu() -> void:
	if GameManager.state in [GameManager.STATE_PLAYING, GameManager.STATE_PAUSED, GameManager.STATE_LEVEL_UP]:
		_save_game()
	_exit_to_main_menu()

func _on_quit_pressed() -> void:
	if GameManager.state in [GameManager.STATE_PLAYING, GameManager.STATE_PAUSED]:
		_save_game()
	get_tree().quit()

func _open_options(return_state: StringName) -> void:
	_options_return_state = return_state
	hud.visible = false
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_screen.visible = true
	start_screen.visible = false
	pause_screen.visible = false
	AudioManager.play_sfx("ui_click")

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"Music", value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_bus_volume(&"SFX", value)

func _close_options() -> void:
	options_screen.visible = false
	if _options_return_state == GameManager.STATE_PAUSED:
		hud.visible = true
		pause_screen.visible = true
	else:
		hud.visible = false
		start_screen.visible = true

func _on_player_hp_changed(current_hp: float, maximum_hp: float) -> void:
	var ratio := current_hp / maximum_hp if maximum_hp > 0.0 else 0.0
	var fill_width := health_bar.size.x * clampf(ratio, 0.0, 1.0)
	health_fill.custom_minimum_size.x = fill_width
	health_fill.size.x = fill_width

func _on_player_xp_changed(current_xp: int, required_xp: int, current_level: int) -> void:
	var ratio := float(current_xp) / float(required_xp) if required_xp > 0 else 0.0
	xp_fill.size.x = xp_bar.size.x * clampf(ratio, 0.0, 1.0)
	level_label.text = "LV %d" % current_level

func _on_player_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	AudioManager.play_sfx("level_up")
	if not level_up_screen.visible:
		_open_level_up_screen()

func _open_level_up_screen() -> void:
	GameManager.set_state(GameManager.STATE_LEVEL_UP)
	level_up_screen.visible = true
	pause_button.visible = false
	var choices: Array = UpgradeManager.build_choices(_player, 3)
	for index in range(_option_buttons.size()):
		var button := _option_buttons[index]
		button.visible = index < choices.size()
		button.disabled = index >= choices.size()
		button.set_meta("upgrade_id", "")
		if index < choices.size():
			var choice: Dictionary = choices[index]
			button.text = "%s %d/5\n%s" % [choice.title, choice.next_level, choice.description]
			button.icon = load(String(choice.icon)) if ResourceLoader.exists(String(choice.icon)) else null
			button.expand_icon = true
			button.set_meta("upgrade_id", choice.id)
	maxed_button.visible = choices.is_empty()

func _on_upgrade_option_pressed(button: Button) -> void:
	var id := String(button.get_meta("upgrade_id", ""))
	if UpgradeManager.apply_choice(_player, id):
		_resolve_level_up_choice()

func _resolve_level_up_choice() -> void:
	_pending_level_ups = maxi(_pending_level_ups - 1, 0)
	if _pending_level_ups > 0:
		_open_level_up_screen()
		return
	level_up_screen.visible = false
	pause_button.visible = true
	GameManager.set_state(GameManager.STATE_PLAYING)

func _on_player_died() -> void:
	_on_player_hp_changed(0.0, _player.max_hp)
	_stop_gameplay_systems()
	GameManager.finish_run(false)

func _on_run_finished(_victory: bool) -> void:
	get_tree().paused = false
	_stop_gameplay_systems()
	hud.visible = false
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.visible = false
	level_up_screen.visible = false
	pause_screen.visible = false
	game_over_screen.visible = false
	AudioManager.stop_music()
	_clear_save_game()
	_show_game_over_scene()

func _on_wave_changed(wave: int, maximum: int) -> void:
	wave_label.text = "OLEADA %d/%d" % [wave, maximum]
	_save_game()

func _on_wave_timer_changed(seconds_left: float) -> void:
	wave_label.tooltip_text = "Restan %.0f segundos" % seconds_left

func _on_kills_changed(value: int) -> void:
	kills_label.text = "BAJAS %d" % value

func _show_banner(text: String) -> void:
	banner_label.text = text
	banner_label.visible = true
	_banner_timer = 2.0

func _show_main_menu() -> void:
	_exit_to_main_menu()

func _show_gameplay() -> void:
	hud.visible = true
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	start_screen.visible = false
	game_over_screen.visible = false
	level_up_screen.visible = false
	pause_screen.visible = false
	options_screen.visible = false
	pause_button.visible = true
	if _player != null:
		_player.set_process(true)
		_player.set_physics_process(true)

func _exit_to_main_menu() -> void:
	_stop_gameplay_systems()
	get_tree().paused = false
	AudioManager.play_menu_music()
	GameManager.set_state(GameManager.STATE_MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _show_game_over_scene() -> void:
	var scene := load(GAME_OVER_SCENE) as PackedScene
	if scene == null:
		game_over_screen.visible = true
		return
	var screen := scene.instantiate() as Control
	add_child(screen)

func _stop_gameplay_systems() -> void:
	if _enemy_spawner != null and _enemy_spawner.has_method("stop_wave"):
		_enemy_spawner.call("stop_wave")
	if _wave_manager != null:
		_wave_manager.set("state", &"idle")
	if _player != null:
		_player.set_physics_process(false)
	for group_node in [_enemies, _projectiles, _xp_drops]:
		if group_node == null:
			continue
		for child in group_node.get_children():
			child.set_process(false)
			child.set_physics_process(false)

func _update_bars() -> void:
	if _player != null:
		_on_player_hp_changed(_player.hp, _player.max_hp)
		_on_player_xp_changed(_player.xp, _player.xp_required, _player.level)

func _reset_player() -> void:
	if _player == null:
		return
	if _player.has_method("reset_run_state"):
		_player.call("reset_run_state")

func _clear_world() -> void:
	_clear_children(_enemies)
	_clear_children(_projectiles)
	_clear_children(_xp_drops)

func _save_game() -> void:
	if _player == null or GameManager.state in [GameManager.STATE_MENU, GameManager.STATE_GAME_OVER, GameManager.STATE_VICTORY]:
		return
	var data := {
		"save_version": SAVE_VERSION,
		"player": _player.export_save_data(),
		"wave": _wave_manager.export_save_data() if _wave_manager != null else {},
		"run_stats": {"elapsed_time": GameManager.elapsed_time, "kills": GameManager.kills},
		"enemies": [], "xp_orbs": []
	}
	for enemy in _enemies.get_children():
		data.enemies.append({"position": [enemy.global_position.x, enemy.global_position.y], "hp": enemy.hp, "type": enemy.enemy_type})
	for orb in _xp_drops.get_children():
		data.xp_orbs.append({"position": [orb.global_position.x, orb.global_position.y], "value": orb.value})
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))

func _load_game() -> bool:
	if not _has_save_game():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data := parsed as Dictionary
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		return false
	_clear_world()
	_player.import_save_data(data.get("player", {}))
	var stats: Dictionary = data.get("run_stats", {})
	GameManager.elapsed_time = float(stats.get("elapsed_time", 0.0))
	GameManager.kills = int(stats.get("kills", 0))
	GameManager.kills_changed.emit(GameManager.kills)
	if _wave_manager != null:
		_wave_manager.import_save_data(data.get("wave", {}))
	_restore_enemies(data.get("enemies", []))
	_restore_orbs(data.get("xp_orbs", []))
	return true

func _restore_enemies(items: Array) -> void:
	for item_variant in items:
		var item := item_variant as Dictionary
		var enemy := _enemy_spawner.spawn_enemy(String(item.get("type", "normal"))) as Node2D
		if enemy == null:
			continue
		var position_data: Array = item.get("position", [0.0, 0.0])
		enemy.global_position = Vector2(float(position_data[0]), float(position_data[1]))
		enemy.hp = clampf(float(item.get("hp", enemy.max_hp)), 0.1, enemy.max_hp)

func _restore_orbs(items: Array) -> void:
	var orb_scene := _enemy_spawner.xp_drop_scene as PackedScene
	for item_variant in items:
		var item := item_variant as Dictionary
		var orb := orb_scene.instantiate() as Node2D
		_xp_drops.add_child(orb)
		var position_data: Array = item.get("position", [0.0, 0.0])
		orb.global_position = Vector2(float(position_data[0]), float(position_data[1]))
		orb.value = int(item.get("value", 1))
		orb.set_player(_player)

func _has_save_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _clear_save_game() -> void:
	if _has_save_game():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_save_game()
