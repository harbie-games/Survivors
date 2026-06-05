extends CanvasLayer

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var enemies_path: NodePath
@export var projectiles_path: NodePath
@export var xp_drops_path: NodePath
@export var health_bar_width: float = 420.0
@export var health_bar_max_width_ratio: float = 0.82
@export var health_bar_min_width: float = 240.0
@export var health_bar_bottom_margin: float = 28.0
@export var xp_bar_gap: float = 10.0
@export var menu_panel_max_width: float = 380.0
@export var menu_panel_horizontal_margin: float = 24.0

var _player: Node
var _enemy_spawner: Node
var _enemies: Node
var _projectiles: Node
var _xp_drops: Node

@onready var start_screen: Control = $StartScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var health_bar: ColorRect = $HUD/HealthBar
@onready var health_fill: ColorRect = $HUD/HealthBar/Fill
@onready var xp_bar: ColorRect = $HUD/XpBar
@onready var xp_fill: ColorRect = $HUD/XpBar/Fill
@onready var level_label: Label = $HUD/XpBar/LevelLabel
@onready var start_panel: Panel = $StartScreen/Panel
@onready var game_over_panel: Panel = $GameOverScreen/Panel
@onready var start_button: Button = $StartScreen/Panel/VBoxContainer/StartButton
@onready var restart_button: Button = $GameOverScreen/Panel/VBoxContainer/RestartButton

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_enemy_spawner = get_node_or_null(enemy_spawner_path)
	_enemies = get_node_or_null(enemies_path)
	_projectiles = get_node_or_null(projectiles_path)
	_xp_drops = get_node_or_null(xp_drops_path)
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_responsive_layout()
	if _player != null:
		_player.hp_changed.connect(_on_player_hp_changed)
		_player.xp_changed.connect(_on_player_xp_changed)
		_player.died.connect(_on_player_died)
		_on_player_hp_changed(_player.hp, _player.max_hp)
		_on_player_xp_changed(_player.xp, _player.xp_required, _player.level)
	_set_playing(false)
	start_screen.visible = true
	game_over_screen.visible = false

func _on_player_hp_changed(current_hp: float, max_hp: float) -> void:
	var ratio := 0.0
	if max_hp > 0.0:
		ratio = clampf(current_hp / max_hp, 0.0, 1.0)
	_update_responsive_layout()
	health_fill.custom_minimum_size.x = health_bar_width * ratio
	health_fill.size.x = health_bar_width * ratio

func _on_player_xp_changed(current_xp: int, xp_required: int, level: int) -> void:
	var ratio := 0.0
	if xp_required > 0:
		ratio = clampf(float(current_xp) / float(xp_required), 0.0, 1.0)
	_update_responsive_layout()
	xp_fill.custom_minimum_size.x = health_bar_width * ratio
	xp_fill.size.x = health_bar_width * ratio
	level_label.text = "LV %d" % level

func _on_viewport_size_changed() -> void:
	if _player != null:
		_on_player_hp_changed(_player.hp, _player.max_hp)
		_on_player_xp_changed(_player.xp, _player.xp_required, _player.level)
	else:
		_update_responsive_layout()

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_update_health_bar_layout(viewport_size)
	_update_xp_bar_layout(viewport_size)
	_update_menu_panel(start_panel, viewport_size, 160.0)
	_update_menu_panel(game_over_panel, viewport_size, 180.0)

func _update_health_bar_layout(viewport_size: Vector2) -> void:
	health_bar_width = clampf(viewport_size.x * health_bar_max_width_ratio, health_bar_min_width, viewport_size.x - 32.0)
	var bar_height := health_bar.size.y
	if bar_height <= 0.0:
		bar_height = 18.0
	health_bar.anchor_left = 0.5
	health_bar.anchor_right = 0.5
	health_bar.anchor_top = 1.0
	health_bar.anchor_bottom = 1.0
	health_bar.offset_left = -health_bar_width * 0.5
	health_bar.offset_right = health_bar_width * 0.5
	health_bar.offset_top = -health_bar_bottom_margin - bar_height
	health_bar.offset_bottom = -health_bar_bottom_margin
	health_fill.offset_bottom = bar_height

func _update_xp_bar_layout(viewport_size: Vector2) -> void:
	var bar_height := xp_bar.size.y
	if bar_height <= 0.0:
		bar_height = 16.0
	xp_bar.anchor_left = 0.5
	xp_bar.anchor_right = 0.5
	xp_bar.anchor_top = 1.0
	xp_bar.anchor_bottom = 1.0
	xp_bar.offset_left = -health_bar_width * 0.5
	xp_bar.offset_right = health_bar_width * 0.5
	xp_bar.offset_top = -health_bar_bottom_margin - health_bar.size.y - xp_bar_gap - bar_height
	xp_bar.offset_bottom = -health_bar_bottom_margin - health_bar.size.y - xp_bar_gap
	xp_fill.offset_bottom = bar_height
	level_label.position = Vector2(10.0, -2.0)

func _update_menu_panel(panel: Panel, viewport_size: Vector2, preferred_height: float) -> void:
	var panel_width := minf(menu_panel_max_width, viewport_size.x - menu_panel_horizontal_margin * 2.0)
	var panel_height := minf(preferred_height, viewport_size.y - menu_panel_horizontal_margin * 2.0)
	panel.offset_left = -panel_width * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_bottom = panel_height * 0.5

func _on_start_pressed() -> void:
	start_screen.visible = false
	game_over_screen.visible = false
	_set_playing(true)

func _on_player_died() -> void:
	_set_playing(false)
	game_over_screen.visible = true

func _on_restart_pressed() -> void:
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _set_playing(is_playing: bool) -> void:
	if _player != null:
		_player.set_physics_process(is_playing)
	if _enemy_spawner != null:
		_enemy_spawner.set_process(is_playing)
	if _enemies != null:
		for enemy in _enemies.get_children():
			enemy.set_physics_process(is_playing)
	if _projectiles != null:
		for projectile in _projectiles.get_children():
			projectile.set_physics_process(is_playing)
	if _xp_drops != null:
		for xp_orb in _xp_drops.get_children():
			xp_orb.set_process(is_playing)
