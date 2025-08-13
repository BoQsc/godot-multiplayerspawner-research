@tool
extends EditorPlugin

var was_playing = false

func _enter_tree():
	print("Scene Auto-Reloader: Plugin enabled and active.")

func _exit_tree():
	print("Scene Auto-Reloader: Plugin disabled.")

func _process(delta):
	var editor_interface = get_editor_interface()
	
	# The correct function to check if the game is running in Godot 4.
	var is_playing = editor_interface.is_playing_scene()

	# Detect the state change from "playing" to "stopped".
	if was_playing and not is_playing:
		print("Scene Auto-Reloader: Project stopped running. Initiating scene reload.")
		
		var edited_scene_root = editor_interface.get_edited_scene_root()
		var current_scene_path = ""
		
		if edited_scene_root:
			current_scene_path = edited_scene_root.scene_file_path

		if not current_scene_path.is_empty():
			editor_interface.reload_scene_from_path(current_scene_path)
			print("Scene Auto-Reloader: Reloaded scene '", current_scene_path, "'.")
		else:
			print("Scene Auto-Reloader: No valid scene is currently open to reload.")
	
	was_playing = is_playing
