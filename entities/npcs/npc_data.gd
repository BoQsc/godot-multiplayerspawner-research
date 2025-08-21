extends Resource
class_name NPCDataManager

# NPC Data Management System
# Handles NPC data structures and persistence helpers

# NPC data storage
@export var npc_data: Dictionary = {}
@export var next_npc_id: int = 1

# Nested class to represent individual NPC information
class NPCInfo:
	var npc_id: String
	var npc_type: String
	var position: Vector2
	var health: float
	var max_health: float
	var ai_state: String
	var ai_timer: float
	var config_data: Dictionary  # Custom NPC configuration
	var last_updated: String
	
	func _init(p_npc_id: String = "", p_npc_type: String = "", p_position: Vector2 = Vector2.ZERO):
		npc_id = p_npc_id
		npc_type = p_npc_type
		position = p_position
		health = 100.0
		max_health = 100.0
		ai_state = "idle"
		ai_timer = 0.0
		config_data = {}
		last_updated = Time.get_datetime_string_from_system()
	
	func to_dict() -> Dictionary:
		return {
			"npc_id": npc_id,
			"npc_type": npc_type,
			"position": position,
			"health": health,
			"max_health": max_health,
			"ai_state": ai_state,
			"ai_timer": ai_timer,
			"config_data": config_data,
			"last_updated": last_updated
		}
	
	func from_dict(data: Dictionary):
		npc_id = data.get("npc_id", "")
		npc_type = data.get("npc_type", "")
		position = data.get("position", Vector2.ZERO)
		health = data.get("health", 100.0)
		max_health = data.get("max_health", 100.0)
		ai_state = data.get("ai_state", "idle")
		ai_timer = data.get("ai_timer", 0.0)
		config_data = data.get("config_data", {})
		last_updated = data.get("last_updated", Time.get_datetime_string_from_system())

# NPC data management functions
func save_npc(npc_id: String, npc_type: String, position: Vector2, health: float = 100.0, max_health: float = 100.0, ai_state: String = "idle", ai_timer: float = 0.0, config_data: Dictionary = {}):
	var npc_info = NPCInfo.new(npc_id, npc_type, position)
	npc_info.health = health
	npc_info.max_health = max_health
	npc_info.ai_state = ai_state
	npc_info.ai_timer = ai_timer
	npc_info.config_data = config_data
	npc_info.last_updated = Time.get_datetime_string_from_system()
	
	npc_data[npc_id] = npc_info.to_dict()

func get_npc(npc_id: String) -> Dictionary:
	if npc_id in npc_data:
		return npc_data[npc_id]
	else:
		# Return empty dictionary if NPC not found
		return {}

func remove_npc(npc_id: String):
	if npc_id in npc_data:
		npc_data.erase(npc_id)

func get_all_npcs() -> Dictionary:
	return npc_data.duplicate()

func get_npc_count() -> int:
	return npc_data.size()

func clear_all_npcs():
	npc_data.clear()

func update_npc_position(npc_id: String, position: Vector2):
	if npc_id in npc_data:
		npc_data[npc_id]["position"] = position
		npc_data[npc_id]["last_updated"] = Time.get_datetime_string_from_system()

func print_npc_info():
	"""Debug function to print NPC data"""
	if get_npc_count() > 0:
		print("--- NPC Data ---")
		for npc_id in npc_data.keys():
			var npc = npc_data[npc_id]
			print("NPC ", npc_id, ": Type(", npc["npc_type"], ") Pos(", npc["position"], ") HP:", npc["health"], "/", npc["max_health"], " State:", npc["ai_state"])
	else:
		print("--- No NPC Data ---")