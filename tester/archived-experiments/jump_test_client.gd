extends Node

# Simple jump test client

func _ready():
	print("=== JUMP TEST CLIENT ===")
	print("Testing jump command specifically")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_test_jump")

func _test_jump():
	print("⏳ Waiting for spawn...")
	await get_tree().create_timer(8.0).timeout
	
	print("🦘 JUMPING NOW!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(2.0).timeout
	
	print("🦘 JUMPING AGAIN!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	await get_tree().create_timer(2.0).timeout
	
	print("🦘 THIRD JUMP!")
	Input.action_press("ui_accept")
	await get_tree().process_frame
	Input.action_release("ui_accept")
	
	print("🏁 Jump test complete!")