extends Node

# Test client that completely overrides physics processing

var target_player = null
var override_active = false

func _ready():
	print("=== PHYSICS OVERRIDE CLIENT ===")
	print("This client completely replaces the physics process")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_start_physics_override")

func _start_physics_override():
	await get_tree().create_timer(8.0).timeout
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("❌ No GameManager found")
		return
	
	var players = game_manager.get("players")
	var my_peer_id = multiplayer.get_unique_id()
	
	if not players or not (my_peer_id in players):
		print("❌ Player not found")
		return
	
	target_player = players[my_peer_id]
	print("✅ Found target player: " + str(my_peer_id))
	print("📍 Player is_local_player: " + str(target_player.is_local_player))
	print("📍 Starting position: " + str(target_player.position))
	
	# COMPLETELY OVERRIDE the physics process
	print("🔧 Overriding entire physics process...")
	target_player.set_physics_process(false)  # Disable original physics
	override_active = true
	
	# Start our custom movement
	_start_movement_demo()

func _start_movement_demo():
	print("🚀 Starting custom physics movement demo...")
	
	# Move right for 4 seconds
	print("➡️ Moving right for 4 seconds...")
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < 4000:
		if target_player and override_active:
			target_player.velocity.x = 200
			target_player.velocity.y += target_player.gravity * get_process_delta_time()
			target_player.move_and_slide()
		await get_tree().process_frame
	
	# Stop
	print("⏹️ Stopping...")
	await get_tree().create_timer(1.0).timeout
	
	# Jump
	print("🦘 Jumping...")
	if target_player and override_active:
		target_player.velocity.y = -400
	
	# Move left for 4 seconds
	print("⬅️ Moving left for 4 seconds...")
	start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < 4000:
		if target_player and override_active:
			target_player.velocity.x = -200
			if not target_player.is_on_floor():
				target_player.velocity.y += target_player.gravity * get_process_delta_time()
			target_player.move_and_slide()
		await get_tree().process_frame
	
	# Final stop
	print("⏹️ Final stop")
	if target_player and override_active:
		target_player.velocity.x = 0
	
	print("🏁 Physics override demo completed!")
	print("📍 Final position: " + str(target_player.position))

func _process(_delta):
	# Keep player stationary when not in demo
	if target_player and override_active and not _is_demo_running():
		target_player.velocity.x = 0
		if not target_player.is_on_floor():
			target_player.velocity.y += target_player.gravity * get_process_delta_time()
		target_player.move_and_slide()

func _is_demo_running() -> bool:
	# Simple check - this is a basic implementation
	return false  # For now, always let the demo control movement