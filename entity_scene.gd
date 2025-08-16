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
var last_network_send: float = 0.0
var last_sent_position: Vector2

# Interpolation for remote players
var target_position: Vector2
var is_interpolating: bool = false
var interpolation_speed: float = 30.0

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
	target_position = position
	
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
	if is_local_player:
		# Local player - handle input and movement
		_handle_local_movement(delta)
	else:
		# Remote player - handle interpolation
		_handle_remote_interpolation(delta)

func _handle_local_movement(delta: float):
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
	
	# Move and slide
	move_and_slide()
	
	# Direct RPC with rate limiting
	if game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var current_time = Time.get_ticks_msec() / 1000.0
		var distance_moved = position.distance_to(last_sent_position)
		
		# Send update if movement detected (high frequency for local testing)
		if distance_moved > 0.1:  # Only movement threshold, no rate limiting for local testing
			game_manager.rpc("update_player_position", player_id, position)
			last_sent_position = position

func _handle_remote_interpolation(delta: float):
	# Smooth interpolation for remote players
	if is_interpolating:
		var distance_to_target = position.distance_to(target_position)
		
		if distance_to_target > 100.0:
			# Snap if too far (teleport/major desync)
			position = target_position
			is_interpolating = false
		elif distance_to_target > 0.1:
			# Fast interpolation for local testing
			position = position.lerp(target_position, interpolation_speed * delta)
		else:
			# Snap to target immediately
			position = target_position
			is_interpolating = false

func set_network_position(new_position: Vector2):
	"""Called when receiving network position update"""
	if not is_local_player:
		target_position = new_position
		is_interpolating = true

func _exit_tree():
	# Unregister from NetworkManager when player leaves
	if network_manager:
		network_manager.unregister_player(player_id)
