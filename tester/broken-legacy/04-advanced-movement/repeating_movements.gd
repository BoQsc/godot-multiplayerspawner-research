extends Node

# Repeating movements - each action repeated for visibility

func _ready():
	print("=== REPEATING MOVEMENTS ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_repeating_sequence")

func _start_repeating_sequence():
	print("🚀 Starting repeating movement sequence...")
	
	# Move right for many frames
	print("➡️ Moving right for 180 frames...")
	Input.action_press("ui_right")
	for i in range(180):  # 3 seconds at 60fps
		await get_tree().process_frame
	
	print("⬅️ Switching to left for 180 frames...")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	for i in range(180):  # 3 seconds at 60fps
		await get_tree().process_frame
	
	print("🦘 Jumping 5 times...")
	Input.action_release("ui_left")
	for jump_count in range(5):
		print("   Jump " + str(jump_count + 1) + "/5")
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		# Wait between jumps
		for i in range(60):  # 1 second between jumps
			await get_tree().process_frame
	
	print("➡️ Final right movement for 120 frames...")
	Input.action_press("ui_right")
	for i in range(120):  # 2 seconds
		await get_tree().process_frame
	
	print("⏹️ Stopping all movement")
	Input.action_release("ui_right")
	
	print("🏁 Repeating movement sequence COMPLETE!")
	print("✨ Right -> Left -> 5 Jumps -> Right -> Stop")