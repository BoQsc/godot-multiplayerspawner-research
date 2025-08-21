extends BaseEntity
class_name TestNPC

@export var npc_type: String = "test_npc"
@export var patrol_speed: float = 50.0

# NPC-specific properties  
var npc_id: String
var ai_state: String = "idle"
var ai_timer: float = 0.0

func _entity_ready():
	"""NPC-specific initialization"""
	npc_id = name
	
	# NPCs can optionally sync over network (for this test, we'll enable it)
	requires_network_sync = true
	
	# Set movement speed from our patrol_speed
	max_speed = patrol_speed
	
	print("TestNPC initialized: ", npc_id)

func configure_npc(config_data: Dictionary):
	"""Configure NPC with spawn data"""
	if config_data.has("patrol_speed"):
		patrol_speed = config_data["patrol_speed"]
		max_speed = patrol_speed
		print("TestNPC configured with patrol_speed: ", patrol_speed)

func _custom_physics_process(delta: float):
	"""NPC-specific physics - simple AI"""
	if multiplayer.is_server():
		_update_ai(delta)

func _update_ai(delta: float):
	"""Simple AI: move back and forth"""
	ai_timer += delta
	
	match ai_state:
		"idle":
			velocity.x = 0
			if ai_timer > 2.0:  # Wait 2 seconds
				ai_state = "moving_right"
				ai_timer = 0.0
		
		"moving_right":
			velocity.x = patrol_speed
			if ai_timer > 3.0:  # Move right for 3 seconds
				ai_state = "moving_left"
				ai_timer = 0.0
		
		"moving_left":
			velocity.x = -patrol_speed
			if ai_timer > 3.0:  # Move left for 3 seconds
				ai_state = "idle"
				ai_timer = 0.0

func _entity_cleanup():
	"""NPC cleanup"""
	print("TestNPC cleanup: ", npc_id)

func get_save_data() -> Dictionary:
	"""Return data needed to save this NPC's state"""
	return {
		"npc_type": npc_type,
		"health": current_health,
		"max_health": max_health,
		"ai_state": ai_state,
		"ai_timer": ai_timer,
		"config_data": {
			"patrol_speed": patrol_speed
		}
	}

func restore_save_data(data: Dictionary):
	"""Restore NPC state from saved data"""
	if data.has("health"):
		current_health = data["health"]
	if data.has("max_health"):
		max_health = data["max_health"]
	if data.has("ai_state"):
		ai_state = data["ai_state"]
	if data.has("ai_timer"):
		ai_timer = data["ai_timer"]
	
	print("TestNPC ", npc_id, " restored state: HP=", current_health, ", AI=", ai_state)