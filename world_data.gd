@tool
extends Resource
class_name WorldData

@export var world_name: String = "MyWorld"
@export var created_at: String = ""
@export var last_modified: String = ""
@export var world_size: Vector2i = Vector2i(100, 100)

# Dictionary to store tile data: Vector2i -> TileInfo
@export var tile_data: Dictionary = {}

# Dictionary to store player data: String (persistent_player_id) -> PlayerData
@export var player_data: Dictionary = {}
# Dictionary to map client IDs to persistent player IDs: String -> String
@export var client_to_player_mapping: Dictionary = {}
# Dictionary to map network peer IDs to client IDs (for current session): int -> String
@export var peer_to_client_mapping: Dictionary = {}
# Counter for generating unique player IDs
@export var next_player_id: int = 1

# Dictionary to store NPC data: String (npc_id) -> NPCData
@export var npc_data: Dictionary = {}
# Counter for generating unique NPC IDs
@export var next_npc_id: int = 1

# Dictionary to store pickup data: String (item_id) -> PickupData
@export var pickup_data: Dictionary = {}
# Counter for generating unique pickup IDs
@export var next_pickup_id: int = 1

# Nested class to represent individual tile information
class TileInfo:
	var source_id: int
	var atlas_coords: Vector2i
	var alternative_tile: int
	
	func _init(p_source_id: int = -1, p_atlas_coords: Vector2i = Vector2i(-1, -1), p_alternative_tile: int = 0):
		source_id = p_source_id
		atlas_coords = p_atlas_coords
		alternative_tile = p_alternative_tile
	
	func to_dict() -> Dictionary:
		return {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		}
	
	func from_dict(data: Dictionary):
		source_id = data.get("source_id", -1)
		atlas_coords = data.get("atlas_coords", Vector2i(-1, -1))
		alternative_tile = data.get("alternative_tile", 0)

# Nested class to represent individual player information
class PlayerData:
	var player_id: String
	var position: Vector2
	var health: float
	var max_health: float
	var level: int
	var experience: int
	var last_seen: String
	var inventory: Array[Dictionary] # Array of item dictionaries
	
	func _init(p_player_id: String = "", p_position: Vector2 = Vector2.ZERO):
		player_id = p_player_id
		position = p_position
		health = 100.0
		max_health = 100.0
		level = 1
		experience = 0
		last_seen = Time.get_datetime_string_from_system()
		inventory = []
	
	func to_dict() -> Dictionary:
		return {
			"player_id": player_id,
			"position": position,
			"health": health,
			"max_health": max_health,
			"level": level,
			"experience": experience,
			"last_seen": last_seen,
			"inventory": inventory
		}
	
	func from_dict(data: Dictionary):
		player_id = data.get("player_id", "")
		position = data.get("position", Vector2.ZERO)
		health = data.get("health", 100.0)
		max_health = data.get("max_health", 100.0)
		level = data.get("level", 1)
		experience = data.get("experience", 0)
		last_seen = data.get("last_seen", Time.get_datetime_string_from_system())
		inventory = data.get("inventory", [])

# Nested class to represent individual NPC information
class NPCData:
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

# Nested class to represent individual pickup information
class PickupData:
	var item_id: String
	var item_type: String
	var position: Vector2
	var pickup_value: float
	var respawn_time: float
	var is_collected: bool
	var respawn_timer: float
	var config_data: Dictionary  # Custom pickup configuration
	var last_updated: String
	
	func _init(p_item_id: String = "", p_item_type: String = "", p_position: Vector2 = Vector2.ZERO):
		item_id = p_item_id
		item_type = p_item_type
		position = p_position
		pickup_value = 1.0
		respawn_time = 0.0
		is_collected = false
		respawn_timer = 0.0
		config_data = {}
		last_updated = Time.get_datetime_string_from_system()
	
	func to_dict() -> Dictionary:
		return {
			"item_id": item_id,
			"item_type": item_type,
			"position": position,
			"pickup_value": pickup_value,
			"respawn_time": respawn_time,
			"is_collected": is_collected,
			"respawn_timer": respawn_timer,
			"config_data": config_data,
			"last_updated": last_updated
		}
	
	func from_dict(data: Dictionary):
		item_id = data.get("item_id", "")
		item_type = data.get("item_type", "")
		position = data.get("position", Vector2.ZERO)
		pickup_value = data.get("pickup_value", 1.0)
		respawn_time = data.get("respawn_time", 0.0)
		is_collected = data.get("is_collected", false)
		respawn_timer = data.get("respawn_timer", 0.0)
		config_data = data.get("config_data", {})
		last_updated = data.get("last_updated", Time.get_datetime_string_from_system())

