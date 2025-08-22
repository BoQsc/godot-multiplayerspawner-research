extends Node

# Debug client to test Input.get_axis() with programmatic input

func _ready():
	print("=== AXIS DEBUG CLIENT ===")
	print("Testing Input.get_axis() with programmatic input")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_test_axis_behavior")

func _test_axis_behavior():
	await get_tree().create_timer(8.0).timeout
	
	print("🔍 Testing Input.get_axis() behavior...")
	
	# Test 1: Check initial state
	print("📊 Initial state:")
	print("   Input.get_axis('ui_left', 'ui_right'): ", Input.get_axis("ui_left", "ui_right"))
	print("   Input.is_action_pressed('ui_left'): ", Input.is_action_pressed("ui_left"))
	print("   Input.is_action_pressed('ui_right'): ", Input.is_action_pressed("ui_right"))
	
	# Test 2: Press ui_right programmatically
	print("\n🔧 Pressing ui_right programmatically...")
	Input.action_press("ui_right")
	
	await get_tree().process_frame  # Wait one frame
	
	print("📊 After pressing ui_right:")
	print("   Input.get_axis('ui_left', 'ui_right'): ", Input.get_axis("ui_left", "ui_right"))
	print("   Input.is_action_pressed('ui_left'): ", Input.is_action_pressed("ui_left"))
	print("   Input.is_action_pressed('ui_right'): ", Input.is_action_pressed("ui_right"))
	
	# Test 3: Hold for a few frames
	print("\n⏱️ Holding ui_right for 3 seconds...")
	for i in range(180):  # 3 seconds at 60fps
		await get_tree().process_frame
		if i % 60 == 0:  # Every second
			print("   Frame ", i, " - Input.get_axis('ui_left', 'ui_right'): ", Input.get_axis("ui_left", "ui_right"))
	
	# Test 4: Release
	print("\n🔧 Releasing ui_right...")
	Input.action_release("ui_right")
	
	await get_tree().process_frame
	
	print("📊 After releasing ui_right:")
	print("   Input.get_axis('ui_left', 'ui_right'): ", Input.get_axis("ui_left", "ui_right"))
	print("   Input.is_action_pressed('ui_left'): ", Input.is_action_pressed("ui_left"))
	print("   Input.is_action_pressed('ui_right'): ", Input.is_action_pressed("ui_right"))
	
	# Test 5: Test ui_left
	print("\n🔧 Testing ui_left...")
	Input.action_press("ui_left")
	await get_tree().process_frame
	
	print("📊 After pressing ui_left:")
	print("   Input.get_axis('ui_left', 'ui_right'): ", Input.get_axis("ui_left", "ui_right"))
	print("   Input.is_action_pressed('ui_left'): ", Input.is_action_pressed("ui_left"))
	print("   Input.is_action_pressed('ui_right'): ", Input.is_action_pressed("ui_right"))
	
	Input.action_release("ui_left")
	
	print("\n🏁 Axis debug test completed!")