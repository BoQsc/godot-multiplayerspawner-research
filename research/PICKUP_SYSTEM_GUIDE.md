# Pickup System - Complete Implementation Guide

## ✅ System Status: PRODUCTION READY

The pickup/item system has been fully implemented and integrated with the existing entity architecture. All collectible objects in the world are now entities that extend BaseEntity, providing consistent persistence, networking, and management.

---

## 🏗️ Architecture Overview

### Inheritance Hierarchy
```
BaseEntity
├── PlayerEntity (players)
├── TestNPC (NPCs)
└── PickupEntity (base for all collectible items)
    └── HealthPotion (specific item type)
```

### Core Components

**1. PickupEntity (entities/pickups/pickup_entity.gd)**
- Base class for all collectible items
- Handles pickup detection and interaction
- Provides save/restore functionality for persistence
- Network synchronization for collection state

**2. HealthPotion (entities/pickups/health_potion.gd)**
- Example implementation extending PickupEntity
- Heals players when collected
- Only allows pickup if player is injured

**3. WorldData Integration**
- PickupData class for structured item storage
- Dictionary management: `pickup_data`
- Persistence functions: `save_pickup()`, `get_pickup()`, `remove_pickup()`

**4. GameManager Integration**
- Pickup spawning: `spawn_pickup()`, `despawn_pickup()`
- Network synchronization via RPC
- Auto-save integration (every 5 seconds)

**5. WorldManager Integration**
- `save_pickups()` - Save all pickups to persistent storage
- `load_pickups()` - Restore pickups on server startup
- Auto-save coordination

---

## 🎮 How the System Works

### Pickup Lifecycle

1. **Spawning**
   ```gdscript
   game_manager.spawn_pickup("health_potion", Vector2(300, 100), {"healing_amount": 25})
   ```

2. **Detection** - PickupEntity uses Area2D for collision detection
   - 30-pixel radius by default (`auto_pickup_radius`)
   - Only detects PlayerEntity collisions

3. **Collection** - Server-authoritative pickup logic
   - Calls `_can_be_picked_up()` for conditional logic
   - Applies item effect via `_apply_pickup_effect()`
   - Synchronizes collection state to all clients

4. **Persistence** - Automatic save/restore
   - Items save collection state, respawn timers
   - Respawn items automatically restore after specified time
   - Non-respawn items are removed from world permanently

### Network Authority

- **Server**: Handles all pickup logic, collection, respawning
- **Clients**: Receive synchronized collection/respawn events
- **RPCs**: `sync_pickup_collected`, `sync_pickup_respawned`

---

## 🛠️ Creating New Pickup Types

### Step 1: Create .tscn Scene File

Create a new scene file inheriting from `PickupEntity.tscn`:
```
[gd_scene load_steps=4 format=3]
[ext_resource type="PackedScene" path="res://entities/pickups/PickupEntity.tscn" id="1"]
[ext_resource type="Script" path="res://entities/pickups/magic_orb.gd" id="2"]  
[ext_resource type="Texture2D" path="res://assets/.../magic_orb.png" id="3"]

[node name="MagicOrb" instance=ExtResource("1")]
script = ExtResource("2")

[node name="Sprite2D" parent="." index="0"]
texture = ExtResource("3")
```

### Step 2: Create New Pickup Class

```gdscript
extends PickupEntity
class_name MagicOrb

@export var mana_restore: float = 50.0

func _entity_ready():
    item_type = "magic_orb"
    pickup_value = mana_restore
    super._entity_ready()

func _can_be_picked_up(player: PlayerEntity) -> bool:
    # Only allow pickup if player needs mana
    return player.current_mana < player.max_mana

func _apply_pickup_effect(player: PlayerEntity):
    player.restore_mana(mana_restore)
    print("Magic orb restored ", mana_restore, " mana to ", player.player_id)

func get_save_data() -> Dictionary:
    var base_data = super.get_save_data()
    base_data["mana_restore"] = mana_restore
    return base_data
```

### Step 3: Add to GameManager Spawning

No changes needed! The system automatically loads .tscn files:
```gdscript
# GameManager automatically handles: magic_orb.tscn
spawn_pickup("magic_orb", position, config_data)
```

### Step 4: Handle in WorldManager Loading

```gdscript
# In WorldManager.load_pickups()
elif item_type == "magic_orb":
    config_data["mana_restore"] = pickup_data.get("pickup_value", 50.0)
```

---

## 📊 Pickup Configuration Options

### Basic Properties
- `item_type`: String identifier for the pickup type
- `pickup_value`: Numeric value (healing, damage, points, etc.)
- `auto_pickup_radius`: Detection radius in pixels (default: 30)
- `respawn_time`: Auto-respawn delay in seconds (0 = no respawn)

### Advanced Features
- **Conditional Pickup**: Override `_can_be_picked_up()` for requirements
- **Custom Effects**: Override `_apply_pickup_effect()` for unique behavior
- **Visual Feedback**: Override `_play_healing_effect()` for audio/visual
- **Configuration Data**: Pass custom parameters via `config_data`

### Example Configurations

```gdscript
# Health Potion - basic healing
{"healing_amount": 25}

# Respawning Power-up - respawns every 30 seconds
{"power_boost": 2.0, "respawn_time": 30.0}

# Rare Item - large pickup radius, no respawn
{"auto_pickup_radius": 60.0, "respawn_time": 0.0}
```

