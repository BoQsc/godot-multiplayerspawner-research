extends Node

# Force client to be local player with debug output

func _ready():
	print("=== FORCED LOCAL CLIENT ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_force_local_player")

func _force_local_player():
	await get_tree().create_timer(8.0).timeout  # Wait for full connection and spawn
	
	print("🔧 Forcing local player status...")
	
	# Find my player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found in players list")
		return
	
	var my_player = players[my_peer_id]
	print("✅ Found my player: " + str(my_player.name))
	print("   Current is_local_player: " + str(my_player.is_local_player))
	print("   Player ID: " + str(my_player.player_id))
	print("   Multiplayer ID: " + str(my_peer_id))
	
	# Force local player status
	my_player.is_local_player = true
	print("🔧 Forced is_local_player = true")
	
	# Try to directly modify velocity to simulate right movement
	print("🚀 Testing direct velocity control...")
	my_player.velocity.x = 200  # Move right
	print("   Set velocity.x = 200")
	
	# Wait and reset
	await get_tree().create_timer(2.0).timeout
	my_player.velocity.x = 0
	print("   Reset velocity.x = 0")
	
	# Test jump
	print("🦘 Testing jump...")
	my_player.velocity.y = -400  # Jump up
	print("   Set velocity.y = -400")
	
	print("🏁 Force test completed!")
	print("   Final position: " + str(my_player.position))
	print("   Final velocity: " + str(my_player.velocity))