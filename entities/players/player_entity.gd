extends BaseEntity
class_name PlayerEntity

@export var jump_velocity = -800.0

# Player-specific properties
var player_id: int
var is_local_player: bool = false
var persistent_id: String = ""
var player_camera: Camera2D
var network_update_timer: Timer

# Connection quality monitoring
var network_samples: Array = []
var last_network_time: float = 0.0
var connection_quality: String = "GOOD"

# Network position buffering for smooth interpolation
var network_position_buffer: Array = []
var current_target_position: Vector2
var interpolation_speed: float = 30.0
var is_interpolating: bool = false
var use_local_optimization: bool = true

func _entity_ready():
	"""Player-specific initialization"""
	# Players always need network sync
	requires_network_sync = true
	
	# Set player-specific properties
	player_id = int(name)
	is_local_player = (player_id == multiplayer.get_unique_id())
	
	# Setup player-specific systems
	_setup_player_camera()
	_register_with_network_manager()
	update_player_label()
	
	# Initialize network position buffering
	current_target_position = position
	
	# Setup network timer (using NetworkManager flow, no RPC conflicts)
	_setup_network_timer()

func _setup_player_camera():
	"""Setup camera for local player only"""
	player_camera = get_node("PlayerCamera")
	if is_local_player:
		player_camera.enabled = true
		player_camera.make_current()
		print("Camera enabled for local player: ", player_id)
	else:
		player_camera.enabled = false

func _setup_network_timer():
	"""Setup network update timer for local players"""
	if is_local_player:
		network_update_timer = Timer.new()
		network_update_timer.wait_time = 0.008  # 120Hz for buttery smooth local multiplayer
		network_update_timer.timeout.connect(_send_network_update)
		add_child(network_update_timer)
		network_update_timer.start()

func _register_with_network_manager():
	"""Register with NetworkManager using player-specific method"""
	if network_manager:
		network_manager.register_player(self, player_id)

func _custom_physics_process(delta: float):
	"""Player-specific physics - input handling"""
	if is_local_player:
		_handle_player_input()
	# No interpolation for remote players - direct position updates only

func _handle_player_input():
	"""Handle keyboard/controller input for local player"""
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * max_speed
	else:
		velocity.x = move_toward(velocity.x, 0, max_speed * 3 * get_physics_process_delta_time())

func _handle_movement():
	"""Only local players use physics movement - remote players get direct position updates"""
	if is_local_player:
		move_and_slide()
	# Remote players don't call move_and_slide() - they get position updates via network

func _handle_network_interpolation(delta: float):
	"""Smooth interpolation for remote players' network positions"""
	if is_interpolating:
		var distance_to_target = position.distance_to(current_target_position)
		
		# Smooth interpolation towards target
		var new_position = position.lerp(current_target_position, interpolation_speed * delta)
		position = new_position
		
		# Stop interpolating when close enough
		if distance_to_target < 1.0:
			position = current_target_position
			is_interpolating = false
			# print("Player ", player_id, " finished interpolating to ", current_target_position)

func update_player_label():
	"""Update the player's display label"""
	var label = get_node("PlayerLabel")
	if label:
		var display_text = "Peer: " + str(player_id)
		if persistent_id != "":
			display_text += "\n" + persistent_id
		if is_local_player:
			display_text += "\n[YOU]"
		label.text = display_text

func set_persistent_id(new_persistent_id: String):
	"""Set the persistent player ID and update label"""
	persistent_id = new_persistent_id
	update_player_label()

func _send_network_update():
	"""Send position updates to other players (local player only)"""
	if not is_local_player or not is_inside_tree():
		return
	
	# Safety check: ensure multiplayer system is properly initialized
	if not multiplayer.multiplayer_peer or multiplayer.get_unique_id() == 0:
		return
		
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		# Debug: Track sending frequency and distance
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_since_last = current_time - last_network_time
		var distance_moved = position.distance_to(last_sent_position)
		
		
		# Use NetworkManager for ALL players to avoid RPC conflicts
		if network_manager and is_local_player:
			network_manager.report_local_movement(position)
		last_sent_position = position
		last_network_time = current_time

func receive_network_position(pos: Vector2, timestamp: float = 0.0):
	"""Called when receiving position update with latency measurement"""
	if not is_local_player:
		
		# For local multiplayer - direct position update, no interpolation whatsoever
		position = pos
		is_interpolating = false
		
		# Still track latency for connection quality monitoring
		var current_time = Time.get_ticks_msec() / 1000.0
		var latency = current_time - timestamp
		network_samples.append(latency)
		if network_samples.size() > 10:
			network_samples.pop_front()
		_evaluate_connection_quality()

func _evaluate_connection_quality():
	"""Evaluate if connection meets our standards"""
	if network_samples.size() < 5:
		return
	
	var avg_latency = 0.0
	var max_latency = 0.0
	
	for sample in network_samples:
		avg_latency += sample
		max_latency = max(max_latency, sample)
	
	avg_latency /= network_samples.size()
	
	# Strict quality standards
	if avg_latency > 0.050 or max_latency > 0.100:  # 50ms avg, 100ms max
		connection_quality = "POOR"
		if is_local_player:
			print("WARNING: Your connection is too poor for this server (avg: ", int(avg_latency * 1000), "ms, max: ", int(max_latency * 1000), "ms)")
			print("Required: <50ms average, <100ms maximum latency")
	elif avg_latency > 0.025 or max_latency > 0.075:  # 25ms avg, 75ms max
		connection_quality = "MARGINAL"
		if is_local_player:
			print("NOTICE: Connection quality is marginal (avg: ", int(avg_latency * 1000), "ms, max: ", int(max_latency * 1000), "ms)")
	else:
		connection_quality = "GOOD"

func get_connection_quality() -> String:
	"""Get current connection quality rating"""
	return connection_quality

# Removed sync_player_position RPC - using NetworkManager → GameManager flow instead
# This eliminates node path resolution issues while maintaining networking

func _entity_cleanup():
	"""Player-specific cleanup"""
	# Stop network updates immediately
	if network_update_timer and network_update_timer.is_valid():
		network_update_timer.stop()
		network_update_timer.queue_free()
	
	# Stop any interpolation
	is_interpolating = false
	
	# Unregister from NetworkManager when player leaves
	if network_manager:
		network_manager.unregister_player(player_id)
	
	print("Player ", player_id, " cleanup completed")
