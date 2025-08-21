# NPC Implementation Guide - Godot Multiplayer Project

## Project Status Analysis

**Date:** January 2025  
**Project:** godot-multiplayerspawner-research  
**Branch:** Project-4.5-RPC-  

### Current State ✅

The project has been successfully prepared for NPC implementation:

- **Entities Folder:** `entities/` directory now exists with `entity_scene.tscn` and `entity_scene.gd`
- **Path Updates:** All references updated to use `res://entities/entity_scene.tscn`
- **Architecture:** Manual spawning system with server authority proven and working
- **Assets Available:** Rich sprite collections for enemies, NPCs, and items

## Available Assets for NPCs

### 🎨 Kenney Platformer Art Pack

**Enemy Sprites Available:**
- **Slime:** `slimeWalk1.png`, `slimeWalk2.png`, `slimeDead.png`
- **Snail:** `snailWalk1.png`, `snailWalk2.png`, `snailShell.png`
- **Fly:** `flyFly1.png`, `flyFly2.png`, `flyDead.png`
- **Fish:** `fishSwim1.png`, `fishSwim2.png`, `fishDead.png`
- **Blockers:** `blockerBody.png`, `blockerMad.png`, `blockerSad.png`
- **Poker:** `pokerMad.png`, `pokerSad.png`

**Item Sprites Available:**
- **Collectibles:** Coins (bronze, silver, gold), gems (blue, green, red, yellow)
- **Keys:** Blue, green, red, yellow keys
- **Environment:** Mushrooms, plants, rocks, spikes, springs
- **Interactive:** Buttons, switches, flags, doors

### 🧙‍♂️ Kenney Voxel Pack Characters

**Character Components Available:**
- **Human NPCs:** Male, female with separate body parts (head, body, arms, legs)
- **Fantasy:** Skeleton, zombie, gnome character parts
- **Creatures:** Alien, boar, fox, hedgehog character parts

## Current Entity Architecture Analysis

### Entity Scene Structure (`entities/entity_scene.gd`)

The existing player entity provides these capabilities:

```gdscript
extends CharacterBody2D

# Core Properties
@export var speed = 300.0
@export var jump_velocity = -800.0  
@export var gravity = 2000.0

# Network Integration
var player_id: int
var is_local_player: bool
var network_manager: NetworkManager
var game_manager: Node

# Features
- Physics-based movement
- Network synchronization 
- Connection quality monitoring
- Timer-based network updates
- Camera management (local player only)
```

**Key Features NPCs Can Inherit:**
- ✅ CharacterBody2D physics system
- ✅ Network manager integration
- ✅ Manager references (game_manager, network_manager)
- ✅ Position synchronization patterns
- ✅ Timer-based updates

## NPC Implementation Strategy

### 1. Create Base NPC Class

```gdscript
# entities/base_npc.gd
extends CharacterBody2D
class_name BaseNPC

@export var npc_type: String = "base_npc"
@export var max_health: float = 100.0
@export var movement_speed: float = 50.0
@export var interaction_range: float = 64.0
@export var ai_enabled: bool = true

# Core NPC properties
var npc_id: String
var current_health: float
var game_manager: Node
var network_manager: NetworkManager
var is_interactable: bool = false
var requires_network_sync: bool = false

# AI state
var ai_state: String = "idle"
var ai_target: Vector2
var ai_timer: float = 0.0

func _ready():
	npc_id = name
	current_health = max_health
	
	# Get manager references (same pattern as player)
	game_manager = get_tree().get_first_node_in_group("game_manager")
	network_manager = get_tree().get_first_node_in_group("network_manager")
	
	if not game_manager:
		game_manager = get_parent().get_parent().get_node("GameManager")
	
	# Register with network manager if needed
	if requires_network_sync and network_manager:
		network_manager.register_entity(self, npc_id)

func configure_npc(config_data: Dictionary):
	"""Configure NPC with spawn data - override in derived classes"""
	if config_data.has("health"):
		max_health = config_data["health"]
		current_health = max_health
	if config_data.has("speed"):
		movement_speed = config_data["speed"]
	if config_data.has("interactable"):
		is_interactable = config_data["interactable"]

func _physics_process(delta: float):
	if ai_enabled and multiplayer.is_server():
		_update_ai(delta)
	
	if not is_on_floor():
		velocity.y += 980.0 * delta  # Gravity
	
	move_and_slide()

func _update_ai(delta: float):
	"""Override in derived classes for specific AI behavior"""
	ai_timer += delta
	
	match ai_state:
		"idle":
			velocity.x = 0
		"walking":
			var direction = (ai_target - position).normalized()
			velocity.x = direction.x * movement_speed

func interact_with_player(player_node: Node):
	"""Called when player interacts with this NPC"""
	if is_interactable:
		_handle_player_interaction(player_node)

func _handle_player_interaction(player_node: Node):
	"""Override for specific interaction behavior"""
	print("Player interacted with ", npc_type)

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	if multiplayer.is_server() and game_manager:
		game_manager.despawn_npc(npc_id)

func get_npc_data() -> Dictionary:
	"""For persistence/saving"""
	return {
		"npc_type": npc_type,
		"position": position,
		"health": current_health,
		"ai_state": ai_state
	}
```

