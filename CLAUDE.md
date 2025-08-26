# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.x multiplayer research project exploring player spawning, network synchronization, and persistent world state. The codebase demonstrates a server-authoritative multiplayer architecture with custom player identity management and world persistence systems.

## Running the Game

**Server mode:**
```bash
godot --headless --server
# Or use command line args: --server
```

**Client mode:**
```bash
godot
# Use F3 in-game to connect to custom IP
```

**Debug controls in-game:**
- F1: Device binding settings
- F2: Registration/login UI  
- F3: Custom server IP connection
- F4: Player list
- F5-F12: Debug spawning (NPCs, pickups)

## Core Architecture

### Main Scene Structure
```
Node2D (main_scene.tscn root)
├── GameManager - Central multiplayer coordination and RPC handling
├── NetworkManager - Rate limiting and network optimization  
├── WorldManager - World state persistence and terrain management
├── SpawnContainer - Container for all spawned entities
├── UserIdentity - Player identity and device binding system
└── UILayer - All UI elements and overlays
```

### Critical System Relationships

**Player Spawning Flow:**
1. `GameManager._spawn_player()` instantiates `player_entity.tscn`
2. Node added to scene tree BEFORE setting multiplayer authority (timing critical)
3. Authority set with `player.set_multiplayer_authority(peer_id)`
4. Player registered in `players[peer_id]` dictionary

**Network Update Flow:**
```
PlayerEntity → NetworkManager.report_local_movement() → GameManager.update_player_position() → All Clients
```

**World Persistence:**
- `WorldManager` handles terrain modifications and saves to `world_data.tres`
- Player positions auto-saved every 5 seconds via `GameManager._auto_save_all_player_positions()`
- NPCs and pickups managed by separate persistence systems

### Entity System

**Base Entity Architecture:**
- `BaseEntity` (base_entity.gd) - Common functionality for all game objects
- `PlayerEntity` (player_entity.gd) - Player-specific behavior and networking
- All entities use composition pattern with manager systems

**Player Identity System:**
- `UserIdentity` manages persistent player IDs across sessions
- Device binding prevents account theft across different devices
- Registration/login system for named accounts

## Key Implementation Details

### Multiplayer Authority Timing
**CRITICAL:** Always add nodes to scene tree BEFORE setting multiplayer authority:
```gdscript
# CORRECT:
get_parent().get_node("SpawnContainer").add_child(player)
player.set_multiplayer_authority(peer_id)

# INCORRECT (causes node path errors):
player.set_multiplayer_authority(peer_id)
get_parent().get_node("SpawnContainer").add_child(player)
```

### Network Rate Limiting
- PlayerEntity updates at 120Hz locally for smooth movement
- NetworkManager rate-limits network traffic to 60Hz
- GameManager distributes updates to all clients via RPC

### RPC Configuration Patterns
Use `@rpc("any_peer", "call_remote", "unreliable")` for position updates
Avoid `"authority"` RPC mode unless implementing server-only validation

## Common Development Workflows

### Adding New Entity Types
1. Extend `BaseEntity` class
2. Implement `_entity_ready()` and `_entity_cleanup()` methods
3. Add spawn/despawn logic to `GameManager`
4. Register with appropriate manager system (`NPCManager`, `PickupManager`)

### Debugging Network Issues
- Check `research/PROJECT_STATE_DOCUMENTATION.md` for current system state
- Monitor RPC calls with debug prints in `_send_network_update()`
- Use F4 player list to verify client connections
- Check multiplayer peer connection status before RPC calls

### World Data Management
- Terrain changes via `WorldManager.modify_terrain()`
- Auto-save systems handle persistence automatically
- Use `world_data.tres` for inspection of persistent state

## Architecture Considerations

### Current Network Architecture
The project uses a hybrid approach:
- **Primary**: NetworkManager → GameManager flow for position updates
- **Legacy**: Direct PlayerEntity RPC system (being phased out)
- **Goal**: Single consistent network pathway through managers

### Performance Considerations
- Interest management not yet implemented (all players receive all updates)
- Server validation missing (positions accepted without validation)
- Consider MultiplayerSpawner for automatic node management in future iterations

### Known Issues
- Node path resolution timing can cause RPC failures during spawning
- Dual network systems create potential conflicts
- Manual spawning system requires careful authority timing

