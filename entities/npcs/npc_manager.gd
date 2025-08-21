extends Node
class_name NPCManager

# NPC Management System
# Handles spawning, despawning, and network synchronization of NPCs

var npcs = {}  # npc_id -> npc_node
var next_npc_id: int = 1

func spawn_npc(spawn_pos: Vector2, npc_type: String = "test_npc", config_data: Dictionary = {}) -> String:
	"""Server-authoritative NPC spawning"""
	if not multiplayer.is_server():
		print("Only server can spawn NPCs")
		return ""
	
	var npc_id = "npc_" + str(next_npc_id)
	next_npc_id += 1
	
	# Spawn locally first
	_spawn_npc_locally(npc_id, npc_type, spawn_pos, config_data)
	
	# Broadcast to all clients
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_npc_spawn", npc_id, npc_type, spawn_pos, config_data)
	
	print("Spawned NPC: ", npc_type, " with ID: ", npc_id, " at ", spawn_pos)
	return npc_id

func _spawn_npc_locally(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Spawn NPC locally on this client"""
	var npc_scene_path = "res://entities/npcs/" + npc_type + ".tscn"
	var npc_scene = load(npc_scene_path)
	
	if not npc_scene:
		print("ERROR: Could not load NPC scene: ", npc_scene_path)
		return
	
	# Instantiate NPC
	var npc_node = npc_scene.instantiate()
	npc_node.name = npc_id
	npc_node.position = pos
	
	# Add to scene
	get_tree().current_scene.add_child(npc_node, true)
	
	# Configure NPC
	npc_node.configure_npc(config)
	
	# Store reference
	npcs[npc_id] = npc_node
	
	print("Spawned NPC locally: ", npc_id, " at ", pos)

func despawn_npc(npc_id: String):
	"""Remove NPC (server authority)"""
	if not multiplayer.is_server():
		return
	
	_despawn_npc_locally(npc_id)
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_npc_despawn", npc_id)

func _despawn_npc_locally(npc_id: String):
	"""Remove NPC locally"""
	if npc_id in npcs:
		npcs[npc_id].queue_free()
		npcs.erase(npc_id)
		print("Despawned NPC: ", npc_id)

func despawn_all_npcs():
	"""Clear all NPCs from the world"""
	if not multiplayer.is_server():
		print("Only server can clear NPCs")
		return
	
	print("Clearing all ", npcs.size(), " NPCs...")
	for npc_id in npcs.keys():
		despawn_npc(npc_id)
	print("All NPCs cleared")

func get_npc_count() -> int:
	"""Get total number of active NPCs"""
	return npcs.size()

func get_all_npcs() -> Dictionary:
	"""Get reference to all active NPCs"""
	return npcs.duplicate()

@rpc("authority", "call_local", "reliable")
func sync_npc_spawn(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Synchronize NPC spawn to clients"""
	if not multiplayer.is_server():
		_spawn_npc_locally(npc_id, npc_type, pos, config)

@rpc("authority", "call_local", "reliable")
func sync_npc_despawn(npc_id: String):
	"""Synchronize NPC despawn to clients"""
	if not multiplayer.is_server():
		_despawn_npc_locally(npc_id)

# Debug Functions
func debug_spawn_test_npc():
	"""Debug: Spawn a test NPC at a fixed location"""
	if not multiplayer.is_server():
		print("Only server can spawn NPCs")
		return
	
	var spawn_pos = Vector2(200, 100)  # Fixed test position
	spawn_npc(spawn_pos, "test_npc", {"patrol_speed": 75})
	print("Debug: Spawned TestNPC at ", spawn_pos)

func debug_list_npcs():
	"""Debug: List all current NPCs"""
	print("=== NPC DEBUG INFO ===")
	print("Total NPCs: ", npcs.size())
	for npc_id in npcs:
		var npc = npcs[npc_id]
		print("  ", npc_id, ": ", npc.npc_type, " at ", npc.position)
	print("=====================")