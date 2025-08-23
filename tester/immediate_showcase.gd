extends Node

# IMMEDIATE movement showcase - NO DELAYS, MOVE RIGHT NOW!

func _ready():
	print("=== IMMEDIATE MOVEMENT SHOWCASE ===")
	print("🚀 MOVING RIGHT NOW!")
	
	# MOVE IMMEDIATELY - this is what works!
	Input.action_press("ui_right")
	print("✅ Moving right IMMEDIATELY")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Continue movement sequence immediately
	call_deferred("_immediate_showcase")

func _immediate_showcase():
	print("🎭 Continuing immediate movement showcase...")
	
	# Already moving right from _ready(), continue for 3 seconds
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_right")
	print("⏹️ Stopped right")
	
	# IMMEDIATE jump
	print("🦘 JUMPING NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	# IMMEDIATE left movement
	print("⬅️ MOVING LEFT NOW")
	Input.action_press("ui_left")
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_left")
	print("⏹️ Stopped left")
	
	# IMMEDIATE jump again
	print("🦘 JUMPING AGAIN NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	# IMMEDIATE right movement
	print("➡️ MOVING RIGHT AGAIN NOW")
	Input.action_press("ui_right")
	await get_tree().create_timer(2.0).timeout
	
	# IMMEDIATE jump while moving
	print("🦘 JUMPING WHILE MOVING NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.0).timeout
	
	# Final stop
	Input.action_release("ui_right")
	print("🏁 SHOWCASE COMPLETE!")
	print("💪 All movements executed IMMEDIATELY!")