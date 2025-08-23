extends Node

# Simple walker that executes movement commands immediately

func _ready():
	print("=== SIMPLE WALKER ===")
	print("🚀 Starting movement sequence immediately...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Start walking immediately
	call_deferred("_walk_sequence")

func _walk_sequence():
	print("📝 Command: Move right for 3 seconds")
	Input.action_press("ui_right")
	await get_tree().create_timer(3.0).timeout
	
	print("📝 Command: Stop")
	Input.action_release("ui_right")
	await get_tree().create_timer(0.5).timeout
	
	print("📝 Command: Jump")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.0).timeout
	
	print("📝 Command: Move left for 3 seconds")
	Input.action_press("ui_left")
	await get_tree().create_timer(3.0).timeout
	
	print("📝 Command: Stop")
	Input.action_release("ui_left")
	await get_tree().create_timer(0.5).timeout
	
	print("📝 Command: Jump")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.0).timeout
	
	print("📝 Command: Move right + jump combo")
	Input.action_press("ui_right")
	await get_tree().create_timer(1.0).timeout
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(2.0).timeout
	
	print("📝 Command: Final stop")
	Input.action_release("ui_right")
	
	print("🏁 Walking sequence completed!")
	print("💡 Client ready for manual commands")

# Manual command functions that can be called externally
func move_right():
	print("📝 Manual command: Move right")
	Input.action_release("ui_left")
	Input.action_press("ui_right")

func move_left():
	print("📝 Manual command: Move left")
	Input.action_release("ui_right")
	Input.action_press("ui_left")

func jump():
	print("📝 Manual command: Jump")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")

func stop():
	print("📝 Manual command: Stop all movement")
	Input.action_release("ui_right")
	Input.action_release("ui_left")