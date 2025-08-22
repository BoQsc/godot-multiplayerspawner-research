extends Node

# Autoconnect client script for main scene

func _ready():
	print("=== AUTO CLIENT TEST ===")
	print("Starting main scene and auto-connecting as client...")
	
	# Wait for scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the GameManager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		print("✅ Found GameManager")
		
		# Check if it has the join method
		if game_manager.has_method("_join_as_client"):
			print("🔌 Auto-connecting to server...")
			game_manager._join_as_client("127.0.0.1", 4443)
		elif game_manager.has_method("start_client"):
			print("🔌 Using start_client method...")
			game_manager.start_client("127.0.0.1", 4443)
		else:
			print("⚠️ No client connection method found")
			# Try to call the UI method directly
			var ui_container = get_node_or_null("/root/Main/CanvasLayer/UserInterface/MarginContainer/VBoxContainer/ConnectionContainer")
			if ui_container:
				print("🔌 Found connection UI - attempting connection...")
				# Look for IP and port inputs
				var ip_input = ui_container.get_node_or_null("CustomServerContainer/CustomJoinContainer/VBoxContainer/IpInput")
				var port_input = ui_container.get_node_or_null("CustomServerContainer/CustomJoinContainer/VBoxContainer/PortInput")
				var connect_btn = ui_container.get_node_or_null("CustomServerContainer/CustomJoinContainer/VBoxContainer/ConnectButton")
				
				if ip_input and port_input and connect_btn:
					ip_input.text = "127.0.0.1"
					port_input.text = "4443"
					print("📝 Set connection details")
					await get_tree().process_frame
					connect_btn.pressed.emit()
					print("🔌 Triggered connection button")
	else:
		print("❌ Could not find GameManager")
	
	print("⏳ Test client should be connecting now...")
	print("Check your player list for a new connection!")
	
	# Monitor for successful spawn
	await _monitor_spawn_status()
	
	# Stay alive for 3 minutes after spawn
	await get_tree().create_timer(180.0).timeout
	print("⏰ Auto client test completed")

func _monitor_spawn_status():
	"""Monitor if we get spawned properly"""
	print("🔍 Monitoring for spawn...")
	
	for i in range(30):  # Check for 30 seconds
		await get_tree().create_timer(1.0).timeout
		
		# Check if we're in the spawn container
		var spawn_container = get_tree().get_first_node_in_group("spawn_container")
		if spawn_container:
			var my_id = str(multiplayer.get_unique_id())
			var my_player = spawn_container.get_node_or_null(my_id)
			if my_player:
				print("🎉 SPAWNED! Found myself as: " + my_player.name + " at " + str(my_player.position))
				return
		
		if i % 10 == 0:  # Every 10 seconds
			print("⏳ Still checking for spawn... (" + str(i) + "s)")
	
	print("⚠️ No spawn detected after 30 seconds")