func _init():
	created_at = Time.get_datetime_string_from_system()
	last_modified = created_at

func set_tile(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int = 0):
	if source_id == -1:
		# Remove tile
		tile_data.erase(coords)
	else:
		# Set tile
		var tile_info = TileInfo.new(source_id, atlas_coords, alternative_tile)
		tile_data[coords] = tile_info.to_dict()
	
	last_modified = Time.get_datetime_string_from_system()

func get_tile(coords: Vector2i) -> Dictionary:
	if coords in tile_data:
		return tile_data[coords]
	else:
		return {
			"source_id": -1,
			"atlas_coords": Vector2i(-1, -1),
			"alternative_tile": -1
		}

func has_tile(coords: Vector2i) -> bool:
	return coords in tile_data

func get_all_tiles() -> Dictionary:
	return tile_data.duplicate()

func clear_all_tiles():
	tile_data.clear()
	last_modified = Time.get_datetime_string_from_system()

func get_tile_count() -> int:
	return tile_data.size()

# Player ID management functions
func register_client(client_id: String, peer_id: int, chosen_player_num: int = -1, chosen_player_id: String = "") -> String:
	print("=== REGISTER_CLIENT CALLED ===")
	print("Client ID: ", client_id)
	print("Peer ID: ", peer_id)
	print("Chosen player num: ", chosen_player_num)
	print("Chosen player id: ", chosen_player_id)
	# Validate input parameters
	if client_id == "" or peer_id <= 0:
		print("ERROR: Invalid client registration - client_id: '", client_id, "', peer_id: ", peer_id)
		return ""
	
	# Check for existing peer conflicts
	if peer_id in peer_to_client_mapping:
		var existing_client = peer_to_client_mapping[peer_id]
		if existing_client != client_id:
			print("WARNING: Peer ID ", peer_id, " was previously mapped to different client: ", existing_client, " -> ", client_id)
	
	# Map this peer to the client ID for this session
	peer_to_client_mapping[peer_id] = client_id
	
	# Check if this client already has a persistent player ID
	print("DEBUG: Checking if client ", client_id, " exists in mapping...")
	print("DEBUG: Available client mappings: ", client_to_player_mapping.keys())
	if client_id in client_to_player_mapping:
		var existing_persistent_id = client_to_player_mapping[client_id]
		print("DEBUG: Found client mapping: ", client_id, " -> ", existing_persistent_id)
		
		# Validate that the persistent player ID exists and is consistent
		if existing_persistent_id in player_data:
			print("DEBUG: Player data found for ", existing_persistent_id)
			print("Registered returning client: ", client_id, " (peer ", peer_id, ") -> persistent ID ", existing_persistent_id, " (EXISTING)")
			last_modified = Time.get_datetime_string_from_system()
			return existing_persistent_id
		else:
			print("DEBUG: Player data NOT found for ", existing_persistent_id)
			print("DEBUG: Available player data keys: ", player_data.keys())
			print("🚨 CRITICAL: Client mapping exists but player data missing!")
			print("🔧 PRESERVING mapping and creating missing player data instead of deleting mapping")
			# FIXED: Don't delete the mapping! Instead, create the missing player data
			# This preserves the client-to-player relationship and prevents spawn bugs
			player_data[existing_persistent_id] = {
				"player_id": existing_persistent_id,
				"position": Vector2(100, 100),  # Safe default position  
				"health": 100.0,
				"max_health": 100.0,
				"level": 1,
				"experience": 0,
				"inventory": [],
				"last_seen": Time.get_datetime_string_from_system()
			}
			print("✅ Created missing player data for ", existing_persistent_id, " at default position")
			print("Registered returning client: ", client_id, " (peer ", peer_id, ") -> persistent ID ", existing_persistent_id, " (RECOVERED)")
			last_modified = Time.get_datetime_string_from_system()
			return existing_persistent_id
	else:
		print("DEBUG: Client ", client_id, " NOT found in client mappings")
	
	# Create new persistent player ID for this client
	var persistent_id: String
	
	if chosen_player_id != "":
		# Use the chosen player identifier (string or numeric)
		persistent_id = "player_" + chosen_player_id
		print("Using chosen player identifier: ", chosen_player_id)
	elif chosen_player_num > 0:
		# Use the chosen player number directly (backward compatibility)
		persistent_id = "player_" + str(chosen_player_num)
		print("Using chosen player number: ", chosen_player_num)
	else:
		# Use UUID-based player ID for collision-free identification
		# Extract UUID from client_id (remove "client_" or "server_" prefix)
		var uuid_part = client_id.replace("client_", "").replace("server_", "")
		persistent_id = "player_" + uuid_part
		print("Using UUID-based player ID: ", persistent_id)
	client_to_player_mapping[client_id] = persistent_id
	print("DEBUG: Set client mapping: ", client_id, " -> ", persistent_id)
	print("DEBUG: Mapping now contains: ", client_to_player_mapping.has(client_id))
	print("DEBUG: Mapping size before: ", client_to_player_mapping.size())
	print("DEBUG: All mappings after set: ", client_to_player_mapping.keys())
	
	# Create player record immediately if it doesn't exist
	if not has_player(persistent_id):
		# Use default spawn position for new players
		print("DEBUG: Creating new player record for ", persistent_id)
		save_player(persistent_id, Vector2(100, 100))
		print("DEBUG: Player ", persistent_id, " created, exists: ", has_player(persistent_id))
		print("Registered new client: ", client_id, " (peer ", peer_id, ") -> persistent ID ", persistent_id, " (NEW)")
	else:
		print("DEBUG: Player ", persistent_id, " already exists in data")
		var existing_data = get_player(persistent_id)
		print("DEBUG: Existing position: ", existing_data["position"])
		print("Registered returning client: ", client_id, " (peer ", peer_id, ") -> persistent ID ", persistent_id, " (EXISTING)")
	
	last_modified = Time.get_datetime_string_from_system()
	print("DEBUG: Final client_to_player_mapping size: ", client_to_player_mapping.size())
	print("DEBUG: Final mapping contains our client: ", client_to_player_mapping.has(client_id))
	return persistent_id

