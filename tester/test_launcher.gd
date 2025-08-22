extends Node

# Test Launcher - Main entry point for multiplayer testing
# Run with: godot --headless TestLauncher.tscn

var multi_client_tester: MultiClientTester
var automated_test_runner: AutomatedTestRunner
var problem_isolator: ProblemIsolator
var input_buffer: String = ""
var command_queue: Array = []
var is_automated_mode: bool = false

func _ready():
	print("=== MULTIPLAYER TEST LAUNCHER ===")
	print("Starting in headless mode for automated testing...")
	print("======================================")
	
	# Validate environment first
	if not _validate_environment():
		print("❌ Environment validation failed - some features may not work")
		return
	
	# Get components
	multi_client_tester = $MultiClientTester
	
	# Create automated test runner
	try_create_automated_runner()
	
	# Create problem isolator  
	try_create_problem_isolator()
	
	# Check command line arguments for automation
	var args = OS.get_cmdline_args()
	_process_command_line_args(args)
	
	# Setup input processing
	$InputTimer.timeout.connect(_process_input)
	
	if not is_automated_mode:
		# Show initial help for interactive mode
		multi_client_tester.process_command("help")
		print("\nEnter commands (or 'quit' to exit):")
		print("> ", false)  # Print prompt without newline

func _process_input():
	"""Process input from stdin (simulated for demonstration)"""
	# In a real implementation, you would read from stdin here
	# For now, we'll demonstrate with some auto-commands
	
	if not is_automated_mode and command_queue.is_empty():
		# Add some demo commands for testing
		command_queue = [
			"start_server",
			"spawn_clients 3",
			"broadcast status",
			"run_scenario basic_connection"
		]
	
	if not command_queue.is_empty():
		var command = command_queue.pop_front()
		print("Executing: " + command)
		
		# Route to appropriate handler
		if automated_test_runner and command.begins_with("run_test_suite"):
			automated_test_runner.process_command(command)
		elif automated_test_runner and (command.begins_with("validate_") or command.begins_with("performance_") or command.begins_with("generate_") or command.begins_with("export_") or command.begins_with("continuous_")):
			automated_test_runner.process_command(command)
		elif problem_isolator and (command.begins_with("isolate_") or command.begins_with("collect_") or command.begins_with("reproduce_") or command.begins_with("compare_") or command.begins_with("network_") or command.begins_with("memory_")):
			problem_isolator.process_command(command)
		else:
			multi_client_tester.process_command(command)
		
		if not is_automated_mode and command_queue.is_empty():
			print("\nDemo completed. In real usage, you would type commands interactively.")
			print("Available commands: start_server, spawn_clients, run_scenario, etc.")

