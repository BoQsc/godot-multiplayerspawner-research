extends Node

func _ready():
	# Load main scene
	var main_scene = load("res://main_scene.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main_scene)
	call_deferred("queue_free")
	
	call_deferred("_move_right")

func _move_right():
	await get_tree().create_timer(3.0).timeout
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		var players = game_manager.get("players")
		var my_peer_id = multiplayer.get_unique_id()
		if players and my_peer_id in players:
			var my_player = players[my_peer_id]
			if my_player:
				var new_pos = my_player.position + Vector2(100, 0)
				my_player.position = new_pos
				print("➡️ MOVED RIGHT to: " + str(new_pos))
			else:
				print("❌ No player found")
	else:
		print("❌ No GameManager")