func get_persistent_player_id(peer_id: int) -> String:
	var client_id = peer_to_client_mapping.get(peer_id, "")
	if client_id != "":
		return client_to_player_mapping.get(client_id, "")
	return ""

func get_client_id(peer_id: int) -> String:
	return peer_to_client_mapping.get(peer_id, "")

func unregister_peer(peer_id: int):
	if peer_id in peer_to_client_mapping:
		var client_id = peer_to_client_mapping[peer_id]
		print("Unregistered peer ", peer_id, " (client ID: ", client_id, ")")
		peer_to_client_mapping.erase(peer_id)
		# Note: We keep the client_to_player_mapping for persistence
		last_modified = Time.get_datetime_string_from_system()
		
		# Clean up old peer mappings periodically to prevent pollution
		cleanup_old_peer_mappings()

func cleanup_old_peer_mappings():
	# Remove excessive peer mappings for the same client to prevent dictionary pollution
	var client_peer_counts = {}
	
	# Count peers per client
	for peer_id in peer_to_client_mapping:
		var client_id = peer_to_client_mapping[peer_id]
		if client_id not in client_peer_counts:
			client_peer_counts[client_id] = []
		client_peer_counts[client_id].append(peer_id)
	
	# Keep only the most recent 3 peer IDs per client
	var cleaned_count = 0
	for client_id in client_peer_counts:
		var peer_list = client_peer_counts[client_id]
		if peer_list.size() > 3:
			# Sort by peer ID (newer IDs are generally larger)
			peer_list.sort()
			# Remove the oldest ones
			for i in range(peer_list.size() - 3):
				peer_to_client_mapping.erase(peer_list[i])
				cleaned_count += 1
	
	if cleaned_count > 0:
		print("WorldData: Cleaned up ", cleaned_count, " old peer mappings")
		last_modified = Time.get_datetime_string_from_system()

