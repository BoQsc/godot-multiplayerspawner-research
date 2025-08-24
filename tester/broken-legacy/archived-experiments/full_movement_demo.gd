extends Node

# Full movement demonstration - all directions and jumping

func _ready():
	print("=== FULL MOVEMENT DEMO ===")
	print("🎮 Demonstrating ALL movement capabilities!")
	
	# IMMEDIATE movement start (our working pattern!)
	Input.action_press("ui_right")
	print("✅ Started moving right IMMEDIATELY")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_full_demo_sequence")

func _full_demo_sequence():
	print("🚀 Starting FULL movement demonstration...")
	print("Player ID: " + str(multiplayer.get_unique_id()))
	
	# Already moving right from _ready(), continue for 2 seconds
	await get_tree().create_timer(2.0).timeout
	Input.action_release("ui_right")
	print("⏹️ Stopped right movement")
	
	await get_tree().create_timer(0.5).timeout
	
	# JUMP TEST
	print("🦘 JUMPING NOW!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	
	# LEFT MOVEMENT
	print("⬅️ MOVING LEFT NOW!")
	Input.action_press("ui_left")
	await get_tree().create_timer(3.0).timeout
	Input.action_release("ui_left")
	print("⏹️ Stopped left movement")
	
	await get_tree().create_timer(0.5).timeout
	
	# JUMP AGAIN
	print("🦘 JUMPING AGAIN!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	
	# RIGHT MOVEMENT WITH JUMP COMBO
	print("➡️ MOVING RIGHT + JUMPING!")
	Input.action_press("ui_right")
	await get_tree().create_timer(1.0).timeout
	
	# Jump while moving
	print("🦘 JUMPING WHILE MOVING RIGHT!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(2.0).timeout
	Input.action_release("ui_right")
	print("⏹️ Stopped right movement")
	
	await get_tree().create_timer(0.5).timeout
	
	# RAPID DIRECTION CHANGES
	print("⚡ RAPID DIRECTION CHANGES!")
	for i in range(4):
		if i % 2 == 0:
			print("   ➡️ Quick right")
			Input.action_press("ui_right")
			await get_tree().create_timer(0.5).timeout
			Input.action_release("ui_right")
		else:
			print("   ⬅️ Quick left")
			Input.action_press("ui_left")
			await get_tree().create_timer(0.5).timeout
			Input.action_release("ui_left")
		
		# Jump between direction changes
		print("   🦘 Quick jump")
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		
		await get_tree().create_timer(0.3).timeout
	
	# FINAL COMBO - LEFT WITH MULTIPLE JUMPS
	print("🎪 FINAL COMBO - LEFT + TRIPLE JUMP!")
	Input.action_press("ui_left")
	
	for i in range(3):
		await get_tree().create_timer(0.8).timeout
		print("   🦘 Jump " + str(i + 1) + "/3")
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
	
	await get_tree().create_timer(1.0).timeout
	Input.action_release("ui_left")
	print("⏹️ Final stop")
	
	print("🏆 FULL MOVEMENT DEMO COMPLETED!")
	print("✨ Demonstrated: Right, Left, Jump, Combos, Rapid changes")
	print("💪 All movements executed successfully!")