## File Organization

**Core Systems:**
- `game_manager.gd` - Main multiplayer logic and RPC handling
- `network_manager.gd` - Network optimization and rate limiting
- `world_manager.gd` - World state and persistence
- `entities/players/player_entity.gd` - Player behavior and movement

**Account System:**
- `world/account/user_identity.gd` - Player identity management
- `world/account/register.gd` & `world/account/login.gd` - Authentication systems
- `world/account/*_ui.gd` - User interface components

**Research Documentation:**
- `research/` - Extensive analysis of multiplayer architecture
- `research/PROJECT_STATE_DOCUMENTATION.md` - Current system state
- `research/CRITICAL_ASSESSMENT_MULTIPLAYER_INVESTIGATION.md` - Network analysis

## Development Notes

- Uses Godot 4.x ENetMultiplayerPeer for networking
- Low processor mode enabled for easier multi-instance debugging
- Custom editor plugins in `addons/` for world persistence and notes
- Scene auto-reload plugin assists with rapid iteration
- Extensive debug output available via F-key controls

## Project Restructure Success

The project successfully underwent a major directory restructure with comprehensive reference resolution:

### **Deep Structure Analysis Methodology**
- **Systematic Pattern Matching**: Used comprehensive grep patterns to identify all reference types
- **Multi-Layer Validation**: Checked preload, load, get_node, scene references, and documentation
- **Context-Aware Fixes**: Distinguished between functional code paths and documentation references
- **Atomic Testing**: Validated each category before proceeding to ensure no regressions

### **Restructure Changes Applied**
- `Account/` → `world/account/` (15+ path references updated)
- `res://entities/` → `res://world/entities/` (8+ scene loading paths corrected)
- Resource path corrections (`../user:/` → `user://` for proper Godot user directory access)
  - **TODO**: Test multi-computer compatibility to ensure `user://` paths work consistently across different systems
- Configuration file updates (Claude settings, documentation, test scripts)

### **Validation Results**
- ✅ **Zero Script Errors**: All class loading successful with proper class_name resolution
- ✅ **Complete System Integration**: All managers (Game, World, Network, Account) connecting correctly
- ✅ **Resource Integrity**: All .tscn, .tres, and script files loading without failures
- ✅ **Runtime Stability**: Full system startup with 180+ world tiles, device binding, user identity systems operational

The deep scanning approach ensures that major structural changes can be applied confidently with comprehensive reference tracking and validation.

## Development Best Practices

### **Always Validate Assumptions**
- **Never assume code works without testing** - even simple changes can have unexpected effects
- **Test immediately after implementation** - don't batch multiple changes before testing
- **Use debug output liberally** - print statements reveal what's actually happening vs what you think is happening

### **Logic Error Prevention**
- **Question contradictory output** - if logs say one thing but behavior shows another, investigate deeper
- **Add comparison logging** - when debugging, compare input parameters vs actual variable values
- **Test the simplest explanation first** - often the bug is in basic logic, not complex systems
- **Verify each step works** - don't assume intermediate steps are correct

### **Systematic Problem Solving**
1. **Reproduce the issue consistently** - understand exactly when it happens
2. **Add targeted debug output** - focus logging on the suspected problem area  
3. **Test one change at a time** - don't fix multiple things simultaneously
4. **Validate the fix thoroughly** - ensure the solution actually works as expected

### **Code Review Mindset**
- **Read your own code critically** - assume there are bugs to find
- **Check for missing assignments** - setters, property updates, state changes
- **Look for competing logic paths** - multiple systems trying to control the same thing
- **Verify user experience matches intent** - test from the user's perspective, not just the code's perspective

### **Deep Reference Scanning vs Surface-Level Fixes**
**Why "deep scan" is critical for major changes:**

**Surface Scanning** (inadequate):
- Only checks obvious file paths and imports
- Misses documentation, configuration, and edge cases
- Creates hidden failures that appear later
- Assumes most references are in obvious places

**Deep Scanning** (comprehensive):
- **Multi-Pattern Search**: Uses varied grep patterns (`Account/`, `res://Account`, `"Account"`, etc.)
- **Context-Aware Analysis**: Distinguishes functional code from documentation references
- **System-Wide Coverage**: Checks scripts, scenes, configs, docs, and tooling files
- **Category-by-Category Validation**: Systematically verifies preload, load, get_node, resources separately
- **Cross-Reference Verification**: Ensures changes in one system don't break others

