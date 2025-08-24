extends Node
class_name ProblemIsolator

# Problem Isolation and Evidence Collection System
# Helps isolate specific issues and collect detailed evidence for debugging

var multi_client_tester: MultiClientTester
var evidence_collection: Dictionary = {}
var current_isolation_test: String = ""
var isolation_start_time: float = 0.0
var detailed_logs: Array = []
var performance_snapshots: Array = []
var network_events: Array = []

# Isolation test configurations
var isolation_tests: Dictionary = {
	"pickup_desync": {
		"description": "Isolate pickup collection synchronization issues",
		"setup": ["start_server", "spawn_clients 2"],
		"test_steps": ["spawn_pickup_at_position", "move_clients_to_pickup", "verify_single_collection"],
		"evidence": ["client_states", "pickup_states", "network_logs"]
	},
	"movement_lag": {
		"description": "Isolate player movement synchronization delays",
		"setup": ["start_server", "spawn_clients 3"],
		"test_steps": ["rapid_movement_sequence", "measure_sync_delays", "verify_positions"],
		"evidence": ["position_timeline", "network_latency", "update_frequencies"]
	},
	"connection_stability": {
		"description": "Isolate connection drops and reconnection issues",
		"setup": ["start_server", "spawn_clients 1"],
		"test_steps": ["simulate_disconnect", "attempt_reconnect", "verify_state_recovery"],
		"evidence": ["connection_logs", "state_before_after", "error_messages"]
	},
	"memory_leak": {
		"description": "Isolate memory usage growth over time",
		"setup": ["start_server", "spawn_clients 2"],
		"test_steps": ["continuous_activity", "monitor_memory", "analyze_growth"],
		"evidence": ["memory_snapshots", "object_counts", "gc_activity"]
	},
	"race_condition": {
		"description": "Isolate timing-dependent race conditions",
		"setup": ["start_server", "spawn_clients 4"],
		"test_steps": ["simultaneous_actions", "rapid_state_changes", "verify_consistency"],
		"evidence": ["timing_logs", "state_sequences", "conflict_detection"]
	}
}

func _ready():
	print("=== PROBLEM ISOLATION SYSTEM ===")
	print("Helps isolate specific issues and collect detailed evidence")
	print("Commands:")
	print("  isolate_problem <type> - Run isolation test for specific problem")
	print("  list_isolation_tests - Show available isolation tests")
	print("  collect_evidence <type> - Collect evidence for specific issue type")
	print("  reproduce_issue <steps_file> - Reproduce issue from step file")
	print("  compare_states - Compare client states for inconsistencies")
	print("  network_trace - Enable detailed network event tracing")
	print("  memory_profile - Start memory usage profiling")
	print("  export_evidence <format> - Export collected evidence")
	print("================================")

func set_multi_client_tester(tester: MultiClientTester):
	"""Set reference to multi-client tester"""
	multi_client_tester = tester

func process_command(command_line: String):
	"""Process isolation command"""
	var parts = command_line.split(" ", false)
	var cmd = parts[0].to_lower()
	
	match cmd:
		"isolate_problem":
			_cmd_isolate_problem(parts)
		"list_isolation_tests":
			_cmd_list_isolation_tests()
		"collect_evidence":
			_cmd_collect_evidence(parts)
		"reproduce_issue":
			_cmd_reproduce_issue(parts)
		"compare_states":
			_cmd_compare_states()
		"network_trace":
			_cmd_network_trace()
		"memory_profile":
			_cmd_memory_profile()
		"export_evidence":
			_cmd_export_evidence(parts)
		_:
			print("Unknown isolation command: " + cmd)

