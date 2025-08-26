extends Node

# Test with completely clean state - Hypothesis 1: Client slot limit

func _ready():
	print("=== CLEAN STATE TEST ===")
	print("Testing movement with fresh user data")
	
	# First, try to reset/clean any persistent state
	var user_data_dir = OS.get_user_data_dir()
	print("User data dir: " + user_data_dir)
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_test_with_minimal_setup")

func _test_with_minimal_setup():
	await get_tree().create_timer(5.0).timeout
	
	print("🧹 CLEAN STATE ANALYSIS:")
	print("Current client slot: " + str(multiplayer.get_unique_id()))
	
	# Check if we can find our player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager")
		return
		
	var players = game_manager.get("players")
	if not players:
		print("❌ No players dict")
		return
		
	var my_id = multiplayer.get_unique_id()
	if not (my_id in players):
		print("❌ Player not spawned")
		return
		
	var my_player = players[my_id]
	print("✅ Player found: " + str(my_player))
	print("   is_local_player: " + str(my_player.get("is_local_player")))
	print("   position: " + str(my_player.position))
	
	# THE CRITICAL TEST - does movement work with clean state?
	print("🧪 MOVEMENT TEST WITH CLEAN STATE:")
	var start_pos = my_player.position
	
	print("   Pressing ui_right...")
	Input.action_press("ui_right")
	
	# Wait and check
	for i in range(60):  # 1 second
		await get_tree().process_frame
		if my_player.position != start_pos:
			print("   ✅ MOVEMENT DETECTED after " + str(i) + " frames!")
			print("   New position: " + str(my_player.position))
			Input.action_release("ui_right")
			print("🎉 CLEAN STATE TEST: SUCCESS")
			return
	
	print("   ❌ NO MOVEMENT after 60 frames")
	Input.action_release("ui_right")
	print("💥 CLEAN STATE TEST: FAILED")
	
	# If still failed, the issue is deeper than client slots