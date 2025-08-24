extends Node

# Immediate showcase - all actions without timers

func _ready():
	print("=== IMMEDIATE SHOWCASE ===")
	print("All actions immediately!")
	
	Input.action_press("ui_right")
	print("✅ Pressed ui_right immediately")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_immediate_actions")

func _immediate_actions():
	print("🚀 Starting immediate actions...")
	
	# Right movement already started in _ready()
	print("➡️ Moving right (already started)")
	
	# Let it move for a moment, then do more actions
	await get_tree().create_timer(2.0).timeout
	
	# Stop right, start left immediately
	print("⬅️ Switching to left movement")
	Input.action_release("ui_right")
	Input.action_press("ui_left")
	
	await get_tree().create_timer(2.0).timeout
	
	# Jump while moving left
	print("🦘 Jumping while moving left")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(2.0).timeout
	
	# Stop everything
	print("⏹️ Stopping all movement")
	Input.action_release("ui_left")
	
	print("🏁 Immediate showcase complete!")