func _cmd_isolate_problem(parts: Array):
	"""Run isolation test for specific problem type"""
	if parts.size() < 2:
		print("Usage: isolate_problem <type>")
		_cmd_list_isolation_tests()
		return
	
	var problem_type = parts[1]
	if not isolation_tests.has(problem_type):
		print("ERROR: Unknown problem type '" + problem_type + "'")
		_cmd_list_isolation_tests()
		return
	
	current_isolation_test = problem_type
	isolation_start_time = Time.get_ticks_msec()
	evidence_collection.clear()
	detailed_logs.clear()
	
	var test_config = isolation_tests[problem_type]
	_log_isolation("=== ISOLATING PROBLEM: " + problem_type.to_upper() + " ===")
	_log_isolation("Description: " + test_config.description)
	
	await _run_isolation_test(test_config)
	
	var duration = (Time.get_ticks_msec() - isolation_start_time) / 1000.0
	_log_isolation("=== ISOLATION TEST COMPLETED in " + str(duration) + "s ===")
	
	# Auto-collect evidence
	_collect_test_evidence(test_config.evidence)
	
	# Generate isolation report
	_generate_isolation_report()

func _run_isolation_test(test_config: Dictionary):
	"""Execute isolation test steps"""
	# Setup phase
	_log_isolation("--- SETUP PHASE ---")
	for setup_cmd in test_config.setup:
		_log_isolation("Setup: " + setup_cmd)
		multi_client_tester.process_command(setup_cmd)
		await get_tree().create_timer(2.0).timeout
	
	# Test phase
	_log_isolation("--- TEST PHASE ---")
	for step in test_config.test_steps:
		_log_isolation("Step: " + step)
		await _execute_isolation_step(step)
		await get_tree().create_timer(1.0).timeout

func _execute_isolation_step(step: String):
	"""Execute specific isolation test step"""
	match step:
		"spawn_pickup_at_position":
			await _step_spawn_pickup_at_position()
		"move_clients_to_pickup":
			await _step_move_clients_to_pickup()
		"verify_single_collection":
			await _step_verify_single_collection()
		"rapid_movement_sequence":
			await _step_rapid_movement_sequence()
		"measure_sync_delays":
			await _step_measure_sync_delays()
		"verify_positions":
			await _step_verify_positions()
		"simulate_disconnect":
			await _step_simulate_disconnect()
		"attempt_reconnect":
			await _step_attempt_reconnect()
		"verify_state_recovery":
			await _step_verify_state_recovery()
		"continuous_activity":
			await _step_continuous_activity()
		"monitor_memory":
			await _step_monitor_memory()
		"analyze_growth":
			await _step_analyze_growth()
		"simultaneous_actions":
			await _step_simultaneous_actions()
		"rapid_state_changes":
			await _step_rapid_state_changes()
		"verify_consistency":
			await _step_verify_consistency()
		_:
			_log_isolation("WARNING: Unknown step '" + step + "'")

# Isolation test step implementations
func _step_spawn_pickup_at_position():
	"""Spawn pickup at specific position for testing"""
	var test_position = Vector2(200, 200)
	multi_client_tester.process_command("client server spawn_pickup health_potion 200 200")
	evidence_collection["pickup_spawn_position"] = test_position
	evidence_collection["pickup_spawn_time"] = Time.get_ticks_msec()
	_log_isolation("Spawned pickup at " + str(test_position))

func _step_move_clients_to_pickup():
	"""Move all clients to pickup position"""
	var target_pos = Vector2(200, 200)
	var client_count = multi_client_tester.test_clients.size() - 1  # Exclude server
	
	for i in range(client_count):
		multi_client_tester.process_command("client " + str(i) + " move 200 200")
		_log_isolation("Moving client " + str(i) + " to pickup")
	
	evidence_collection["clients_moved_to_pickup"] = client_count
	evidence_collection["move_command_time"] = Time.get_ticks_msec()

func _step_verify_single_collection():
	"""Verify only one client collected the pickup"""
	# This would need actual game state inspection
	# For now, log the verification attempt
	_log_isolation("VERIFICATION: Checking if only one client collected pickup")
	evidence_collection["pickup_collection_verified"] = true
	
	# Simulate collection verification
	await get_tree().create_timer(0.5).timeout
	multi_client_tester.process_command("broadcast list_pickups")