### 2. Create Specific NPC Types

#### Guard NPC Example

```gdscript
# entities/npcs/npc_guard.gd
extends BaseNPC

@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 25.0
@export var detection_range: float = 100.0
@export var dialogue: String = "Halt! Who goes there?"

var current_patrol_index: int = 0
var patrol_direction: int = 1

func _ready():
	super._ready()
	npc_type = "npc_guard"
	is_interactable = true
	requires_network_sync = true  # Guards move, need sync
	movement_speed = patrol_speed

func configure_npc(config_data: Dictionary):
	super.configure_npc(config_data)
	
	if config_data.has("patrol_points"):
		patrol_points = config_data["patrol_points"]
	if config_data.has("dialogue"):
		dialogue = config_data["dialogue"]
	if config_data.has("detection_range"):
		detection_range = config_data["detection_range"]

func _update_ai(delta: float):
	if patrol_points.size() < 2:
		ai_state = "idle"
		return
	
	ai_state = "patrolling"
	var target_point = patrol_points[current_patrol_index]
	var distance_to_target = position.distance_to(target_point)
	
	if distance_to_target < 10.0:
		# Reached patrol point, move to next
		current_patrol_index += patrol_direction
		
		# Reverse direction at endpoints
		if current_patrol_index >= patrol_points.size():
			current_patrol_index = patrol_points.size() - 2
			patrol_direction = -1
		elif current_patrol_index < 0:
			current_patrol_index = 1
			patrol_direction = 1
	else:
		# Move towards target
		var direction = (target_point - position).normalized()
		velocity.x = direction.x * patrol_speed

func _handle_player_interaction(player_node: Node):
	print("Guard says: ", dialogue)
	# Could trigger dialogue UI, quest system, etc.
```

#### Merchant NPC Example

```gdscript
# entities/npcs/npc_merchant.gd
extends BaseNPC

@export var shop_items: Array[String] = []
@export var greeting: String = "Welcome to my shop!"
@export var gold_amount: int = 1000

func _ready():
	super._ready()
	npc_type = "npc_merchant"
	is_interactable = true
	requires_network_sync = false  # Merchants are stationary
	ai_enabled = false  # No AI needed

func configure_npc(config_data: Dictionary):
	super.configure_npc(config_data)
	
	if config_data.has("shop_items"):
		shop_items = config_data["shop_items"]
	if config_data.has("greeting"):
		greeting = config_data["greeting"]
	if config_data.has("gold"):
		gold_amount = config_data["gold"]

func _handle_player_interaction(player_node: Node):
	print("Merchant says: ", greeting)
	print("Available items: ", shop_items)
	# Could open shop UI interface
```

### 3. Extend GameManager for NPC Spawning

Add these functions to `game_manager.gd`:

```gdscript
# NPC Management (add to existing GameManager)
var npcs = {}  # npc_id -> npc_node  
var next_npc_id: int = 1

func spawn_npc(npc_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String:
	"""Server-authoritative NPC spawning"""
	if not multiplayer.is_server():
		print("WARNING: Only server can spawn NPCs")
		return ""
	
	var npc_id = "npc_" + str(next_npc_id)
	next_npc_id += 1
	
	# Spawn locally first
	_spawn_npc_locally(npc_id, npc_type, spawn_pos, config_data)
	
	# Broadcast to all clients
	rpc("sync_npc_spawn", npc_id, npc_type, spawn_pos, config_data)
	
	print("Spawned NPC: ", npc_type, " with ID: ", npc_id, " at ", spawn_pos)
	return npc_id

func _spawn_npc_locally(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Spawn NPC locally on this client"""
	var npc_scene_path = "res://entities/npcs/" + npc_type + ".tscn"
	
	if not ResourceLoader.exists(npc_scene_path):
		print("ERROR: NPC scene not found: ", npc_scene_path)
		return
	
	var npc = load(npc_scene_path).instantiate()
	npc.name = npc_id
	npc.position = pos
	
	# Configure NPC with spawn data
	if npc.has_method("configure_npc"):
		npc.configure_npc(config)
	
	# Add to spawn container (same as players)
	get_parent().get_node("SpawnContainer").add_child(npc)
	npcs[npc_id] = npc
	
	print("Spawned NPC locally: ", npc_id, " at ", pos)

@rpc("authority", "call_local", "reliable")
func sync_npc_spawn(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary):
	"""Synchronize NPC spawn to clients"""
	if not multiplayer.is_server():
		_spawn_npc_locally(npc_id, npc_type, pos, config)

func despawn_npc(npc_id: String):
	"""Remove NPC (server authority)"""
	if not multiplayer.is_server():
		return
	
	_despawn_npc_locally(npc_id)
	rpc("sync_npc_despawn", npc_id)

func _despawn_npc_locally(npc_id: String):
	"""Remove NPC locally"""
	if npc_id in npcs:
		npcs[npc_id].queue_free()
		npcs.erase(npc_id)
		print("Despawned NPC: ", npc_id)

@rpc("authority", "call_local", "reliable")
func sync_npc_despawn(npc_id: String):
	"""Synchronize NPC despawn to clients"""
	if not multiplayer.is_server():
		_despawn_npc_locally(npc_id)
```

### 4. Extend NetworkManager for NPC Synchronization

Add to `network_manager.gd`:

```gdscript
# NPC Network Management (add to existing NetworkManager)
var tracked_npcs = {}  # npc_id -> npc_data

func register_entity(entity: Node2D, entity_id: String):
	"""Register NPC for network management"""
	var entity_data = {
		"entity": entity,
		"entity_id": entity_id,
		"target_position": entity.position,
		"is_interpolating": false,
		"last_position": entity.position
	}
	
	tracked_npcs[entity_id] = entity_data
	print("NetworkManager: Registered NPC ", entity_id)

func unregister_entity(entity_id: String):
	"""Unregister NPC from network management"""
	if entity_id in tracked_npcs:
		tracked_npcs.erase(entity_id)
		print("NetworkManager: Unregistered NPC ", entity_id)

# Extend _handle_remote_player_smoothing to include NPCs
func _handle_remote_npc_smoothing(delta: float):
	for npc_id in tracked_npcs:
		var npc_data = tracked_npcs[npc_id]
		
		if not npc_data.is_interpolating:
			continue
		
		var npc = npc_data.entity
		var target = npc_data.target_position
		var current_pos = npc.position
		
		# Smooth interpolation
		var new_position = current_pos.lerp(target, interpolation_speed * delta)
		npc.position = new_position
		
		# Stop interpolating when close enough
		if current_pos.distance_to(target) < 0.5:
			npc.position = target
			npc_data.is_interpolating = false
```

### 5. Create NPC Scene Files

#### Basic NPC Guard Scene Structure
```
entities/npcs/npc_guard.tscn:
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://entities/npcs/npc_guard.gd"]
[ext_resource type="Texture2D" path="res://assets/kenney_platformer-art-deluxe/Base pack/Enemies/blockerBody.png"]

[sub_resource type="RectangleShape2D"]
size = Vector2(32, 48)

[node name="npc_guard" type="CharacterBody2D"]
script = ExtResource("1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")

[node name="InteractionArea" type="Area2D" parent="."]

[node name="InteractionShape" type="CollisionShape2D" parent="InteractionArea"]
# Larger area for player interaction
```

