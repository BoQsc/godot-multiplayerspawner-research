extends Node
class_name PlayerManager

# Player Management System
# Handles player spawning, management, and persistence

var players = {}  # peer_id -> player_node
var player_persistent_ids = {}  # peer_id -> persistent_player_id

func register_player(peer_id: int, player_node: Node):
	"""Register a player with the manager"""
	players[peer_id] = player_node
	print("PlayerManager: Registered player ", peer_id)

func unregister_player(peer_id: int):
	"""Unregister a player from the manager"""
	if peer_id in players:
		players.erase(peer_id)
		print("PlayerManager: Unregistered player ", peer_id)
	
	if peer_id in player_persistent_ids:
		player_persistent_ids.erase(peer_id)

func get_player(peer_id: int) -> Node:
	"""Get player node by peer ID"""
	return players.get(peer_id, null)

func get_player_count() -> int:
	"""Get total number of active players"""
	return players.size()

func get_all_players() -> Dictionary:
	"""Get reference to all active players"""
	return players.duplicate()

func set_persistent_id(peer_id: int, persistent_id: String):
	"""Set persistent ID for a player"""
	player_persistent_ids[peer_id] = persistent_id

func get_persistent_id(peer_id: int) -> String:
	"""Get persistent ID for a player"""
	return player_persistent_ids.get(peer_id, "")

func save_player_positions(world_data: Resource):
	"""Save all player positions to world data"""
	if not multiplayer.is_server():
		return
	
	var saved_count = 0
	for peer_id in players.keys():
		var player = players[peer_id]
		var persistent_id = get_persistent_id(peer_id)
		
		if player and persistent_id != "":
			var current_pos = player.position
			
			# Save to world data
			if world_data.has_method("save_player"):
				world_data.save_player(persistent_id, current_pos)
				saved_count += 1
	
	if saved_count > 0:
		print("PlayerManager: Saved ", saved_count, " player positions")

func emergency_save_positions(world_data: Resource):
	"""Force save all player positions immediately"""
	if world_data:
		save_player_positions(world_data)
		print("PlayerManager: Emergency save completed")

# Debug Functions
func debug_list_players():
	"""Debug: List all current players"""
	print("=== PLAYER DEBUG INFO ===")
	print("Total Players: ", players.size())
	for peer_id in players:
		var player = players[peer_id]
		var persistent_id = get_persistent_id(peer_id)
		print("  Peer ", peer_id, " (", persistent_id, ") at ", player.position)
	print("=========================")