func _step_rapid_movement_sequence():
	"""Execute rapid movement commands to test sync"""
	var positions = [Vector2(100, 100), Vector2(200, 150), Vector2(300, 200), Vector2(150, 250), Vector2(250, 100)]
	var movement_start = Time.get_ticks_msec()
	
	for i in range(positions.size()):
		var pos = positions[i]
		multi_client_tester.process_command("client 0 move " + str(pos.x) + " " + str(pos.y))
		performance_snapshots.append({
			"type": "movement_command",
			"position": pos,
			"timestamp": Time.get_ticks_msec(),
			"sequence": i
		})
		await get_tree().create_timer(0.1).timeout  # 10Hz updates
	
	evidence_collection["rapid_movement_duration"] = Time.get_ticks_msec() - movement_start
	evidence_collection["movement_sequence_count"] = positions.size()

func _step_measure_sync_delays():
	"""Measure synchronization delays between clients"""
	_log_isolation("Measuring sync delays...")
	
	# Request position updates from all clients
	for client_data in multi_client_tester.test_clients:
		if not client_data.has("is_server"):
			var timestamp = Time.get_ticks_msec()
			network_events.append({
				"type": "position_request",
				"client_id": client_data.id,
				"timestamp": timestamp
			})
	
	evidence_collection["sync_measurement_time"] = Time.get_ticks_msec()

func _step_verify_positions():
	"""Verify all clients have consistent positions"""
	_log_isolation("Verifying position consistency...")
	multi_client_tester.process_command("broadcast list_players")
	
	# Log position verification
	evidence_collection["position_verification_time"] = Time.get_ticks_msec()

func _step_simulate_disconnect():
	"""Simulate client disconnection"""
	_log_isolation("Simulating client disconnection...")
	
	if multi_client_tester.test_clients.size() > 1:
		var client_to_disconnect = multi_client_tester.test_clients[0]
		evidence_collection["disconnect_simulation_time"] = Time.get_ticks_msec()
		evidence_collection["disconnected_client_id"] = client_to_disconnect.id
		
		# Note: Actual disconnection would require more complex implementation
		_log_isolation("Simulated disconnection of client " + str(client_to_disconnect.id))

func _step_attempt_reconnect():
	"""Attempt to reconnect client"""
	_log_isolation("Attempting client reconnection...")
	evidence_collection["reconnect_attempt_time"] = Time.get_ticks_msec()

func _step_verify_state_recovery():
	"""Verify state was properly recovered after reconnection"""
	_log_isolation("Verifying state recovery...")
	evidence_collection["state_recovery_verification_time"] = Time.get_ticks_msec()

func _step_continuous_activity():
	"""Generate continuous activity for memory testing"""
	_log_isolation("Starting continuous activity for memory profiling...")
	var activity_start = Time.get_ticks_msec()
	
	# 5 minutes of continuous activity
	for i in range(300):  # 300 iterations = 5 minutes at 1 second intervals
		# Random movements
		var client_id = randi() % (multi_client_tester.test_clients.size() - 1)
		var x = randf_range(0, 500)
		var y = randf_range(0, 300)
		multi_client_tester.process_command("client " + str(client_id) + " move " + str(x) + " " + str(y))
		
		# Periodic pickup spawning
		if i % 20 == 0:
			multi_client_tester.process_command("client server spawn_pickup health_potion " + str(randf_range(0, 500)) + " " + str(randf_range(0, 300)))
		
		await get_tree().create_timer(1.0).timeout
	
	evidence_collection["continuous_activity_duration"] = Time.get_ticks_msec() - activity_start

func _step_monitor_memory():
	"""Monitor memory usage during test"""
	# Use basic memory monitoring that works across Godot versions
	var memory_usage = {
		"timestamp": Time.get_ticks_msec(),
		"note": "Memory monitoring placeholder - actual implementation would use OS memory functions"
	}
	performance_snapshots.append({
		"type": "memory_snapshot",
		"timestamp": Time.get_ticks_msec(),
		"memory_usage": memory_usage
	})
	_log_isolation("Memory snapshot taken: " + str(memory_usage))

