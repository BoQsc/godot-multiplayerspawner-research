extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -800.0
@export var gravity = 2000.0

var player_id: int
var is_local_player: bool = false
var game_manager: Node
var network_manager: NetworkManager
var persistent_id: String = ""
var player_camera: Camera2D
var last_sent_position: Vector2
var network_update_timer: Timer

# Connection quality monitoring
var network_samples: Array = []
var last_network_time: float = 0.0
var connection_quality: String = "GOOD"

func _ready():
	player_id = int(name)
	is_local_player = (player_id == multiplayer.get_unique_id())
	
	# Cache references to managers
	game_manager = get_tree().get_first_node_in_group("game_manager")
	network_manager = get_tree().get_first_node_in_group("network_manager")
	
	if not game_manager:
		game_manager = get_parent().get_parent().get_node("GameManager")
	
	# Setup camera for local player only
	player_camera = get_node("PlayerCamera")
	if is_local_player:
		player_camera.enabled = true
		player_camera.make_current()
		print("Camera enabled for local player: ", player_id)
	else:
		player_camera.enabled = false
	
	# Register with NetworkManager (all players, not just local)
	if network_manager:
		network_manager.register_player(self, player_id)
	
	# Initialize network variables
	last_sent_position = position
	
	# Setup network timer for local players
	if is_local_player:
		network_update_timer = Timer.new()
		network_update_timer.wait_time = 0.016  # ~60Hz
		network_update_timer.timeout.connect(_send_network_update)
		add_child(network_update_timer)
		network_update_timer.start()
	
	# Update the player label
	update_player_label()

func update_player_label():
	var label = get_node("PlayerLabel")
	if label:
		var display_text = "Peer: " + str(player_id)
		if persistent_id != "":
			display_text += "\n" + persistent_id
		if is_local_player:
			display_text += "\n[YOU]"
		label.text = display_text

func set_persistent_id(new_persistent_id: String):
	persistent_id = new_persistent_id
	update_player_label()

func _physics_process(delta: float) -> void:
	# Only handle input for local player - NO NETWORK OPERATIONS HERE
	if is_local_player:
		# Add gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Handle jump
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity
		
		# Handle horizontal movement
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * 3 * delta)
		
		# Move and slide - ONLY LOCAL MOVEMENT, NO NETWORK
		move_and_slide()

func _send_network_update():
	"""Called by timer - separate from physics for smooth movement"""
	if not is_local_player:
		return
		
	if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var distance_moved = position.distance_to(last_sent_position)
		if distance_moved > 0.05:  # Very small threshold for high precision
			var current_time = Time.get_ticks_msec() / 1000.0
			game_manager.rpc("update_player_position", player_id, position, current_time)
			last_sent_position = position
			last_network_time = current_time

func receive_network_position(pos: Vector2, timestamp: float):
	"""Called when receiving position update with latency measurement"""
	if not is_local_player:
		position = pos
		
		# Measure network quality
		var current_time = Time.get_ticks_msec() / 1000.0
		var latency = current_time - timestamp
		
		# Track latency samples (keep last 10)
		network_samples.append(latency)
		if network_samples.size() > 10:
			network_samples.pop_front()
		
		# Evaluate connection quality
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
	return connection_quality

func _exit_tree():
	# Unregister from NetworkManager when player leaves
	if network_manager:
		network_manager.unregister_player(player_id)
