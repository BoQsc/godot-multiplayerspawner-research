@tool
extends EditorPlugin

var timer: Timer
var reload_interval: float = 2.0

func _enter_tree():
	timer = Timer.new()
	timer.wait_time = reload_interval
	timer.timeout.connect(_on_reload_timer_timeout)
	timer.autostart = true
	add_child(timer)
	print("Scene Auto Reload: Plugin enabled - reloading scene every ", reload_interval, " seconds")

func _exit_tree():
	if timer:
		timer.queue_free()
		timer = null
	print("Scene Auto Reload: Plugin disabled")

func _on_reload_timer_timeout():
	var current_scene = EditorInterface.get_edited_scene_root()
	if current_scene:
		var scene_path = current_scene.scene_file_path
		if scene_path != "":
			print("Scene Auto Reload: Reloading scene - ", scene_path)
			EditorInterface.reload_scene_from_path(scene_path)
		else:
			print("Scene Auto Reload: No scene file path found, skipping reload")
	else:
		print("Scene Auto Reload: No scene currently open, skipping reload")