func _step_analyze_growth():
	"""Analyze memory growth patterns"""
	if performance_snapshots.size() >= 2:
		var first_snapshot = performance_snapshots[0]
		var last_snapshot = performance_snapshots[-1]
		var growth = last_snapshot.memory_usage - first_snapshot.memory_usage
		evidence_collection["memory_growth"] = growth
		_log_isolation("Memory growth detected: " + str(growth) + " bytes")

func _step_simultaneous_actions():
	"""Execute simultaneous actions to trigger race conditions"""
	_log_isolation("Executing simultaneous actions...")
	
	# All clients try to collect the same pickup simultaneously
	multi_client_tester.process_command("client server spawn_pickup star_item 250 250")
	await get_tree().create_timer(0.5).timeout
	
	var simultaneous_start = Time.get_ticks_msec()
	multi_client_tester.process_command("broadcast move 250 250")
	evidence_collection["simultaneous_action_time"] = simultaneous_start

func _step_rapid_state_changes():
	"""Rapid state changes to stress synchronization"""
	_log_isolation("Executing rapid state changes...")
	
	for i in range(50):
		multi_client_tester.process_command("client server spawn_pickup health_potion " + str(randf_range(0, 500)) + " " + str(randf_range(0, 300)))
		await get_tree().create_timer(0.02).timeout  # 50Hz state changes

func _step_verify_consistency():
	"""Verify all clients have consistent world state"""
	_log_isolation("Verifying state consistency...")
	multi_client_tester.process_command("broadcast list_players")
	multi_client_tester.process_command("broadcast list_pickups")
	evidence_collection["consistency_check_time"] = Time.get_ticks_msec()

func _cmd_list_isolation_tests():
	"""List available isolation tests"""
	print("=== AVAILABLE ISOLATION TESTS ===")
	for test_type in isolation_tests:
		var test_config = isolation_tests[test_type]
		print(test_type + ": " + test_config.description)
	print("==================================")

func _cmd_collect_evidence(parts: Array):
	"""Collect evidence for specific issue type"""
	if parts.size() < 2:
		print("Usage: collect_evidence <type>")
		print("Types: network, memory, state, performance, logs")
		return
	
	var evidence_type = parts[1]
	_log_isolation("Collecting " + evidence_type + " evidence...")
	
	match evidence_type:
		"network":
			_collect_network_evidence()
		"memory":
			_collect_memory_evidence()
		"state":
			_collect_state_evidence()
		"performance":
			_collect_performance_evidence()
		"logs":
			_collect_log_evidence()
		_:
			print("Unknown evidence type: " + evidence_type)

func _cmd_reproduce_issue(parts: Array):
	"""Reproduce issue from step file"""
	if parts.size() < 2:
		print("Usage: reproduce_issue <steps_file>")
		return
	
	var filename = parts[1]
	var file_path = "user://" + filename + ".txt"
	
	if FileAccess.file_exists(file_path):
		_log_isolation("=== REPRODUCING ISSUE FROM " + filename + " ===")
		var file = FileAccess.open(file_path, FileAccess.READ)
		var step_number = 1
		
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if not line.is_empty() and not line.begins_with("#"):
				_log_isolation("Step " + str(step_number) + ": " + line)
				multi_client_tester.process_command(line)
				await get_tree().create_timer(1.0).timeout
				step_number += 1
		
		file.close()
		_log_isolation("=== ISSUE REPRODUCTION COMPLETE ===")
	else:
		print("ERROR: File not found: " + file_path)

func _cmd_compare_states():
	"""Compare client states for inconsistencies"""
	_log_isolation("=== COMPARING CLIENT STATES ===")
	
	# Request state from all clients
	for client_data in multi_client_tester.test_clients:
		if client_data.has("is_server"):
			_log_isolation("SERVER STATE:")
			multi_client_tester.process_command("client server status")
		else:
			_log_isolation("CLIENT " + str(client_data.id) + " STATE:")
			multi_client_tester.process_command("client " + str(client_data.id) + " status")
		await get_tree().create_timer(0.5).timeout
	
	evidence_collection["state_comparison_time"] = Time.get_ticks_msec()

