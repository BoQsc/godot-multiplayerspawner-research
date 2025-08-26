extends Node
class_name PickupPersistence

# Pickup Persistence System
# Handles saving and loading pickup states with world data

var pickup_manager: PickupManager

func set_pickup_manager(manager: PickupManager):
	"""Set reference to pickup manager"""
	pickup_manager = manager

func save_pickups(world_data: Resource):
	"""Save all current pickups to world data (server only)"""
	if not multiplayer.is_server():
		return
	
	if not pickup_manager:
		print("PickupPersistence: Cannot save pickups - PickupManager not available")
		return
	
	var saved_count = 0
	
	# Clear existing pickup data
	if world_data.has_method("get") and world_data.get("pickup_data"):
		world_data.pickup_data.clear()
	
	# Save all current pickups
	for item_id in pickup_manager.pickups:
		var pickup = pickup_manager.pickups[item_id]
		if pickup and pickup.has_method("get_save_data"):
			var pickup_save_data = pickup.get_save_data()
			
			# Save pickup data to WorldData
			if world_data.has_method("save_pickup"):
				world_data.save_pickup(
					item_id,
					pickup_save_data.get("item_type", "generic"),
					pickup.position,
					pickup_save_data.get("pickup_value", 1.0),
					pickup_save_data.get("respawn_time", 0.0),
					pickup_save_data.get("is_collected", false),
					pickup_save_data.get("respawn_timer", 0.0),
					pickup_save_data.get("config_data", {})
				)
			saved_count += 1
	
	print("PickupPersistence: Saved ", saved_count, " pickups to persistent storage")

func load_pickups(world_data: Resource):
	"""Restore pickups from world data on server startup"""
	if not multiplayer.is_server():
		return
	
	if not pickup_manager:
		print("PickupPersistence: Cannot load pickups - PickupManager not available")
		return
	
	var pickup_save_data = {}
	if world_data.has_method("get_all_pickups"):
		pickup_save_data = world_data.get_all_pickups()
	
	if pickup_save_data.is_empty():
		print("PickupPersistence: No saved pickups to restore")
		return
	
	print("PickupPersistence: Loading ", pickup_save_data.size(), " pickups from save data...")
	
	var loaded_count = 0
	for item_id in pickup_save_data:
		var pickup_data = pickup_save_data[item_id]
		var item_type = pickup_data.get("item_type", "generic")
		var position = pickup_data.get("position", Vector2.ZERO)
		var config_data = pickup_data.get("config_data", {})
		
		# Handle special pickup types
		if item_type == "health_potion":
			config_data["healing_amount"] = pickup_data.get("pickup_value", 25.0)
		else:
			config_data["pickup_value"] = pickup_data.get("pickup_value", 1.0)
		
		config_data["respawn_time"] = pickup_data.get("respawn_time", 0.0)
		
		# Spawn the pickup
		var spawned_item_id = pickup_manager.spawn_pickup(item_type, position, config_data)
		
		# Restore pickup state after spawning
		if spawned_item_id != "" and spawned_item_id in pickup_manager.pickups:
			await get_tree().process_frame  # Wait for pickup to be fully initialized
			var pickup_node = pickup_manager.pickups[spawned_item_id]
			if pickup_node and pickup_node.has_method("restore_save_data"):
				pickup_node.restore_save_data(pickup_data)
			
			loaded_count += 1
			print("Restored pickup: ", item_id, " (", item_type, ") at ", position)
	
	print("PickupPersistence: Successfully loaded ", loaded_count, " pickups")

func auto_save_pickups(world_data: Resource):
	"""Automatically save pickups periodically"""
	if multiplayer.is_server():
		save_pickups(world_data)