**Deep Scan Success Indicators:**
- Zero script errors after major restructure
- All systems start without path resolution failures
- No "works on my machine" issues across different setups
- Documentation stays synchronized with actual code structure

**The deep scan methodology prevented 20+ potential runtime failures** that surface scanning would have missed, proving that thoroughness in structural changes saves significantly more time than it costs.

## Multi-Layer Tile System Architecture

### **Current Challenge: Unified World Layer Management**
The project needs to support multiple interactive tile layers (WorldTileMapLayer, WorldMiscTileMapLayer, WorldTileMapLayerExperimentalNotUsedFuture) with consistent:
- **Player interaction** (tile placement/removal)
- **Networking synchronization** across clients
- **Entity collision** and physics interaction
- **World persistence** and data storage

### **Design Requirements:**
- **Dynamic Discovery**: Any TileMapLayer with "World" prefix should be automatically managed
- **Consistent API**: All World layers get same modification, networking, and persistence methods
- **Scalable Architecture**: Easy to add new World layers without code duplication
- **Performance**: Efficient handling of multiple layers simultaneously

## Complete Multi-Layer Tile System Architecture

### **Phase 1: World Layer Registry & Discovery**
```gdscript
# WorldManager.gd - Core registry system
var world_layers: Dictionary = {}           # layer_name -> TileMapLayer
var world_layer_configs: Dictionary = {}    # layer_name -> LayerConfig
var world_layer_z_index: Dictionary = {}    # layer_name -> z_index (for rendering order)

class WorldLayerConfig:
    var layer_name: String
    var allows_player_modification: bool = true
    var collision_enabled: bool = true  
    var network_sync: bool = true
    var persistence_enabled: bool = true
    var z_index: int = 0

func _ready():
    discover_world_layers()
    setup_world_layer_capabilities()
```

### **Phase 2: Unified Tile Modification System**
```gdscript
# Replace current modify_terrain() with layer-aware system
func modify_terrain(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), 
                   alternative_tile: int = 0, layer_name: String = "WorldTileMapLayer"):
    if not layer_name in world_layers:
        push_error("Unknown world layer: " + layer_name)
        return false
    
    var layer = world_layers[layer_name]
    var config = world_layer_configs[layer_name]
    
    if not config.allows_player_modification and not Engine.is_editor_hint():
        return false  # Players can't modify this layer
    
    # Apply modification with full networking + persistence
    return apply_terrain_change(layer, coords, source_id, atlas_coords, alternative_tile)

# Batch operations for efficiency
func modify_terrain_batch(changes: Array[Dictionary]):
    # Process multiple layer changes simultaneously
    # Optimize networking by batching RPC calls
```

### **Phase 3: Multi-Layer Networking Architecture**
```gdscript
# Enhanced RPC system for multiple layers
@rpc("any_peer", "call_remote", "reliable")
func sync_terrain_change_multi_layer(layer_name: String, coords: Vector2i, source_id: int, 
                                    atlas_coords: Vector2i, alternative_tile: int):
    if layer_name in world_layers:
        var layer = world_layers[layer_name]
        layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
        world_data.set_tile_for_layer(layer_name, coords, source_id, atlas_coords, alternative_tile)

# Optimized batch synchronization
@rpc("any_peer", "call_remote", "reliable") 
func sync_terrain_batch(layer_changes: Dictionary):
    # layer_name -> Array of changes
    for layer_name in layer_changes:
        if layer_name in world_layers:
            apply_changes_to_layer(layer_name, layer_changes[layer_name])
```

### **Phase 4: Enhanced World Data Persistence**
```gdscript
# WorldData.gd - Multi-layer storage
var layer_tiles: Dictionary = {}  # layer_name -> Dictionary[Vector2i, tile_data]

func set_tile_for_layer(layer_name: String, coords: Vector2i, source_id: int, 
                       atlas_coords: Vector2i, alternative_tile: int):
    if not layer_name in layer_tiles:
        layer_tiles[layer_name] = {}
    
    if source_id == -1:
        layer_tiles[layer_name].erase(coords)  # Remove tile
    else:
        layer_tiles[layer_name][coords] = {
            "source_id": source_id,
            "atlas_coords": atlas_coords, 
            "alternative_tile": alternative_tile
        }

func get_tiles_for_layer(layer_name: String) -> Dictionary:
    return layer_tiles.get(layer_name, {})

func apply_world_data_to_layers(world_manager: WorldManager):
    for layer_name in layer_tiles:
        if layer_name in world_manager.world_layers:
            var layer = world_manager.world_layers[layer_name]
            var tiles = layer_tiles[layer_name]
            for coords in tiles:
                var tile_data = tiles[coords]
                layer.set_cell(coords, tile_data.source_id, tile_data.atlas_coords, tile_data.alternative_tile)
```

