extends Node

# Simple client - just move right and stop

func _ready():
	print("=== RIGHT AND STOP CLIENT ===")
	print("Moving right, then stopping")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_move_right_and_stop")

func _move_right_and_stop():
	print("🚀 Starting right movement...")
	
	# Move right
	print("➡️ Moving right NOW")
	Input.action_press("ui_right")
	
	# Count frames instead of using timer
	print("⏰ Counting 120 frames (2 seconds)...")
	for i in range(120):  # 2 seconds at 60fps
		if i % 30 == 0:  # Print every half second
			print("   Frame " + str(i) + "/120")
		await get_tree().process_frame
	
	print("⏰ Frame counting complete!")
	Input.action_release("ui_right")
	print("⏹️ STOPPED - released ui_right")
	
	print("🏁 Right and stop sequence COMPLETE!")
	print("✅ Successfully moved right and stopped")