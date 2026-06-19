extends Node

const SETTINGS_PATH := "user://settings.json"
const MENU_MUSIC := "res://assets/audio/music/menu_theme.mp3"
const GAMEPLAY_MUSIC := "res://assets/audio/music/gameplay_theme.mp3"
const SFX := {
	"player_shoot": "res://assets/audio/sfx/player_shoot.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"player_death": "res://assets/audio/sfx/player_death.wav",
	"enemy_attack": "res://assets/audio/sfx/enemy_attack.wav",
	"enemy_hurt": "res://assets/audio/sfx/enemy_hurt.wav",
	"enemy_death": "res://assets/audio/sfx/enemy_death.wav",
	"xp_collect": "res://assets/audio/sfx/xp_collect.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
	"wave_start": "res://assets/audio/sfx/wave_start.wav",
	"wave_complete": "res://assets/audio/sfx/wave_complete.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"pause_open": "res://assets/audio/sfx/pause_open.wav"
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cache: Dictionary = {}
var current_music_path := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = &"SFX"
		add_child(player)
		sfx_players.append(player)
	_load_settings()

func play_sfx(id: String) -> void:
	var path := String(SFX.get(id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = sfx_cache.get(id)
	if stream == null:
		stream = load(path) as AudioStream
		sfx_cache[id] = stream
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	sfx_players[0].stream = stream
	sfx_players[0].play()

func play_menu_music() -> void:
	play_music(MENU_MUSIC)

func play_gameplay_music() -> void:
	play_music(GAMEPLAY_MUSIC)

func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	if current_music_path == path and music_player.playing:
		return
	music_player.stop()
	var stream := load(path) as AudioStream
	if stream == null:
		return
	current_music_path = path
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	current_music_path = ""
	music_player.stop()

func set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear_value, 0.0, 1.0)))
	_save_settings()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _save_settings() -> void:
	var data := {}
	for bus_name in ["Master", "Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			data[bus_name] = db_to_linear(AudioServer.get_bus_volume_db(index))
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	for bus_name in ["Master", "Music", "SFX"]:
		if data.has(bus_name):
			var index := AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_volume_db(index, linear_to_db(float(data[bus_name])))
