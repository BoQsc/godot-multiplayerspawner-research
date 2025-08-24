extends Node

# Simple confirmation test - just connect and report position

func _ready():
	print("=== CONFIRMATION TEST ===")
	print("Just connecting and reporting position...")
	
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_report_status")

func _report_status():
	await get_tree().create_timer(5.0).timeout
	
	print("📍 POSITION REPORT:")
	print("Player ID: " + str(multiplayer.get_unique_id()))
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		var players = game_manager.get("players")
		if players and (multiplayer.get_unique_id() in players):
			var my_player = players[multiplayer.get_unique_id()]
			print("Position: " + str(my_player.position))
			print("✅ Player spawned successfully")
			
			# Stay alive and report position every 2 seconds
			while true:
				await get_tree().create_timer(2.0).timeout
				print("Current position: " + str(my_player.position))
		else:
			print("❌ Player not found in game")
	else:
		print("❌ GameManager not found")