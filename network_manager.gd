extends Node
class_name NetworkManager

# Rate limiting settings
@export var update_rate: float = 25.0
@export var movement_threshold: float = 1.0

# Smoothing settings  
@export var interpolation_speed: float = 15.0
@export var snap_distance: float = 100.0

# Player tracking
var tracked_players = {}
var game_manager: Node

# Rate limiting for local player
var last_update_time: float = 0.0
var last_sent_position: Vector2
var local_player_id: int
var pending_update: bool = false

func _ready():
	game_manager = get_tree().get_first_node_in_group("game_manager")
	local_player_id = multiplayer.get_unique_id()

func _process(delta: float) -> void:
	_handle_local_player_rate_limiting()
	_handle_remote_player_smoothing(delta)

func register_player(player: Node2D, player_id: int):
	"""Register a player for network management"""
	var player_data = {
		"entity": player,
		"player_id": player_id,
		"is_local": player_id == local_player_id,
		"target_position": player.position,
		"is_interpolating": false,
		"last_position": player.position
	}
	
	tracked_players[player_id] = player_data
	
	if player_data.is_local:
		last_sent_position = player.position
	
	print("NetworkManager: Registered player ", player_id)

func unregister_player(player_id: int):
	"""Unregister a player from network management"""
	if player_id in tracked_players:
		tracked_players.erase(player_id)
		print("NetworkManager: Unregistered player ", player_id)

func report_local_movement(new_position: Vector2):
	"""Called by local player when they move"""
	if local_player_id in tracked_players:
		var player_data = tracked_players[local_player_id]
		player_data.entity.position = new_position
		player_data.last_position = new_position
		
		# Check if we should send a network update
		var should_update = new_position.distance_to(last_sent_position) > movement_threshold
		
		if should_update and not pending_update:
			pending_update = true

func receive_remote_position(player_id: int, new_position: Vector2):
	"""Called when receiving position update for remote player"""
	if player_id in tracked_players and player_id != local_player_id:
		var player_data = tracked_players[player_id]
		var current_pos = player_data.entity.position
		var distance = current_pos.distance_to(new_position)
		
		# If too far, snap immediately
		if distance > snap_distance:
			player_data.entity.position = new_position
			player_data.target_position = new_position
			player_data.is_interpolating = false
		else:
			# Set up for smooth interpolation
			player_data.target_position = new_position
			player_data.is_interpolating = true

func _handle_local_player_rate_limiting():
	"""Handle rate limiting for local player position updates"""
	if not pending_update:
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last = current_time - last_update_time
	
	if time_since_last >= (1.0 / update_rate):
		if local_player_id in tracked_players:
			var player_data = tracked_players[local_player_id]
			var current_pos = player_data.last_position
			
			# Send the position update (only if connected)
			if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				game_manager.rpc("update_player_position", local_player_id, current_pos)
			
			last_update_time = current_time
			last_sent_position = current_pos
			pending_update = false

func _handle_remote_player_smoothing(delta: float):
	"""Handle smooth interpolation for all remote players"""
	for player_id in tracked_players:
		var player_data = tracked_players[player_id]
		
		# Skip local player and non-interpolating players
		if player_data.is_local or not player_data.is_interpolating:
			continue
			
		var entity = player_data.entity
		var target = player_data.target_position
		var current_pos = entity.position
		var distance_to_target = current_pos.distance_to(target)
		
		# Smooth interpolation
		var new_position = current_pos.lerp(target, interpolation_speed * delta)
		entity.position = new_position
		
		# Stop interpolating when close enough
		if distance_to_target < 0.5:
			entity.position = target
			player_data.is_interpolating = false

func force_sync_player(player_id: int):
	"""Force immediate position sync for a player (for teleports, etc.)"""
	if player_id == local_player_id and player_id in tracked_players:
		var player_data = tracked_players[player_id]
		if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			game_manager.rpc("update_player_position", player_id, player_data.entity.position)
		last_sent_position = player_data.entity.position
		last_update_time = Time.get_ticks_msec() / 1000.0

func get_network_stats():
	"""Get network statistics for debugging"""
	return {
		"tracked_players": tracked_players.size(),
		"local_player_id": local_player_id,
		"last_update_time": last_update_time,
		"pending_update": pending_update
	}
