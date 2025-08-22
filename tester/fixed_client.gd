extends Node

# Fixed client that puts GameManager at the correct path and does interesting behaviors

var game_manager = null
var my_peer_id = 0
var behaviors = ["exploring", "dancing", "following", "idle"]
var current_behavior = "exploring"

func _ready():
	print("=== FIXED CLIENT TEST ===")
	print("Setting up proper node structure...")
	
	# Load and instantiate the main scene
	var main_scene = load("res://main_scene.tscn").instantiate()
	
	# Add it directly to root instead of as child (deferred to avoid busy parent error)
	get_tree().root.add_child.call_deferred(main_scene)
	
	# Remove ourselves since we're just a setup script (also deferred)
	call_deferred("queue_free")
	
	print("✅ Main scene loaded with correct structure")
	print("GameManager should now be at /root/Main/GameManager")
	print("⏳ Client should connect and spawn properly now!")
	
	# Start behaviors after connection
	call_deferred("_start_behaviors")

func _start_behaviors():
	"""Start interesting behaviors after connection"""
	await get_tree().create_timer(10.0).timeout  # Wait for connection and spawn
	
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		my_peer_id = multiplayer.get_unique_id()
		print("🤖 Starting behaviors for peer " + str(my_peer_id))
		_behavior_loop()
	else:
		print("❌ No GameManager found")

func _behavior_loop():
	"""Main behavior loop"""
	while true:
		match current_behavior:
			"exploring":
				await _explore()
			"dancing": 
				await _dance()
			"following":
				await _follow_player()
			"idle":
				await _idle()
		
		# Switch behavior
		current_behavior = behaviors[randi() % behaviors.size()]
		await get_tree().create_timer(randf_range(10.0, 20.0)).timeout

func _explore():
	"""Move around randomly"""
	print("🗺️ Exploring...")
	var my_player = _get_my_player()
	if not my_player:
		return
	
	for i in range(3):
		var target = Vector2(randf_range(-400, 400), randf_range(-400, 400))
		print("🚶 Moving to " + str(target))
		my_player.position = target
		await get_tree().create_timer(3.0).timeout

func _dance():
	"""Do a little dance"""
	print("💃 Dancing!")
	var my_player = _get_my_player()
	if not my_player:
		return
	
	var center = my_player.position
	for i in range(8):
		var angle = (i * PI * 2.0) / 8.0
		var dance_pos = center + Vector2(cos(angle), sin(angle)) * 40
		my_player.position = dance_pos
		await get_tree().create_timer(1.0).timeout

func _follow_player():
	"""Try to follow other players"""
	print("👥 Looking for players to follow...")
	var players = game_manager.get("players")
	if players:
		for peer_id in players.keys():
			if peer_id != my_peer_id:
				var other_player = players[peer_id]
				print("🏃 Following player " + str(peer_id))
				for j in range(5):
					if other_player and is_instance_valid(other_player):
						var my_player = _get_my_player()
						if my_player:
							my_player.position = other_player.position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
					await get_tree().create_timer(2.0).timeout
				return
	print("👻 No other players to follow")

func _idle():
	"""Just stand around"""
	print("😴 Taking a break...")
	await get_tree().create_timer(5.0).timeout

func _get_my_player():
	"""Get my player node"""
	if not game_manager:
		return null
	var players = game_manager.get("players")
	if players and my_peer_id in players:
		return players[my_peer_id]
	return null