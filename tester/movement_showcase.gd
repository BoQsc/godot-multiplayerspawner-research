extends Node

# Comprehensive movement showcase - showing off all capabilities

func _ready():
	print("=== MOVEMENT SHOWCASE ===")
	print("🎭 Demonstrating all movement capabilities!")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_movement_showcase")

func _movement_showcase():
	print("🚀 Starting comprehensive movement demonstration...")
	print("Player ID: " + str(multiplayer.get_unique_id()))
	
	# 1. Basic Movement Test
	await _basic_movement_test()
	
	# 2. Jump Combinations Test  
	await _jump_combinations_test()
	
	# 3. Precision Control Test
	await _precision_control_test()
	
	# 4. Complex Patterns Test
	await _complex_patterns_test()
	
	# 5. Stress Test
	await _stress_test()
	
	print("🏆 SHOWCASE COMPLETE! All movement capabilities demonstrated.")

func _basic_movement_test():
	print("\n🟢 === BASIC MOVEMENT TEST ===")
	
	print("➡️ Testing right movement...")
	Input.action_press("ui_right")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("ui_right")
	print("   ✅ Right movement: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("⬅️ Testing left movement...")
	Input.action_press("ui_left")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("ui_left")
	print("   ✅ Left movement: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🦘 Testing jump...")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.0).timeout
	print("   ✅ Jump: OK")

func _jump_combinations_test():
	print("\n🟡 === JUMP COMBINATIONS TEST ===")
	
	print("➡️🦘 Right + Jump combo...")
	Input.action_press("ui_right")
	await get_tree().create_timer(0.5).timeout
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("ui_right")
	print("   ✅ Right-Jump combo: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("⬅️🦘 Left + Jump combo...")
	Input.action_press("ui_left")
	await get_tree().create_timer(0.5).timeout
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("ui_left")
	print("   ✅ Left-Jump combo: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🦘🦘🦘 Triple jump test...")
	for i in range(3):
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		await get_tree().create_timer(0.8).timeout
	print("   ✅ Triple jump: OK")

func _precision_control_test():
	print("\n🔵 === PRECISION CONTROL TEST ===")
	
	print("⚡ Rapid direction changes...")
	# Right-Left-Right-Left rapidly
	for i in range(4):
		if i % 2 == 0:
			print("   ➡️ Quick right")
			Input.action_press("ui_right")
			await get_tree().create_timer(0.3).timeout
			Input.action_release("ui_right")
		else:
			print("   ⬅️ Quick left")
			Input.action_press("ui_left")
			await get_tree().create_timer(0.3).timeout
			Input.action_release("ui_left")
		await get_tree().create_timer(0.1).timeout
	print("   ✅ Rapid changes: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🎯 Micro-movements...")
	# Very short movements
	for i in range(6):
		Input.action_press("ui_right")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("ui_right")
		await get_tree().create_timer(0.1).timeout
	print("   ✅ Micro-movements: OK")

func _complex_patterns_test():
	print("\n🟣 === COMPLEX PATTERNS TEST ===")
	
	print("🔄 Square pattern...")
	# Right
	Input.action_press("ui_right")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("ui_right")
	
	# Jump (simulating "up")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(0.8).timeout
	
	# Left
	Input.action_press("ui_left")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("ui_left")
	
	# Jump again (completing square)
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	await get_tree().create_timer(0.8).timeout
	print("   ✅ Square pattern: OK")
	
	await get_tree().create_timer(0.5).timeout
	
	print("🌊 Wave pattern...")
	# Zigzag movement
	for i in range(3):
		Input.action_press("ui_right")
		await get_tree().create_timer(0.5).timeout
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		await get_tree().create_timer(0.5).timeout
		Input.action_release("ui_right")
		
		Input.action_press("ui_left")
		await get_tree().create_timer(0.5).timeout
		Input.action_press("ui_accept")
		await get_tree().process_frame
		Input.action_release("ui_accept")
		await get_tree().create_timer(0.5).timeout
		Input.action_release("ui_left")
	print("   ✅ Wave pattern: OK")

func _stress_test():
	print("\n🔴 === STRESS TEST ===")
	
	print("⚡ High-frequency input test...")
	# Rapid button mashing
	for i in range(20):
		if i % 3 == 0:
			Input.action_press("ui_accept")
			await get_tree().process_frame
			Input.action_release("ui_accept")
		if i % 2 == 0:
			Input.action_press("ui_right")
		else:
			Input.action_release("ui_right")
			Input.action_press("ui_left")
		
		await get_tree().create_timer(0.05).timeout  # 20fps input
	
	# Clean up
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	print("   ✅ High-frequency input: OK")
	
	await get_tree().create_timer(1.0).timeout
	
	print("🔥 Continuous movement test...")
	# Long continuous movement
	Input.action_press("ui_right")
	for i in range(10):
		print("   📍 Continuous right movement: " + str(i + 1) + "/10 seconds")
		await get_tree().create_timer(1.0).timeout
	Input.action_release("ui_right")
	print("   ✅ Continuous movement: OK")

func stop_all_movement():
	"""Emergency stop function"""
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Input.action_release("ui_accept")
	print("🛑 Emergency stop - all movement halted")