extends Label
class_name PositionDisplay

# Position display UI that shows player coordinates in real-time

var game_manager: Node
var user_identity: Node

func _ready():
	# Set up the label appearance
	name = "PositionDisplay"
	text = "Position: (0, 0)"
	
	# Style the label
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	
	# Position in top-right corner
	anchors_preset = Control.PRESET_TOP_RIGHT
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -200
	offset_right = -10
	offset_top = 10
	offset_bottom = 30
	
	# Find GameManager and UserIdentity
	await get_tree().process_frame  # Wait for scene to be ready
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	user_identity = get_tree().get_first_node_in_group("user_identity")
	
	if game_manager:
		print("PositionDisplay: Connected to GameManager")
	else:
		print("PositionDisplay: ❌ Could not find GameManager")
	
	if user_identity:
		print("PositionDisplay: Connected to UserIdentity")
	else:
		print("PositionDisplay: ❌ Could not find UserIdentity")

func _process(_delta):
	update_position_display()

func update_position_display():
	if not game_manager or not user_identity:
		text = "Position: Not Connected"
		return
	
	# Get current player position
	var player_id = user_identity.get_client_id()
	var current_position = Vector2.ZERO
	var player_found = false
	
	# Try to get position from active player
	if game_manager.players.has(1):  # Server is always peer ID 1
		var player = game_manager.players[1]
		if player and is_instance_valid(player):
			current_position = player.global_position
			player_found = true
	
	# Fallback: Get from world data
	if not player_found and game_manager.world_manager and game_manager.world_manager.world_data:
		var world_data = game_manager.world_manager.world_data
		var client_mapping = world_data.client_to_player_mapping.get(player_id, "")
		if client_mapping != "":
			var player_data = world_data.player_data.get(client_mapping, {})
			if player_data.has("position"):
				current_position = player_data.position
				player_found = true
	
	# Update display
	if player_found:
		text = "Position: (%.1f, %.1f)" % [current_position.x, current_position.y]
		
		# Add color coding based on distance from spawn
		var spawn_point = Vector2(100, 100)
		var distance = current_position.distance_to(spawn_point)
		
		if distance > 5000:
			add_theme_color_override("font_color", Color.RED)  # Danger zone
			text += " 🚨 LOST"
		elif distance > 1000:
			add_theme_color_override("font_color", Color.ORANGE)  # Far
			text += " ⚠️ FAR"
		elif distance > 500:
			add_theme_color_override("font_color", Color.YELLOW)  # Medium
		else:
			add_theme_color_override("font_color", Color.WHITE)  # Normal
			
		# Add distance info
		text += "\nDistance: %.0f units" % distance
		
		# Add bounds check warning
		if abs(current_position.x) > 5000 or abs(current_position.y) > 5000:
			text += "\n🚨 EXCEEDS 5000 BOUNDS!"
			add_theme_color_override("font_color", Color.RED)
	else:
		text = "Position: Player Not Found"
		add_theme_color_override("font_color", Color.GRAY)