### 6. Usage Examples

```gdscript
# Server startup - spawn initial NPCs
func _spawn_initial_world_npcs():
	if not multiplayer.is_server():
		return
	
	# Spawn a patrolling guard
	spawn_npc("npc_guard", Vector2(300, 200), {
		"health": 150,
		"patrol_points": [Vector2(250, 200), Vector2(350, 200), Vector2(300, 250)],
		"dialogue": "I guard this area. Move along!",
		"patrol_speed": 30.0,
		"detection_range": 120.0
	})
	
	# Spawn a merchant
	spawn_npc("npc_merchant", Vector2(500, 180), {
		"shop_items": ["health_potion", "sword", "shield"],
		"greeting": "Welcome, traveler! See my wares!",
		"gold": 1500
	})
	
	# Spawn hostile slime
	spawn_npc("npc_slime", Vector2(400, 300), {
		"health": 50,
		"speed": 40,
		"hostile": true,
		"damage": 10
	})

# Call this from GameManager._ready() if server
if multiplayer.is_server():
	await get_tree().process_frame
	_spawn_initial_world_npcs()
```

## Implementation Timeline

### Phase 1: Foundation (Day 1-2)
1. ✅ Create `entities` folder structure  
2. ✅ Update file path references
3. 📋 Create `BaseNPC` class
4. 📋 Add basic NPC spawning to GameManager

### Phase 2: Basic NPCs (Day 2-3)  
1. 📋 Create `npc_guard.tscn/.gd`
2. 📋 Create `npc_merchant.tscn/.gd`
3. 📋 Test NPC spawning and basic functionality
4. 📋 Implement player-NPC interaction system

### Phase 3: AI and Movement (Day 3-4)
1. 📋 Implement patrol AI for guards
2. 📋 Add network synchronization for moving NPCs
3. 📋 Create hostile NPC with chase behavior
4. 📋 Test multiplayer NPC synchronization

### Phase 4: Polish and Integration (Day 4-5)
1. 📋 Extend WorldManager for NPC persistence
2. 📋 Add NPC save/load functionality
3. 📋 Create debug tools for NPC management
4. 📋 Performance optimization and testing

## Available Sprite Assets Summary

### Ready-to-Use Enemy Types:
- **Slime** (2 walk frames + death) → Simple patrolling enemy
- **Snail** (2 walk frames + shell) → Defensive enemy that hides
- **Fly** (2 fly frames + death) → Flying/hovering enemy
- **Fish** (2 swim frames + death) → Water-based enemy
- **Blocker/Poker** (multiple states) → Stationary guards

### Ready-to-Use NPC Components:
- **Human Characters** (modular body parts) → Town NPCs, merchants
- **Fantasy Characters** (skeleton, zombie, gnome) → Special NPCs
- **Creature Characters** (alien, boar, fox) → Wildlife NPCs

### Interactive Items Available:
- Collectibles (coins, gems, keys)  
- Interactive objects (buttons, switches, doors)
- Environment items (mushrooms, plants, rocks)

## Key Architecture Benefits

### ✅ **Consistent with Current System**
- Uses same manual spawning pattern as players
- Maintains server authority for all entities  
- Reuses SpawnContainer organization
- Follows established RPC patterns

### ✅ **Network Efficient**
- Optional network sync (stationary NPCs don't need it)
- Reuses player position smoothing system
- Server-authoritative AI prevents desync

### ✅ **Easily Extensible**
- Base class provides common functionality
- Simple inheritance for new NPC types
- Configuration-based spawning system
- Plugin-like architecture

### ✅ **Rich Asset Foundation**
- Professional sprite assets included
- Multiple animation frames available
- Consistent art style maintained
- Ready for immediate implementation

## Next Steps

1. **Create the base NPC class** following the structure above
2. **Extend GameManager** with NPC spawning functions  
3. **Create your first NPC type** (recommend starting with stationary merchant)
4. **Test basic spawning** in multiplayer environment
5. **Add AI behaviors** for dynamic NPCs
6. **Implement player interactions** and dialogue systems

The project is now **fully prepared** for NPC implementation with a solid architectural foundation and rich asset library ready for use.