func _input(event):
	"""Handle keyboard input for interactive mode"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			if not input_buffer.is_empty():
				multi_client_tester.process_command(input_buffer)
				input_buffer = ""
				print("> ", false)  # Print new prompt
		elif event.keycode == KEY_BACKSPACE:
			if input_buffer.length() > 0:
				input_buffer = input_buffer.substr(0, input_buffer.length() - 1)
		else:
			var character = char(event.unicode)
			if character.is_valid_string() and character != "":
				input_buffer += character

func simulate_commands():
	"""Simulate a series of test commands for demonstration"""
	var demo_commands = [
		"# Demo: Start server and connect clients",
		"start_server 4443",
		"spawn_clients 2 127.0.0.1 4443",
		"# Wait a moment for connections",
		"client 0 status", 
		"client 1 status",
		"# Test movement synchronization",
		"client 0 move 100 100",
		"client 1 move 200 200",
		"broadcast list_players",
		"# Test pickup spawning and collection",
		"client 0 spawn_pickup health_potion 150 150",
		"client 1 move 150 150",
		"broadcast list_pickups",
		"# Run automated test scenario",
		"run_scenario movement_sync",
		"# Show results",
		"results",
		"list_clients"
	]
	
	for command in demo_commands:
		if not command.begins_with("#"):
			print("Executing: " + command)
			multi_client_tester.process_command(command)
			await get_tree().create_timer(1.0).timeout  # Wait between commands

func _process_command_line_args(args: PackedStringArray):
	"""Process command line arguments for automation"""
	for i in range(args.size()):
		var arg = args[i]
		
		match arg:
			"--test-suite":
				if i + 1 < args.size():
					is_automated_mode = true
					var suite_name = args[i + 1]
					command_queue.append("run_test_suite " + suite_name)
					print("Automated mode: Running test suite '" + suite_name + "'")
			
			"--validate-multiplayer":
				is_automated_mode = true
				command_queue.append("validate_multiplayer")
				print("Automated mode: Validating multiplayer functionality")
			
			"--performance-test":
				is_automated_mode = true
				command_queue.append("performance_test")
				print("Automated mode: Running performance tests")
			
			"--continuous-test":
				if i + 1 < args.size():
					is_automated_mode = true
					var duration = args[i + 1]
					command_queue.append("continuous_test " + duration)
					print("Automated mode: Running continuous test for " + duration + " minutes")
			
			"--export-results":
				if i + 1 < args.size():
					var format = args[i + 1]
					command_queue.append("export_results " + format)
					print("Will export results as " + format)
			
			"--help":
				_show_command_line_help()
				get_tree().quit()
				return
	
	if is_automated_mode:
		# Auto-generate report and exit after tests
		command_queue.append("generate_report")
		command_queue.append("export_results json")

func _show_command_line_help():
	"""Show command line usage help"""
	print("=== COMMAND LINE OPTIONS ===")
	print("godot --headless tester/TestLauncher.tscn [options]")
	print("")
	print("Options:")
	print("  --test-suite <name>      Run automated test suite (full/smoke/regression/performance/stability)")
	print("  --validate-multiplayer   Run multiplayer validation tests")
	print("  --performance-test       Run performance benchmark tests")
	print("  --continuous-test <min>  Run continuous testing for specified minutes")
	print("  --export-results <fmt>   Export results in format (json/csv/html)")
	print("  --help                   Show this help")
	print("")
	print("Examples:")
	print("  godot --headless tester/TestLauncher.tscn --test-suite full")
	print("  godot --headless tester/TestLauncher.tscn --validate-multiplayer --export-results json")
	print("  godot --headless tester/TestLauncher.tscn --continuous-test 30")
	print("=============================")

func _validate_environment() -> bool:
	"""Validate that required components exist"""
	var main_scene_exists = FileAccess.file_exists("res://main_scene.tscn") or FileAccess.file_exists("res://Main.tscn")
	if not main_scene_exists:
		print("⚠️  Main scene not found - full testing may not work")
	
	return true  # Continue even with warnings

func try_create_automated_runner():
	"""Try to create automated test runner"""
	if ClassDB.class_exists("AutomatedTestRunner"):
		automated_test_runner = AutomatedTestRunner.new()
		if automated_test_runner:
			add_child(automated_test_runner)
			automated_test_runner.set_multi_client_tester(multi_client_tester)
			print("✅ Automated test runner initialized")
		else:
			print("⚠️  Failed to create automated test runner")
			automated_test_runner = null
	else:
		print("⚠️  AutomatedTestRunner class not found")
		automated_test_runner = null

func try_create_problem_isolator():
	"""Try to create problem isolator"""
	if ClassDB.class_exists("ProblemIsolator"):
		problem_isolator = ProblemIsolator.new()
		if problem_isolator:
			add_child(problem_isolator)
			problem_isolator.set_multi_client_tester(multi_client_tester)
			print("✅ Problem isolator initialized")
		else:
			print("⚠️  Failed to create problem isolator")
			problem_isolator = null
	else:
		print("⚠️  ProblemIsolator class not found")
		problem_isolator = null

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if multi_client_tester:
			multi_client_tester.process_command("quit")
		get_tree().quit()