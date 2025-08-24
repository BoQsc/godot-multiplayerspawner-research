extends Node

# Input simulator that uses proper player controls

func _ready():
	print("=== INPUT SIMULATOR ===")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_input_simulation")

func _start_input_simulation():
	await get_tree().create_timer(5.0).timeout
	
	print("🎮 Starting input simulation...")
	print("Simulating RIGHT key press...")
	
	# Simulate right key press for 2 seconds
	for i in range(120):  # 60 FPS * 2 seconds
		Input.action_press("ui_right")
		await get_tree().process_frame
	
	Input.action_release("ui_right")
	print("✅ Released RIGHT key")
	
	await get_tree().create_timer(1.0).timeout
	
	print("🦘 Simulating JUMP...")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	print("✅ Jump executed")
	
	print("🏁 Input simulation complete!")