extends Node
class_name NetworkManager


# Rate limiting settings
@export var update_rate: float = 60.0  # Match PlayerEntity rate
@export var movement_threshold: float = 0.05  # Match PlayerEntity threshold

# Smoothing settings  
@export var interpolation_speed: float = 30.0  # Much faster interpolation for zero-latency
@export var snap_distance: float = 1.0  # Snap almost immediately for zero-latency

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
	# Don't set local_player_id here - multiplayer may not be ready yet
	# It will be set when the first player registers

func _process(delta: float) -> void:
	_handle_local_player_rate_limiting()
	_handle_remote_player_smoothing(delta)

func register_player(player: Node2D, player_id: int):
	"""Register a player for network management"""
	# Set local_player_id when first player registers (ensures multiplayer is ready)
	if local_player_id == 0:
		local_player_id = multiplayer.get_unique_id()
	
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

func unregister_player(player_id: int):
	"""Unregister a player from network management"""
	if player_id in tracked_players:
		tracked_players.erase(player_id)

func report_local_movement(new_position: Vector2):
	"""Called by local player when they move"""
	if local_player_id in tracked_players:
		var player_data = tracked_players[local_player_id]
		# Don't overwrite local player's position - they already moved via move_and_slide()
		player_data.last_position = new_position
		
		# Check if we should send a network update
		var should_update = new_position.distance_to(last_sent_position) > movement_threshold
		
		if should_update and not pending_update:
			pending_update = true

func receive_remote_position(player_id: int, new_position: Vector2):
	"""Called when receiving position update for remote player"""
	if player_id in tracked_players:
		var player_data = tracked_players[player_id]
		
		# Skip updating local player's position (they handle their own movement)
		if player_id == local_player_id:
			return
		
		var current_pos = player_data.entity.position
		var distance = current_pos.distance_to(new_position)
		
		# For zero-latency testing, snap all positions immediately
		player_data.entity.position = new_position
		player_data.target_position = new_position
		player_data.is_interpolating = false

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
			
			# Send the position update (only if properly connected and initialized)
			if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.get_unique_id() != 0:
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
		
		# Stop interpolating when close enough (smaller threshold for smoother movement)
		if distance_to_target < 0.1:
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