---

## 🎯 Debug Controls

### Available Commands
- **F9**: Spawn health potion (red mushroom) at (300, 100)
- **F10**: List all current pickups with status
- **F11**: Spawn star item (golden star) at (400, 100)
- **F12**: Spawn blue gem at (500, 100)
- **World Info**: F-key command shows pickup count in world data

### Visual Assets Used
- **Health Potion**: `mushroomRed.png` - Classic red mushroom for healing
- **Star Item**: `star.png` - Golden star for special/valuable items  
- **Blue Gem**: `gemBlue.png` - Blue gemstone for collectible currency

### Debug Output Examples
```
=== PICKUP DEBUG INFO ===
Total Pickups: 2
- pickup_1 (health_potion) at (300, 100) - Available
- pickup_2 (health_potion) at (400, 150) - Collected
=========================

Auto-saved 2 pickups to file
WorldManager: Saved 2 pickups to persistent storage
```

---

## 💾 Persistence System

### Data Structure
Each pickup saves the following data:
```json
{
  "item_id": "pickup_1",
  "item_type": "health_potion", 
  "position": {"x": 300, "y": 100},
  "pickup_value": 25.0,
  "respawn_time": 0.0,
  "is_collected": false,
  "respawn_timer": 0.0,
  "config_data": {
    "healing_amount": 25.0,
    "auto_pickup_radius": 30.0
  }
}
```

### Auto-Save Integration
- Pickups auto-save every 5 seconds with players and NPCs
- Collection state, respawn timers preserved across sessions
- Respawning items continue their timers after server restart

### Startup Restoration
1. WorldManager loads pickup data from save file
2. Spawns pickups at saved positions with saved configuration
3. Restores collection state and respawn timers
4. Items resume normal behavior (available/collected/respawning)

---

## 🔧 Technical Implementation Details

### Area2D Collision Detection
```gdscript
func _setup_pickup_area():
    pickup_area = Area2D.new()
    var collision_shape = CollisionShape2D.new()
    var circle_shape = CircleShape2D.new()
    circle_shape.radius = auto_pickup_radius
    collision_shape.shape = circle_shape
    pickup_area.add_child(collision_shape)
    pickup_area.body_entered.connect(_on_pickup_area_entered)
```

### Server Authority Pattern
```gdscript
func _on_pickup_area_entered(body):
    if not multiplayer.is_server() or is_collected:
        return
    
    if body is PlayerEntity:
        _attempt_pickup(body as PlayerEntity)
```

### Client Synchronization
```gdscript
@rpc("authority", "call_local", "reliable")
func sync_pickup_collected(player_id: int):
    if not multiplayer.is_server():
        is_collected = true
        _set_item_visibility(false)
```

---

## 📈 Performance Considerations

### Optimizations Implemented
- **Single Timer System**: Respawn timers run only on server
- **Event-Driven**: Pickups only process when players are nearby
- **Batch Saving**: All pickups save together during auto-save cycles
- **Efficient Networking**: Only broadcast state changes, not continuous updates

### Scaling Recommendations
- **Large Worlds**: Consider spatial partitioning for pickup detection
- **Many Items**: Implement pickup pooling for frequently spawned/despawned items
- **Network**: Batch pickup collections if many items collected simultaneously

---

## 🧪 Testing Scenarios

### Basic Functionality
1. **Spawn Test**: F9 to spawn health potion, verify it appears
2. **Collection Test**: Walk player into potion, verify healing and collection
3. **Persistence Test**: F7 save, restart server, verify potion restores correctly

### Advanced Scenarios
1. **Injured Player**: Damage player, verify only injured players can collect health potions
2. **Network Sync**: Multiple clients, verify pickup collection syncs to all players
3. **Respawn Test**: Create respawning item, wait for respawn timer, verify restoration

### Performance Testing
1. **Many Pickups**: Spawn 50+ items, verify smooth auto-save and loading
2. **Rapid Collection**: Collect many items quickly, verify network stability
3. **Long Sessions**: Run server for extended periods, verify respawn timers work correctly

---

## 🎯 Future Enhancements

### Immediate Opportunities
- **Visual Polish**: Particle effects for pickup collection
- **Audio Integration**: Sound effects for different item types  
- **Item Scenes**: .tscn files for complex items with animations
- **Sprite Integration**: Use Kenney item sprite sheets for visual variety

### Advanced Features
- **Inventory System**: Player storage for collected items
- **Item Stacking**: Multiple copies of the same item type
- **Crafting Integration**: Items as crafting materials
- **Quest Items**: Special items for quest systems
- **Rarities**: Common/rare/legendary item classifications

---

## ✅ System Benefits

### For Developers
- **Consistent Architecture**: All world objects extend BaseEntity
- **Easy Extension**: Simple inheritance pattern for new item types
- **Robust Persistence**: Automatic save/restore with world data
- **Network Ready**: Built-in multiplayer synchronization

### For Players
- **Reliable Interaction**: Server-authoritative pickup prevents desync
- **Persistent World**: Items remain where placed across sessions
- **Smooth Multiplayer**: Real-time collection updates for all players
- **Respawning Resources**: Renewable items for ongoing gameplay

---

**The pickup system is production-ready and provides a solid foundation for any item-based gameplay mechanics. All components integrate seamlessly with the existing entity, persistence, and network architecture.**