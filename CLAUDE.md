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
- `Account/user_identity.gd` - Player identity management
- `Account/register.gd` & `Account/login.gd` - Authentication systems
- `Account/*_ui.gd` - User interface components

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
