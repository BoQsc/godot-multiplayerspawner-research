extends Node

# Test client using proper InputEvent simulation (the CORRECT way)

func _ready():
	print("=== INPUT EVENT CLIENT ===")
	print("Using Input.parse_input_event() - the correct way to simulate input")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_input_simulation")

func _start_input_simulation():
	await get_tree().create_timer(8.0).timeout
	
	print("🚀 Starting PROPER input event simulation...")
	print("Player ID: " + str(multiplayer.get_unique_id()))
	
	# Start movement sequence using REAL InputEvent objects
	_execute_movement_sequence()

func _execute_movement_sequence():
	print("🎮 Starting movement sequence with InputEvent simulation...")
	
	# Move right for 4 seconds
	print("➡️ Moving right (4 seconds)")
	_simulate_action_start("ui_right")
	await get_tree().create_timer(4.0).timeout
	_simulate_action_stop("ui_right")
	
	# Brief pause
	await get_tree().create_timer(0.5).timeout
	
	# Jump
	print("🦘 Jumping")
	_simulate_action_press("ui_accept")
	
	# Brief pause
	await get_tree().create_timer(1.0).timeout
	
	# Move left for 4 seconds
	print("⬅️ Moving left (4 seconds)")
	_simulate_action_start("ui_left")
	await get_tree().create_timer(4.0).timeout
	_simulate_action_stop("ui_left")
	
	# Another jump
	print("🦘 Jumping again")
	_simulate_action_press("ui_accept")
	
	# Brief pause
	await get_tree().create_timer(1.0).timeout
	
	# Move right while jumping
	print("➡️🦘 Moving right + jumping")
	_simulate_action_start("ui_right")
	await get_tree().create_timer(1.0).timeout
	_simulate_action_press("ui_accept")
	await get_tree().create_timer(2.0).timeout
	_simulate_action_stop("ui_right")
	
	print("🏁 InputEvent simulation completed!")

func _simulate_action_start(action_name: String):
	"""Start holding an action (like holding down arrow key)"""
	var input_event = InputEventAction.new()
	input_event.action = action_name
	input_event.pressed = true
	Input.parse_input_event(input_event)
	print("   📤 Started action: " + action_name)

func _simulate_action_stop(action_name: String):
	"""Stop holding an action (like releasing arrow key)"""
	var input_event = InputEventAction.new()
	input_event.action = action_name
	input_event.pressed = false
	Input.parse_input_event(input_event)
	print("   📤 Stopped action: " + action_name)

func _simulate_action_press(action_name: String):
	"""Simulate a single press (like tapping space for jump)"""
	# Press
	var input_event_press = InputEventAction.new()
	input_event_press.action = action_name
	input_event_press.pressed = true
	Input.parse_input_event(input_event_press)
	
	# Wait one frame then release
	await get_tree().process_frame
	
	var input_event_release = InputEventAction.new()
	input_event_release.action = action_name
	input_event_release.pressed = false
	Input.parse_input_event(input_event_release)
	
	print("   📤 Pressed action: " + action_name)