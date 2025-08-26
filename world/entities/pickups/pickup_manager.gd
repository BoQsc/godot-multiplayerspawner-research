extends Node
class_name PickupManager

# Pickup Management System  
# Handles spawning, despawning, and network synchronization of pickups

var pickups = {}  # item_id -> pickup_node
var next_pickup_id: int = 1

func spawn_pickup(item_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String:
	"""Server-authoritative pickup spawning"""
	if not multiplayer.is_server():
		print("Only server can spawn pickups")
		return ""
	
	var item_id = "pickup_" + str(next_pickup_id)
	next_pickup_id += 1
	
	# Spawn locally first
	_spawn_pickup_locally(item_id, item_type, spawn_pos, config_data)
	
	# Broadcast to all clients
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_pickup_spawn", item_id, item_type, spawn_pos, config_data)
	
	print("Spawned pickup: ", item_id, " (", item_type, ") at ", spawn_pos)
	return item_id

func _spawn_pickup_locally(item_id: String, item_type: String, pos: Vector2, config: Dictionary):
	"""Spawn pickup locally on this client"""
	var pickup_scene_path = "res://entities/pickups/" + item_type + ".tscn"
	var pickup_scene = load(pickup_scene_path)
	
	if not pickup_scene:
		print("ERROR: Could not load pickup scene: ", pickup_scene_path)
		return
	
	# Instantiate from scene
	var pickup_node = pickup_scene.instantiate()
	pickup_node.name = item_id
	pickup_node.position = pos
	
	# Add to scene
	get_tree().current_scene.add_child(pickup_node, true)
	
	# Configure pickup
	pickup_node.configure_pickup(config)
	
	# Verify position after adding to scene
	print("Spawned pickup locally: ", item_id, " at ", pos, " -> actual position: ", pickup_node.position)
	
	# Store reference
	pickups[item_id] = pickup_node

func despawn_pickup(item_id: String):
	"""Remove pickup (server authority)"""
	if not multiplayer.is_server():
		return
	
	_despawn_pickup_locally(item_id)
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_pickup_despawn", item_id)

func _despawn_pickup_locally(item_id: String):
	"""Remove pickup locally"""
	if item_id in pickups:
		pickups[item_id].queue_free()
		pickups.erase(item_id)
		print("Despawned pickup: ", item_id)

func despawn_all_pickups():
	"""Clear all pickups from the world"""
	if not multiplayer.is_server():
		print("Only server can clear pickups")
		return
	
	print("Clearing all ", pickups.size(), " pickups...")
	for item_id in pickups.keys():
		despawn_pickup(item_id)
	print("All pickups cleared")

func get_pickup_count() -> int:
	"""Get total number of active pickups"""
	return pickups.size()

func get_all_pickups() -> Dictionary:
	"""Get reference to all active pickups"""
	return pickups.duplicate()

@rpc("authority", "call_local", "reliable")
func sync_pickup_spawn(item_id: String, item_type: String, pos: Vector2, config: Dictionary):
	"""Synchronize pickup spawn to clients"""
	if not multiplayer.is_server():
		_spawn_pickup_locally(item_id, item_type, pos, config)

@rpc("authority", "call_local", "reliable")
func sync_pickup_despawn(item_id: String):
	"""Synchronize pickup despawn to clients"""
	if not multiplayer.is_server():
		_despawn_pickup_locally(item_id)

# Debug Functions
func debug_spawn_health_potion():
	"""Debug: Spawn a health potion at a fixed location"""
	if not multiplayer.is_server():
		print("Only server can spawn pickups")
		return
	
	var spawn_pos = Vector2(300, 100)  # Fixed test position
	spawn_pickup("health_potion", spawn_pos, {"healing_amount": 25})
	print("Debug: Spawned HealthPotion at ", spawn_pos)

func debug_spawn_star_item():
	"""Debug: Spawn a star item at a fixed location"""
	if not multiplayer.is_server():
		print("Only server can spawn pickups")
		return
	
	var spawn_pos = Vector2(400, 100)  # Fixed test position
	spawn_pickup("star_item", spawn_pos, {"pickup_value": 100})
	print("Debug: Spawned StarItem at ", spawn_pos)

func debug_spawn_gem_blue():
	"""Debug: Spawn a blue gem at a fixed location"""
	if not multiplayer.is_server():
		print("Only server can spawn pickups")
		return
	
	var spawn_pos = Vector2(500, 100)  # Fixed test position  
	spawn_pickup("gem_blue", spawn_pos, {"pickup_value": 50})
	print("Debug: Spawned GemBlue at ", spawn_pos)

func debug_list_pickups():
	"""Debug: List all current pickups"""
	print("=== PICKUP DEBUG INFO ===")
	print("Total Pickups: ", pickups.size())
	for item_id in pickups:
		var pickup = pickups[item_id]
		var status = "Available"
		if pickup.has_method("is_collected") and pickup.is_collected:
			status = "Collected"
		print("- ", item_id, " (", pickup.item_type, ") at ", pickup.position, " - ", status)
	print("=========================")