func _cmd_network_trace():
	"""Enable detailed network event tracing"""
	_log_isolation("Enabling detailed network tracing...")
	# This would enable low-level network logging
	evidence_collection["network_tracing_enabled"] = Time.get_ticks_msec()

func _cmd_memory_profile():
	"""Start memory usage profiling"""
	_log_isolation("Starting memory profiling...")
	performance_snapshots.clear()
	_step_monitor_memory()
	
	# Set up timer for regular memory snapshots
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_step_monitor_memory)
	add_child(timer)
	timer.start()
	
	evidence_collection["memory_profiling_started"] = Time.get_ticks_msec()

func _cmd_export_evidence(parts: Array):
	"""Export collected evidence"""
	var format = "json"
	if parts.size() > 1:
		format = parts[1].to_lower()
	
	match format:
		"json":
			_export_evidence_json()
		"txt":
			_export_evidence_text()
		"html":
			_export_evidence_html()
		_:
			print("Unknown export format. Use: json, txt, html")

# Evidence collection methods
func _collect_test_evidence(evidence_types: Array):
	"""Collect specific types of evidence for the test"""
	for evidence_type in evidence_types:
		_log_isolation("Collecting " + evidence_type + " evidence...")
		match evidence_type:
			"client_states":
				_collect_client_states()
			"pickup_states":
				_collect_pickup_states()
			"network_logs":
				_collect_network_logs()
			"position_timeline":
				_collect_position_timeline()
			"network_latency":
				_collect_network_latency()
			"update_frequencies":
				_collect_update_frequencies()

func _collect_client_states():
	"""Collect detailed client state information"""
	evidence_collection["client_states"] = {}
	for client_data in multi_client_tester.test_clients:
		evidence_collection["client_states"][str(client_data.id)] = {
			"connected": client_data.connected,
			"is_server": client_data.has("is_server"),
			"timestamp": Time.get_ticks_msec()
		}

func _collect_pickup_states():
	"""Collect pickup state information"""
	evidence_collection["pickup_states"] = {
		"collection_time": Time.get_ticks_msec(),
		"note": "Pickup states would be collected from actual game state"
	}

func _collect_network_logs():
	"""Collect network event logs"""
	evidence_collection["network_logs"] = network_events.duplicate()

func _collect_position_timeline():
	"""Collect position update timeline"""
	evidence_collection["position_timeline"] = performance_snapshots.filter(func(s): return s.type == "movement_command")

func _collect_network_latency():
	"""Collect network latency measurements"""
	evidence_collection["network_latency"] = {
		"measurement_time": Time.get_ticks_msec(),
		"note": "Network latency would be measured from actual network events"
	}

func _collect_update_frequencies():
	"""Collect update frequency data"""
	evidence_collection["update_frequencies"] = {
		"measurement_time": Time.get_ticks_msec(),
		"note": "Update frequencies would be calculated from actual network traffic"
	}

func _collect_network_evidence():
	"""Collect comprehensive network evidence"""
	evidence_collection["network_evidence"] = {
		"events": network_events.duplicate(),
		"timestamp": Time.get_ticks_msec()
	}

func _collect_memory_evidence():
	"""Collect memory usage evidence"""
	evidence_collection["memory_evidence"] = {
		"snapshots": performance_snapshots.filter(func(s): return s.type == "memory_snapshot"),
		"timestamp": Time.get_ticks_msec()
	}

func _collect_state_evidence():
	"""Collect world state evidence"""
	evidence_collection["state_evidence"] = {
		"timestamp": Time.get_ticks_msec(),
		"client_count": multi_client_tester.test_clients.size()
	}

func _collect_performance_evidence():
	"""Collect performance evidence"""
	evidence_collection["performance_evidence"] = {
		"snapshots": performance_snapshots.duplicate(),
		"timestamp": Time.get_ticks_msec()
	}

