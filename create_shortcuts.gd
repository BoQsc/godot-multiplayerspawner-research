extends Node

# Desktop shortcut creation utility for multiplayer player selection
# This script generates Windows .lnk shortcuts for easy player access

const SHORTCUT_TEMPLATE = """
$WshShell = New-Object -ComObject WScript.Shell
$Desktop = [System.Environment]::GetFolderPath('Desktop')
$ShortcutPath = "$Desktop\\{shortcut_name}.lnk"
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "{exe_path}"
$Shortcut.Arguments = "--player={player_num}"
$Shortcut.WorkingDirectory = "{work_dir}"
$Shortcut.IconLocation = "{exe_path},0"
$Shortcut.Description = "Launch as Player {player_num}"
$Shortcut.Save()
"""

func create_player_shortcuts(max_players: int = 10):
	"""Create desktop shortcuts for players 1 through max_players"""
	
	# Get the current project's executable path
	var exe_path = OS.get_executable_path()
	var work_dir = exe_path.get_base_dir()
	var project_name = ProjectSettings.get_setting("application/config/name", "GameProject")
	
	print("Creating shortcuts for ", max_players, " players...")
	print("Executable: ", exe_path)
	
	for player_num in range(1, max_players + 1):
		var shortcut_name = project_name + " - Player " + str(player_num)
		var ps_script = SHORTCUT_TEMPLATE.format({
			"shortcut_name": shortcut_name,
			"exe_path": exe_path,
			"player_num": player_num,
			"work_dir": work_dir
		})
		
		# Write PowerShell script to temp file
		var temp_script = "user://create_shortcut_" + str(player_num) + ".ps1"
		var file = FileAccess.open(temp_script, FileAccess.WRITE)
		if file:
			file.store_string(ps_script)
			file.close()
			
			# Execute PowerShell script
			var temp_script_path = ProjectSettings.globalize_path(temp_script)
			var output = []
			var exit_code = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", temp_script_path], output)
			
			if exit_code == 0:
				print("✓ Created shortcut for Player ", player_num)
			else:
				print("✗ Failed to create shortcut for Player ", player_num, ": ", output)
			
			# Clean up temp file
			DirAccess.remove_absolute(temp_script_path)
		else:
			print("✗ Failed to create temp script for Player ", player_num)
	
	print("Shortcut creation completed!")

# Alternative method for development environment
func create_dev_shortcuts():
	"""Create shortcuts for development that launch the Godot editor with player args"""
	var godot_exe = find_godot_executable()
	if godot_exe == "":
		print("Godot executable not found. Please run this from exported project.")
		return
	
	var project_path = ProjectSettings.globalize_path("res://project.godot")
	var project_name = ProjectSettings.get_setting("application/config/name", "GameProject")
	
	for player_num in range(1, 5):  # Create 4 dev shortcuts
		var shortcut_name = project_name + " DEV - Player " + str(player_num)
		var ps_script = SHORTCUT_TEMPLATE.format({
			"shortcut_name": shortcut_name,
			"exe_path": godot_exe,
			"player_num": player_num,
			"work_dir": project_path.get_base_dir()
		})
		# Add project path argument for Godot editor
		ps_script = ps_script.replace('$Shortcut.Arguments = "--player={player_num}"', 
			'$Shortcut.Arguments = "--path \"{project_path}\" --player={player_num}"'.format({"project_path": project_path, "player_num": player_num}))
		
		var temp_script = "user://create_dev_shortcut_" + str(player_num) + ".ps1"
		var file = FileAccess.open(temp_script, FileAccess.WRITE)
		if file:
			file.store_string(ps_script)
			file.close()
			
			var temp_script_path = ProjectSettings.globalize_path(temp_script)
			var output = []
			var exit_code = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", temp_script_path], output)
			
			if exit_code == 0:
				print("✓ Created dev shortcut for Player ", player_num)
			else:
				print("✗ Failed to create dev shortcut for Player ", player_num)
			
			DirAccess.remove_absolute(temp_script_path)

func find_godot_executable() -> String:
	"""Try to find Godot executable in common locations"""
	var possible_paths = [
		"C:\\Program Files\\Godot\\godot.exe",
		"C:\\Users\\" + OS.get_environment("USERNAME") + "\\AppData\\Local\\Godot\\godot.exe",
		"godot.exe"  # If it's in PATH
	]
	
	for path in possible_paths:
		if FileAccess.file_exists(path):
			return path
	
	return ""

# Create shortcut for a specific UUID-based player
func create_uuid_shortcut(uuid_player_id: String):
	"""Create desktop shortcut for UUID-based player (e.g., player_1d78ff11-8aa9-4f37-a4e1-c2e93a200b0f)"""
	var exe_path = OS.get_executable_path()
	var work_dir = exe_path.get_base_dir()
	var project_name = ProjectSettings.get_setting("application/config/name", "GameProject")
	
	# Extract just the UUID part for display
	var uuid_part = uuid_player_id.replace("player_", "")
	var shortcut_name = project_name + " - " + uuid_part.substr(0, 8) + "..."  # Show first 8 chars
	
	var ps_script = SHORTCUT_TEMPLATE.format({
		"shortcut_name": shortcut_name,
		"exe_path": exe_path,
		"player_num": uuid_part,  # Use full UUID as player identifier
		"work_dir": work_dir
	})
	
	var temp_script = "user://create_uuid_shortcut.ps1"
	var file = FileAccess.open(temp_script, FileAccess.WRITE)
	if file:
		file.store_string(ps_script)
		file.close()
		
		var temp_script_path = ProjectSettings.globalize_path(temp_script)
		var output = []
		var exit_code = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", temp_script_path], output)
		
		if exit_code == 0:
			print("✓ Created UUID shortcut: ", shortcut_name)
			return true
		else:
			print("✗ Failed to create UUID shortcut: ", output)
			return false
		
		DirAccess.remove_absolute(temp_script_path)
	return false

# Call this function from another script or the command line
func _ready():
	if "--create-shortcuts" in OS.get_cmdline_args():
		var max_players = 10
		
		# Check for custom player count
		var args = OS.get_cmdline_args()
		for i in range(args.size()):
			if args[i] == "--max-players" and i + 1 < args.size():
				max_players = int(args[i + 1])
				break
		
		create_player_shortcuts(max_players)
		get_tree().quit()
	elif "--create-dev-shortcuts" in OS.get_cmdline_args():
		create_dev_shortcuts()
		get_tree().quit()
	elif "--create-uuid-shortcut" in OS.get_cmdline_args():
		# Create shortcut for specific UUID player
		var args = OS.get_cmdline_args()
		for i in range(args.size()):
			if args[i] == "--uuid-player" and i + 1 < args.size():
				var uuid_player = args[i + 1]
				create_uuid_shortcut(uuid_player)
				get_tree().quit()
				return
		print("ERROR: --create-uuid-shortcut requires --uuid-player parameter")
		get_tree().quit()