extends Node

# Non-headless test client that can actually move

func _ready():
	print("=== WINDOWED TEST CLIENT ===")
	print("Running with visible window for proper input handling")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_movement_demo")

func _start_movement_demo():
	await get_tree().create_timer(8.0).timeout
	
	print("🎮 Starting movement demonstration...")
	print("This client should be able to move using input!")
	
	var my_peer_id = multiplayer.get_unique_id()
	print("Player ID: " + str(my_peer_id))
	
	# Simulate input sequence
	await _simulate_input_sequence()

func _simulate_input_sequence():
	"""Simulate a sequence of input commands"""
	print("🚀 Starting input simulation sequence...")
	
	# Move right for 2 seconds
	print("➡️ Simulating RIGHT movement...")
	for i in range(120):  # 2 seconds at 60 FPS
		Input.action_press("ui_right")
		await get_tree().process_frame
	Input.action_release("ui_right")
	print("   Released RIGHT")
	
	await get_tree().create_timer(1.0).timeout
	
	# Jump
	print("🦘 Simulating JUMP...")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	print("   Jump executed")
	
	await get_tree().create_timer(1.0).timeout
	
	# Move left for 2 seconds  
	print("⬅️ Simulating LEFT movement...")
	for i in range(120):  # 2 seconds at 60 FPS
		Input.action_press("ui_left")
		await get_tree().process_frame
	Input.action_release("ui_left")
	print("   Released LEFT")
	
	await get_tree().create_timer(1.0).timeout
	
	# Another jump
	print("🦘 Simulating second JUMP...")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	print("   Second jump executed")
	
	print("🏁 Movement demo completed!")
	print("You should have seen the client move right, jump, move left, and jump again.")
	
	# Keep running for manual control
	print("💡 Client will stay running - you can now manually test controls!")
	print("   Use arrow keys and spacebar/enter to move manually.")