# Player data management functions
func save_player(player_id: String, position: Vector2, health: float = 100.0, max_health: float = 100.0, level: int = 1, experience: int = 0, inventory: Array[Dictionary] = []):
	var player_info = PlayerData.new(player_id, position)
	player_info.health = health
	player_info.max_health = max_health
	player_info.level = level
	player_info.experience = experience
	player_info.inventory = inventory
	player_info.last_seen = Time.get_datetime_string_from_system()
	
	player_data[player_id] = player_info.to_dict()
	last_modified = Time.get_datetime_string_from_system()

func get_player(player_id: String) -> Dictionary:
	if player_id in player_data:
		return player_data[player_id]
	else:
		# Return default player data
		return {
			"player_id": player_id,
			"position": Vector2(100, 100),  # Default spawn position
			"health": 100.0,
			"max_health": 100.0,
			"level": 1,
			"experience": 0,
			"last_seen": Time.get_datetime_string_from_system(),
			"inventory": []
		}

func has_player(player_id: String) -> bool:
	return player_id in player_data

func remove_player(player_id: String):
	player_data.erase(player_id)
	last_modified = Time.get_datetime_string_from_system()

func get_all_players() -> Dictionary:
	return player_data.duplicate()

func get_player_count() -> int:
	return player_data.size()

func update_player_position(player_id: String, position: Vector2):
	if player_id in player_data:
		player_data[player_id]["position"] = position
		player_data[player_id]["last_seen"] = Time.get_datetime_string_from_system()
		last_modified = Time.get_datetime_string_from_system()
	else:
		# Create new player if doesn't exist
		save_player(player_id, position)

func update_player_health(player_id: String, health: float):
	if player_id in player_data:
		player_data[player_id]["health"] = health
		player_data[player_id]["last_seen"] = Time.get_datetime_string_from_system()
		last_modified = Time.get_datetime_string_from_system()

func add_player_experience(player_id: String, experience_points: int):
	if player_id in player_data:
		player_data[player_id]["experience"] += experience_points
		player_data[player_id]["last_seen"] = Time.get_datetime_string_from_system()
		last_modified = Time.get_datetime_string_from_system()
		
		# Check for level up (simple formula: level = sqrt(experience / 100))
		var new_level = int(sqrt(player_data[player_id]["experience"] / 100.0)) + 1
		if new_level > player_data[player_id]["level"]:
			player_data[player_id]["level"] = new_level
			print("Player ", player_id, " leveled up to level ", new_level, "!")

func get_world_bounds() -> Rect2i:
	if tile_data.is_empty():
		return Rect2i()
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for coords in tile_data.keys():
		if coords is Vector2i:
			min_x = min(min_x, coords.x)
			min_y = min(min_y, coords.y)
			max_x = max(max_x, coords.x)
			max_y = max(max_y, coords.y)
	
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

# NPC data management functions
func save_npc(npc_id: String, npc_type: String, position: Vector2, health: float = 100.0, max_health: float = 100.0, ai_state: String = "idle", ai_timer: float = 0.0, config_data: Dictionary = {}):
	var npc_info = NPCData.new(npc_id, npc_type, position)
	npc_info.health = health
	npc_info.max_health = max_health
	npc_info.ai_state = ai_state
	npc_info.ai_timer = ai_timer
	npc_info.config_data = config_data
	npc_info.last_updated = Time.get_datetime_string_from_system()
	
	npc_data[npc_id] = npc_info.to_dict()
	last_modified = Time.get_datetime_string_from_system()

