extends Node
class_name NPCPersistence

# NPC Persistence System
# Handles saving and loading NPC states with world data

var npc_manager: NPCManager
var npc_data: NPCDataManager

func _ready():
	"""Initialize persistence system"""
	npc_data = NPCDataManager.new()

func set_npc_manager(manager: NPCManager):
	"""Set reference to NPC manager"""
	npc_manager = manager

func save_npcs(world_data: Resource):
	"""Save all current NPCs to world data (server only)"""
	if not multiplayer.is_server():
		return
	
	if not npc_manager:
		print("NPCPersistence: Cannot save NPCs - NPCManager not available")
		return
	
	var saved_count = 0
	
	# Clear existing NPC data
	npc_data.clear_all_npcs()
	
	# Save all current NPCs
	for npc_id in npc_manager.npcs:
		var npc = npc_manager.npcs[npc_id]
		if npc and npc.has_method("get_save_data"):
			var npc_save_data = npc.get_save_data()
			
			# Save NPC data
			npc_data.save_npc(
				npc_id,
				npc_save_data.get("npc_type", "test_npc"),
				npc.position,
				npc_save_data.get("health", 100.0),
				npc_save_data.get("max_health", 100.0),
				npc_save_data.get("ai_state", "idle"),
				npc_save_data.get("ai_timer", 0.0),
				npc_save_data.get("config_data", {})
			)
			saved_count += 1
	
	# Copy to world data
	_copy_to_world_data(world_data)
	
	print("NPCPersistence: Saved ", saved_count, " NPCs to persistent storage")

func load_npcs(world_data: Resource):
	"""Restore NPCs from world data on server startup"""
	if not multiplayer.is_server():
		return
	
	if not npc_manager:
		print("NPCPersistence: Cannot load NPCs - NPCManager not available")
		return
	
	# Copy from world data
	_copy_from_world_data(world_data)
	
	var npc_save_data = npc_data.get_all_npcs()
	if npc_save_data.is_empty():
		print("NPCPersistence: No saved NPCs to restore")
		return
	
	print("NPCPersistence: Loading ", npc_save_data.size(), " NPCs from save data...")
	
	var loaded_count = 0
	for npc_id in npc_save_data:
		var npc_data_dict = npc_save_data[npc_id]
		var npc_type = npc_data_dict.get("npc_type", "test_npc")
		var position = npc_data_dict.get("position", Vector2.ZERO)
		var config_data = npc_data_dict.get("config_data", {})
		
		# Handle specific NPC types
		if npc_type == "test_npc":
			config_data["patrol_speed"] = npc_data_dict.get("config_data", {}).get("patrol_speed", 50.0)
		
		# Spawn the NPC
		var spawned_npc_id = npc_manager.spawn_npc(position, npc_type, config_data)
		
		# Restore NPC state after spawning
		if spawned_npc_id != "" and spawned_npc_id in npc_manager.npcs:
			await get_tree().process_frame  # Wait for NPC to be fully initialized
			var npc_node = npc_manager.npcs[spawned_npc_id]
			if npc_node and npc_node.has_method("restore_save_data"):
				npc_node.restore_save_data(npc_data_dict)
			
			loaded_count += 1
			print("Restored NPC: ", npc_id, " (", npc_type, ") at ", position)
	
	print("NPCPersistence: Successfully loaded ", loaded_count, " NPCs")

func auto_save_npcs(world_data: Resource):
	"""Automatically save NPCs periodically"""
	if multiplayer.is_server():
		save_npcs(world_data)

func _copy_to_world_data(world_data: Resource):
	"""Copy NPC data to world data resource"""
	if world_data.has_method("set"):
		# Copy NPC data to world data
		world_data.npc_data = npc_data.npc_data.duplicate()
		world_data.next_npc_id = npc_data.next_npc_id

func _copy_from_world_data(world_data: Resource):
	"""Copy NPC data from world data resource"""
	if world_data.has_method("get"):
		# Copy NPC data from world data
		if world_data.has_method("get_all_npcs"):
			npc_data.npc_data = world_data.get_all_npcs()
		elif world_data.get("npc_data"):
			npc_data.npc_data = world_data.npc_data.duplicate()

# Debug Functions
func debug_save_npcs(world_data: Resource):
	"""Debug: Force save all NPCs now"""
	if not multiplayer.is_server():
		print("Only server can save NPCs")
		return
	
	save_npcs(world_data)
	print("Debug: NPCs saved to world data")

func debug_load_npcs(world_data: Resource):
	"""Debug: Force load NPCs from saved data"""
	if not multiplayer.is_server():
		print("Only server can load NPCs")
		return
	
	load_npcs(world_data)
	print("Debug: NPCs loaded from world data")