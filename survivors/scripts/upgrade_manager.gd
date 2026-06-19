extends Node

const DEFINITIONS := {
	"unlock_arrow": {"title": "DESBLOQUEAR ARROW", "description": "Agrega disparos a distancia", "max": 1, "type": "unlock", "weapon": "arrow", "icon": "res://assets/ui/upgrades/arrow_damage.png"},
	"unlock_saw": {"title": "DESBLOQUEAR SAW", "description": "Agrega una sierra orbital", "max": 1, "type": "unlock", "weapon": "saw", "icon": "res://assets/ui/upgrades/armor.png"},
	"arrow_damage": {"title": "ARROW DAMAGE", "description": "+40% daño de flecha", "max": 5, "type": "weapon", "weapon": "arrow", "icon": "res://assets/ui/upgrades/arrow_damage.png"},
	"fire_rate": {"title": "FIRE RATE", "description": "-12% cooldown de flecha", "max": 5, "type": "weapon", "weapon": "arrow", "icon": "res://assets/ui/upgrades/fire_rate.png"},
	"melee_damage": {"title": "MELEE DAMAGE", "description": "+35% daño melee", "max": 5, "type": "weapon", "weapon": "melee", "icon": "res://assets/ui/upgrades/move_speed.png"},
	"melee_range": {"title": "MELEE RANGE", "description": "+18 px de rango melee", "max": 5, "type": "weapon", "weapon": "melee", "icon": "res://assets/ui/upgrades/pickup_radius.png"},
	"saw_damage": {"title": "SAW DAMAGE", "description": "+35% daño de sierra", "max": 5, "type": "weapon", "weapon": "saw", "icon": "res://assets/ui/upgrades/max_health.png"},
	"saw_size": {"title": "SAW SIZE", "description": "+tamaño y órbita de sierra", "max": 5, "type": "weapon", "weapon": "saw", "icon": "res://assets/ui/upgrades/armor.png"},
	"move_speed": {"title": "MOVE SPEED", "description": "+10% velocidad", "max": 5, "type": "stat", "icon": "res://assets/ui/upgrades/move_speed.png"},
	"max_health": {"title": "MAX HEALTH", "description": "+20 vida y curación", "max": 5, "type": "stat", "icon": "res://assets/ui/upgrades/max_health.png"},
	"pickup_radius": {"title": "PICKUP RADIUS", "description": "+35 px imán XP", "max": 5, "type": "stat", "icon": "res://assets/ui/upgrades/pickup_radius.png"},
	"armor": {"title": "ARMOR", "description": "-8% daño recibido", "max": 5, "type": "stat", "icon": "res://assets/ui/upgrades/armor.png"}
}

func build_choices(player: Node, count: int = 3) -> Array[Dictionary]:
	var candidates: Array[String] = []
	for id in DEFINITIONS:
		if _can_offer(player, id):
			candidates.append(id)
	candidates.shuffle()
	var choices: Array[Dictionary] = []
	for index in range(mini(count, candidates.size())):
		var id := candidates[index]
		var definition: Dictionary = DEFINITIONS[id].duplicate()
		definition["id"] = id
		definition["next_level"] = player.get_upgrade_level(id) + 1
		definition["icon"] = _resolve_icon(String(definition.get("icon", "")))
		choices.append(definition)
	return choices

func apply_choice(player: Node, id: String) -> bool:
	if not DEFINITIONS.has(id):
		return false
	return player.apply_upgrade(id)

func get_definition(id: String) -> Dictionary:
	if not DEFINITIONS.has(id):
		return {}
	var definition: Dictionary = DEFINITIONS[id].duplicate()
	definition["id"] = id
	definition["icon"] = _resolve_icon(String(definition.get("icon", "")))
	return definition

func _can_offer(player: Node, id: String) -> bool:
	var definition: Dictionary = DEFINITIONS[id]
	var max_level := int(definition.max)
	var type := String(definition.get("type", "stat"))
	if type == "unlock":
		var weapon := String(definition.weapon)
		return not player.has_weapon(weapon)
	if player.get_upgrade_level(id) >= max_level:
		return false
	if type == "weapon":
		var weapon := String(definition.weapon)
		return player.has_weapon(weapon)
	return true

func _resolve_icon(path: String) -> String:
	if ResourceLoader.exists(path):
		return path
	return "res://assets/ui/upgrades/armor.png"