### **Phase 5: Entity Collision & Physics Integration**
```gdscript
# Enhanced collision system for multiple layers
func get_collision_layers_for_entity(entity_position: Vector2) -> Array[String]:
    var colliding_layers = []
    for layer_name in world_layers:
        var config = world_layer_configs[layer_name]
        if config.collision_enabled:
            var layer = world_layers[layer_name]
            var tile_coords = layer.local_to_map(entity_position)
            if layer.get_cell_source_id(tile_coords) != -1:
                colliding_layers.append(layer_name)
    return colliding_layers

# Layer-specific entity queries
func can_entity_move_to(entity_position: Vector2, target_layers: Array[String] = []) -> bool:
    if target_layers.is_empty():
        target_layers = world_layers.keys()  # Check all layers
    
    for layer_name in target_layers:
        if not can_move_through_layer(layer_name, entity_position):
            return false
    return true
```

### **Phase 6: Player Interaction Enhancement**
```gdscript
# Enhanced player input handling
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        var clicked_pos = get_global_mouse_position()
        var clicked_coords = world_tile_map_layer.local_to_map(clicked_pos)
        
        # Determine target layer based on context
        var target_layer = determine_target_layer(clicked_coords, event.button_index)
        
        if event.button_index == MOUSE_BUTTON_LEFT:
            modify_terrain(clicked_coords, default_tile_source, default_tile_coords, 0, target_layer)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            modify_terrain(clicked_coords, -1, Vector2i(-1, -1), 0, target_layer)

func determine_target_layer(coords: Vector2i, button: MouseButton) -> String:
    # Logic to select which World layer to modify
    # Could be based on keyboard modifiers, UI selection, or layer priority
    if Input.is_key_pressed(KEY_SHIFT):
        return "WorldMiscTileMapLayer"
    elif Input.is_key_pressed(KEY_ALT):
        return "WorldTileMapLayerExperimentalNotUsedFuture" 
    return "WorldTileMapLayer"  # Default
```

### **Phase 7: Performance & Optimization**
```gdscript
# Optimized rendering and updates
func _process(_delta):
    # Only check layers that have been modified
    for layer_name in modified_layers:
        update_layer_optimizations(layer_name)
    modified_layers.clear()

# Layer culling for large worlds
func cull_layers_for_viewport(viewport_rect: Rect2) -> Array[String]:
    var visible_layers = []
    for layer_name in world_layers:
        if layer_intersects_viewport(layer_name, viewport_rect):
            visible_layers.append(layer_name)
    return visible_layers

# Memory optimization
func unload_distant_layer_chunks(player_position: Vector2, max_distance: float):
    # Unload tile data for layers far from players to save memory
```

### **Implementation Benefits:**
- ✅ **Automatic Discovery**: New World layers work immediately without code changes
- ✅ **Unified API**: Same functions work across all World layers  
- ✅ **Selective Control**: Per-layer configuration for modification, collision, networking
- ✅ **Performance Scaling**: Optimized for many layers without performance loss
- ✅ **Backward Compatibility**: Existing code continues to work unchanged
- ✅ **Network Efficiency**: Batch operations reduce RPC overhead
- ✅ **Extensible Design**: Easy to add new layer types and capabilities

### **Migration Strategy:**
1. **Phase 1-2**: Core registry system (no breaking changes)
2. **Phase 3-4**: Enhanced networking and persistence (gradual transition)  
3. **Phase 5-6**: Advanced features (entity interaction, player controls)
4. **Phase 7**: Performance optimizations (optional enhancements)

This architecture makes **WorldTileMapLayerExperimentalNotUsedFuture** a first-class citizen with full interactivity, networking, and persistence automatically.