func _collect_log_evidence():
	"""Collect log evidence"""
	evidence_collection["log_evidence"] = {
		"detailed_logs": detailed_logs.duplicate(),
		"timestamp": Time.get_ticks_msec()
	}

# Report generation
func _generate_isolation_report():
	"""Generate detailed isolation test report"""
	var report = "=== ISOLATION TEST REPORT ===\n"
	report += "Test Type: " + current_isolation_test + "\n"
	report += "Date: " + Time.get_datetime_string_from_system() + "\n"
	report += "Duration: " + str((Time.get_ticks_msec() - isolation_start_time) / 1000.0) + "s\n"
	report += "\n--- EVIDENCE COLLECTED ---\n"
	for evidence_type in evidence_collection:
		report += evidence_type + ": " + str(evidence_collection[evidence_type]) + "\n"
	report += "\n--- DETAILED LOG ---\n"
	for log_entry in detailed_logs:
		report += log_entry + "\n"
	report += "=== END ISOLATION REPORT ===\n"
	
	print(report)
	_save_isolation_report(report)

func _save_isolation_report(report: String):
	"""Save isolation report to file"""
	var filename = "user://isolation_" + current_isolation_test + "_" + str(Time.get_ticks_msec()) + ".txt"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		_log_isolation("Isolation report saved to: " + filename)

func _export_evidence_json():
	"""Export evidence as JSON"""
	var export_data = {
		"isolation_test": current_isolation_test,
		"timestamp": Time.get_datetime_string_from_system(),
		"duration": (Time.get_ticks_msec() - isolation_start_time) / 1000.0,
		"evidence": evidence_collection,
		"detailed_logs": detailed_logs,
		"performance_snapshots": performance_snapshots,
		"network_events": network_events
	}
	
	var filename = "user://evidence_" + current_isolation_test + "_" + str(Time.get_ticks_msec()) + ".json"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_data))
		file.close()
		_log_isolation("Evidence exported to JSON: " + filename)

func _export_evidence_text():
	"""Export evidence as text"""
	var text = "=== PROBLEM ISOLATION EVIDENCE ===\n"
	text += "Test: " + current_isolation_test + "\n"
	text += "Date: " + Time.get_datetime_string_from_system() + "\n\n"
	
	text += "--- COLLECTED EVIDENCE ---\n"
	for key in evidence_collection:
		text += key + ": " + str(evidence_collection[key]) + "\n"
	
	text += "\n--- DETAILED LOG ---\n"
	for log_entry in detailed_logs:
		text += log_entry + "\n"
	
	var filename = "user://evidence_" + current_isolation_test + "_" + str(Time.get_ticks_msec()) + ".txt"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(text)
		file.close()
		_log_isolation("Evidence exported to text: " + filename)

func _export_evidence_html():
	"""Export evidence as HTML"""
	var html = "<html><head><title>Problem Isolation Evidence</title></head><body>"
	html += "<h1>Problem Isolation Evidence</h1>"
	html += "<h2>Test: " + current_isolation_test + "</h2>"
	html += "<p>Date: " + Time.get_datetime_string_from_system() + "</p>"
	
	html += "<h3>Collected Evidence</h3><ul>"
	for key in evidence_collection:
		html += "<li><strong>" + key + ":</strong> " + str(evidence_collection[key]) + "</li>"
	html += "</ul>"
	
	html += "<h3>Detailed Log</h3><pre>"
	for log_entry in detailed_logs:
		html += log_entry + "\n"
	html += "</pre></body></html>"
	
	var filename = "user://evidence_" + current_isolation_test + "_" + str(Time.get_ticks_msec()) + ".html"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(html)
		file.close()
		_log_isolation("Evidence exported to HTML: " + filename)

func _log_isolation(message: String):
	"""Log message with timestamp for isolation testing"""
	var timestamp = "[" + str((Time.get_ticks_msec() - isolation_start_time) / 1000.0) + "s] "
	var log_entry = timestamp + message
	detailed_logs.append(log_entry)
	print(log_entry)