extends Node

# Test client that moves IMMEDIATELY without waiting

func _ready():
	print("=== IMMEDIATE MOVE CLIENT ===")
	print("Moving RIGHT NOW!")
	
	# Press right movement immediately
	Input.action_press("ui_right")
	print("✅ Pressed ui_right immediately")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	
	# Start movement commands right away
	call_deferred("_immediate_movement")

func _immediate_movement():
	print("🚀 Starting immediate movement sequence...")
	
	# Move right for 3 seconds
	print("➡️ Moving right NOW")
	Input.action_press("ui_right")
	
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_right")
	print("⏹️ Stopped right")
	
	# Jump
	print("🦘 Jumping NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	
	# Move left
	print("⬅️ Moving left NOW")
	Input.action_press("ui_left")
	
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_left")
	print("⏹️ Stopped left")
	
	print("🏁 Immediate movement test done!")