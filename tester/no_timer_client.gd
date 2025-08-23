extends Node

# No timer client - just immediate sequential commands

func _ready():
	print("=== NO TIMER CLIENT ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_do_movements")

func _do_movements():
	print("🚀 Starting movements...")
	
	# Move right immediately
	print("➡️ Moving right NOW")
	Input.action_press("ui_right")
	
	# Wait just a few frames, then switch to left
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("⬅️ Switching to left NOW")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	
	# Wait a few frames, then jump
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("🦘 Jumping NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	print("🏁 All movements executed!")