extends Control

signal direction_changed(direction: Vector2)

@export var radius: float = 72.0
@export var knob_radius: float = 24.0

var _active_touch_id: int = -1
var _center: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.ZERO

@onready var base: Panel = $Base
@onready var knob: Panel = $Knob

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	base.visible = false
	knob.visible = false
	_update_visuals()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _active_touch_id == -2:
		_update_direction(event.position)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _active_touch_id == -1:
		_start(event.index, event.position)
	elif not event.pressed and event.index == _active_touch_id:
		_stop()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _active_touch_id:
		_update_direction(event.position)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and _active_touch_id == -1:
		_start(-2, event.position)
	elif not event.pressed and _active_touch_id == -2:
		_stop()

func _start(touch_id: int, screen_position: Vector2) -> void:
	_active_touch_id = touch_id
	_center = screen_position
	base.visible = true
	knob.visible = true
	_update_direction(screen_position)

func _stop() -> void:
	_active_touch_id = -1
	_direction = Vector2.ZERO
	base.visible = false
	knob.visible = false
	direction_changed.emit(Vector2.ZERO)

func _update_direction(screen_position: Vector2) -> void:
	var offset := screen_position - _center
	_direction = offset.limit_length(radius) / radius
	_update_visuals()
	direction_changed.emit(_direction)

func _update_visuals() -> void:
	base.position = _center - Vector2(radius, radius)
	base.size = Vector2(radius * 2.0, radius * 2.0)
	knob.position = _center + (_direction * radius) - Vector2(knob_radius, knob_radius)
	knob.size = Vector2(knob_radius * 2.0, knob_radius * 2.0)
