extends Node2D
class_name PickupEntity

@export var item_type: String = "generic"
@export var pickup_value: float = 1.0
@export var auto_pickup_radius: float = 30.0
@export var respawn_time: float = 0.0  # 0 = no respawn, >0 = respawn after X seconds

# Manager references (like BaseEntity)
var game_manager: Node
var network_manager: NetworkManager

# Pickup-specific properties
var item_id: String
var is_collected: bool = false
var respawn_timer: float = 0.0
var pickup_area: Area2D
var sprite: Sprite2D

func _ready():
	"""Pickup initialization"""
	item_id = name
	
	# Setup manager references
	_setup_managers()
	
	# Setup collision detection for pickups
	_setup_pickup_area()
	_setup_sprite()
	
	print("PickupEntity initialized: ", item_id, " (", item_type, ") at position: ", position)
	
	# Monitor position changes every few seconds
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(_debug_position_check)
	add_child(timer)
	timer.start()

func _setup_managers():
	"""Get references to core managers"""
	game_manager = get_tree().get_first_node_in_group("game_manager")
	network_manager = get_tree().get_first_node_in_group("network_manager")
	
	if not game_manager:
		game_manager = get_parent().get_parent().get_node("GameManager")

func _setup_pickup_area():
	"""Setup Area2D for pickup detection"""
	pickup_area = get_node_or_null("PickupArea")
	if not pickup_area:
		# Create if it doesn't exist (fallback for programmatic creation)
		pickup_area = Area2D.new()
		pickup_area.name = "PickupArea"
		add_child(pickup_area)
		
		# Create collision shape
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = auto_pickup_radius
		collision_shape.shape = circle_shape
		pickup_area.add_child(collision_shape)
	else:
		# Update existing collision shape radius
		var collision_shape = pickup_area.get_node_or_null("PickupCollision")
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = auto_pickup_radius
	
	# Connect pickup detection
	if not pickup_area.body_entered.is_connected(_on_pickup_area_entered):
		pickup_area.body_entered.connect(_on_pickup_area_entered)

func _setup_sprite():
	"""Setup sprite for the pickup"""
	sprite = get_node_or_null("Sprite2D")
	if not sprite:
		# Create default sprite if none exists (fallback for programmatic creation)
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		sprite.z_index = 10
	
	# Items should render above ground tiles
	if sprite:
		sprite.z_index = 10

func configure_pickup(config_data: Dictionary):
	"""Configure pickup with spawn data"""
	if config_data.has("pickup_value"):
		pickup_value = config_data["pickup_value"]
	if config_data.has("respawn_time"):
		respawn_time = config_data["respawn_time"]
	if config_data.has("item_type"):
		item_type = config_data["item_type"]
	
	print("PickupEntity configured: ", item_type, " value=", pickup_value)

func _process(delta: float):
	"""Pickup processing - handle respawning"""
	# Debug: Check for position changes
	if abs(position.x) > 1000 or abs(position.y) > 1000:
		print("WARNING: Pickup ", item_id, " has extreme position: ", position)
	
	# Only process respawning if multiplayer is active and we're the server
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			_update_respawn(delta)
	elif not multiplayer.multiplayer_peer:
		# Single player mode - always process
		_update_respawn(delta)

func _update_respawn(delta: float):
	"""Handle respawn logic (server only)"""
	if is_collected and respawn_time > 0.0:
		respawn_timer += delta
		if respawn_timer >= respawn_time:
			_respawn_item()

func _on_pickup_area_entered(body):
	"""Handle pickup area entry"""
	print("DEBUG: Pickup area entered by ", body.name, " - pickup position: ", position)
	
	# Only handle pickup if we're the server or in single player
	if multiplayer.multiplayer_peer:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			if not multiplayer.is_server():
				return
		else:
			return  # Multiplayer exists but not connected, skip
	
	if is_collected:
		return
	
	# Check if it's a player
	if body is PlayerEntity:
		var player = body as PlayerEntity
		print("DEBUG: Attempting pickup with player at ", player.position)
		_attempt_pickup(player)

func _attempt_pickup(player: PlayerEntity):
	"""Attempt to pick up the item (server only)"""
	if is_collected:
		return false
	
	# Call virtual method for pickup logic
	if _can_be_picked_up(player):
		_perform_pickup(player)
		return true
	
	return false

func _can_be_picked_up(player: PlayerEntity) -> bool:
	"""Override in derived classes for pickup conditions"""
	return true

func _perform_pickup(player: PlayerEntity):
	"""Perform the actual pickup (server only)"""
	is_collected = true
	respawn_timer = 0.0
	
	# Apply item effect
	_apply_pickup_effect(player)
	
	# Hide the item
	_set_item_visibility(false)
	
	# Sync to clients (only if multiplayer is active and connected)
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_pickup_collected", player.player_id)
	
	# Remove from world if no respawn
	if respawn_time <= 0.0:
		_remove_from_world()
	
	print("Item picked up: ", item_id, " by player ", player.player_id)

func _apply_pickup_effect(player: PlayerEntity):
	"""Override in derived classes for specific effects"""
	print("Generic pickup effect applied to ", player.name)

func _set_item_visibility(visible: bool):
	"""Set item visibility and collision"""
	if sprite:
		sprite.visible = visible
	if pickup_area:
		pickup_area.set_deferred("monitoring", visible)

func _respawn_item():
	"""Respawn the item"""
	is_collected = false
	respawn_timer = 0.0
	_set_item_visibility(true)
	
	# Sync to clients (only if multiplayer is active and connected)
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc("sync_pickup_respawned")
	
	print("Item respawned: ", item_id)

func _remove_from_world():
	"""Remove item from game world"""
	if game_manager and game_manager.has_method("despawn_pickup"):
		game_manager.despawn_pickup(item_id)
	else:
		queue_free()

@rpc("authority", "call_local", "reliable")
func sync_pickup_collected(player_id: int):
	"""Synchronize pickup collection to clients"""
	var is_client = false
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		is_client = not multiplayer.is_server()
	
	if is_client:
		is_collected = true
		_set_item_visibility(false)

@rpc("authority", "call_local", "reliable")
func sync_pickup_respawned():
	"""Synchronize pickup respawn to clients"""
	var is_client = false
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		is_client = not multiplayer.is_server()
	
	if is_client:
		is_collected = false
		_set_item_visibility(true)

func get_save_data() -> Dictionary:
	"""Return data needed to save this pickup's state"""
	return {
		"item_type": item_type,
		"pickup_value": pickup_value,
		"respawn_time": respawn_time,
		"is_collected": is_collected,
		"respawn_timer": respawn_timer,
		"config_data": {
			"auto_pickup_radius": auto_pickup_radius
		}
	}

func restore_save_data(data: Dictionary):
	"""Restore pickup state from saved data"""
	if data.has("pickup_value"):
		pickup_value = data["pickup_value"]
	if data.has("respawn_time"):
		respawn_time = data["respawn_time"]
	if data.has("is_collected"):
		is_collected = data["is_collected"]
		_set_item_visibility(not is_collected)
	if data.has("respawn_timer"):
		respawn_timer = data["respawn_timer"]
	
	print("PickupEntity ", item_id, " restored state: collected=", is_collected, ", value=", pickup_value)

func _debug_position_check():
	"""Debug: Check if position changed"""
	if abs(position.x) > 1000 or abs(position.y) > 1000:
		print("ALERT: Pickup ", item_id, " drifted to extreme position: ", position)

func _exit_tree():
	"""Pickup cleanup"""
	print("PickupEntity cleanup: ", item_id)