func get_npc(npc_id: String) -> Dictionary:
	if npc_id in npc_data:
		return npc_data[npc_id]
	else:
		# Return empty dictionary if NPC not found
		return {}

func remove_npc(npc_id: String):
	if npc_id in npc_data:
		npc_data.erase(npc_id)
		last_modified = Time.get_datetime_string_from_system()

func get_all_npcs() -> Dictionary:
	return npc_data.duplicate()

func get_npc_count() -> int:
	return npc_data.size()

func update_npc_position(npc_id: String, position: Vector2):
	if npc_id in npc_data:
		npc_data[npc_id]["position"] = position
		npc_data[npc_id]["last_updated"] = Time.get_datetime_string_from_system()
		last_modified = Time.get_datetime_string_from_system()

# Pickup data management functions
func save_pickup(item_id: String, item_type: String, position: Vector2, pickup_value: float = 1.0, respawn_time: float = 0.0, is_collected: bool = false, respawn_timer: float = 0.0, config_data: Dictionary = {}):
	var pickup_info = PickupData.new(item_id, item_type, position)
	pickup_info.pickup_value = pickup_value
	pickup_info.respawn_time = respawn_time
	pickup_info.is_collected = is_collected
	pickup_info.respawn_timer = respawn_timer
	pickup_info.config_data = config_data
	pickup_info.last_updated = Time.get_datetime_string_from_system()
	
	pickup_data[item_id] = pickup_info.to_dict()
	last_modified = Time.get_datetime_string_from_system()

func get_pickup(item_id: String) -> Dictionary:
	if item_id in pickup_data:
		return pickup_data[item_id]
	else:
		# Return empty dictionary if pickup not found
		return {}

func remove_pickup(item_id: String):
	if item_id in pickup_data:
		pickup_data.erase(item_id)
		last_modified = Time.get_datetime_string_from_system()

func get_all_pickups() -> Dictionary:
	return pickup_data.duplicate()

func get_pickup_count() -> int:
	return pickup_data.size()

func update_pickup_state(item_id: String, is_collected: bool, respawn_timer: float = 0.0):
	if item_id in pickup_data:
		pickup_data[item_id]["is_collected"] = is_collected
		pickup_data[item_id]["respawn_timer"] = respawn_timer
		pickup_data[item_id]["last_updated"] = Time.get_datetime_string_from_system()
		last_modified = Time.get_datetime_string_from_system()

# Debug function to print world info
func print_world_info():
	print("=== World Data Info ===")
	print("Name: ", world_name)
	print("Created: ", created_at)
	print("Last Modified: ", last_modified)
	print("Tile Count: ", get_tile_count())
	print("Player Count: ", get_player_count())
	print("NPC Count: ", get_npc_count())
	print("Pickup Count: ", get_pickup_count())
	print("Bounds: ", get_world_bounds())
	
	if get_player_count() > 0:
		print("--- Player Data ---")
		for player_id in player_data.keys():
			var player = player_data[player_id]
			print("Player ", player_id, ": Pos(", player["position"], ") Lvl:", player["level"], " HP:", player["health"], "/", player["max_health"], " XP:", player["experience"])
	
	if get_npc_count() > 0:
		print("--- NPC Data ---")
		for npc_id in npc_data.keys():
			var npc = npc_data[npc_id]
			print("NPC ", npc_id, ": Type(", npc["npc_type"], ") Pos(", npc["position"], ") HP:", npc["health"], "/", npc["max_health"], " State:", npc["ai_state"])
	
	if get_pickup_count() > 0:
		print("--- Pickup Data ---")
		for item_id in pickup_data.keys():
			var pickup = pickup_data[item_id]
			var status = "Available" if not pickup["is_collected"] else "Collected"
			print("Pickup ", item_id, ": Type(", pickup["item_type"], ") Pos(", pickup["position"], ") Value:", pickup["pickup_value"], " Status:", status)
	
	print("=======================")
