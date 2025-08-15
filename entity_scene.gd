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
	
	# Register with NetworkManager
	if network_manager and is_local_player:
		network_manager.register_player(self, player_id)
	
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
	# Only handle input for local player
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
		
		# Move and slide
		move_and_slide()
		
		# Report movement to NetworkManager
		if network_manager:
			network_manager.report_local_movement(position)
		elif game_manager and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			# Fallback: direct RPC (only if connected)
			game_manager.rpc("update_player_position", player_id, position)

func _exit_tree():
	# Unregister from NetworkManager when player leaves
	if network_manager and is_local_player:
		network_manager.unregister_player(player_id)
