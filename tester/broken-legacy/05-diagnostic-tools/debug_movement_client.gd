extends Node

# Debug movement client with detailed logging

func _ready():
	print("=== DEBUG MOVEMENT CLIENT ===")
	print("Moving RIGHT NOW!")
	
	# Press right movement immediately
	Input.action_press("ui_right")
	print("✅ Pressed ui_right immediately")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	# Start movement commands right away
	call_deferred("_debug_movement_sequence")

func _debug_movement_sequence():
	print("🚀 Starting debug movement sequence...")
	
	# Move right for 2 seconds (shorter for testing)
	print("➡️ Moving right NOW")
	Input.action_press("ui_right")
	
	print("⏰ Waiting 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	print("⏰ Timer completed! Stopping right movement...")
	
	Input.action_release("ui_right")
	print("⏹️ Released ui_right - should stop now")
	
	print("⏰ Waiting 0.5 seconds before jump...")
	await get_tree().create_timer(0.5).timeout
	print("⏰ Jump timer completed!")
	
	# Jump
	print("🦘 Jumping NOW")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	print("🦘 Jump command executed")
	
	print("⏰ Waiting 1 second after jump...")
	await get_tree().create_timer(1.0).timeout
	print("⏰ Post-jump timer completed!")
	
	# Move left
	print("⬅️ Moving left NOW")
	Input.action_press("ui_left")
	
	print("⏰ Waiting 2 seconds for left movement...")
	await get_tree().create_timer(2.0).timeout
	print("⏰ Left movement timer completed!")
	
	Input.action_release("ui_left")
	print("⏹️ Released ui_left - should stop now")
	
	print("🏁 Debug movement sequence COMPLETE!")
	print("🎉 All steps executed successfully!")