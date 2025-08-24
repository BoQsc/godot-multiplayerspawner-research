extends Node

# Frame-based movement client (no timers)

var frame_count = 0
var state = "waiting"

func _ready():
	print("=== FRAME-BASED CLIENT ===")
	print("Moving RIGHT NOW!")
	
	Input.action_press("ui_right")
	print("✅ Pressed ui_right immediately")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	set_process(true)
	call_deferred("_start_sequence")

func _start_sequence():
	print("🚀 Starting frame-based movement sequence...")
	state = "moving_right"
	frame_count = 0
	Input.action_press("ui_right")

func _process(_delta):
	frame_count += 1
	
	match state:
		"moving_right":
			if frame_count >= 120:  # 2 seconds at 60fps
				print("⏹️ Stopping right movement at frame " + str(frame_count))
				Input.action_release("ui_right")
				state = "before_jump"
				frame_count = 0
		
		"before_jump":
			if frame_count >= 30:  # 0.5 seconds
				print("🦘 Jumping at frame " + str(frame_count))
				Input.action_press("ui_accept")
				await get_tree().process_frame
				Input.action_release("ui_accept")
				state = "after_jump"
				frame_count = 0
		
		"after_jump":
			if frame_count >= 60:  # 1 second
				print("⬅️ Moving left at frame " + str(frame_count))
				Input.action_press("ui_left")
				state = "moving_left"
				frame_count = 0
		
		"moving_left":
			if frame_count >= 120:  # 2 seconds
				print("⏹️ Stopping left movement at frame " + str(frame_count))
				Input.action_release("ui_left")
				state = "complete"
				print("🏁 Frame-based movement sequence COMPLETE!")
				set_process(false)