extends CharacterBody2D
class_name BaseEntity

# Core entity properties
@export var max_speed: float = 300.0
@export var gravity: float = 2000.0
@export var entity_id: String = ""

# Manager references - shared by all entities
var game_manager: Node
var network_manager: NetworkManager

# Network properties
var last_sent_position: Vector2
var requires_network_sync: bool = false

func _ready():
	entity_id = name
	_setup_managers()
	_setup_networking()
	_entity_ready()

func _setup_managers():
	"""Get references to core managers - same pattern as current entity_scene"""
	game_manager = get_tree().get_first_node_in_group("game_manager")
	network_manager = get_tree().get_first_node_in_group("network_manager")
	
	if not game_manager:
		game_manager = get_parent().get_parent().get_node("GameManager")

func _setup_networking():
	"""Initialize network-related properties"""
	last_sent_position = position
	
	# Register with network manager if needed (NPCs can opt-out)
	if requires_network_sync and network_manager:
		network_manager.register_entity(self, entity_id)

func _entity_ready():
	"""Override in derived classes for custom initialization"""
	pass

func _physics_process(delta: float):
	"""Standard physics processing - gravity + custom logic + movement"""
	_apply_gravity(delta)
	_custom_physics_process(delta)
	move_and_slide()

func _apply_gravity(delta: float):
	"""Apply gravity to entities that aren't on the floor"""
	if not is_on_floor():
		velocity.y += gravity * delta

func _custom_physics_process(delta: float):
	"""Override in derived classes for entity-specific physics"""
	pass

func receive_network_position(pos: Vector2, timestamp: float = 0.0):
	"""Called when receiving position update from network"""
	position = pos

func _exit_tree():
	"""Clean up network registration when entity is removed"""
	if network_manager and requires_network_sync:
		network_manager.unregister_entity(entity_id)
	
	_entity_cleanup()

func _entity_cleanup():
	"""Override in derived classes for custom cleanup"""
	pass