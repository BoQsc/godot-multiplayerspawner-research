# Project State Documentation

## Current Architecture Overview

### **Scene Structure**
```
Node2D (main scene root)
├── GameManager (Node, groups: ["game_manager"])
├── NetworkManager (Node, groups: ["network_manager"])  
├── WorldManager (Node2D, groups: ["world_manager"])
├── SpawnContainer (Node2D, groups: ["spawn_container"])
├── UserIdentity (Node, groups: ["user_identity"])
├── Register (Node, groups: ["register_system"])
├── Login (Node, groups: ["login_system"])
└── UILayer (CanvasLayer)
```

### **Core Systems**

#### **1. Player Spawning Flow**
```
1. GameManager._spawn_player(peer_id, pos, persistent_id)
2. Instantiate player_entity.tscn
3. Set player.name = str(peer_id)
4. Add to SpawnContainer via get_parent().get_node("SpawnContainer").add_child(player)
5. Set multiplayer authority: player.set_multiplayer_authority(peer_id)
6. Store in players[peer_id] dictionary
```

#### **2. Network Update Flow**
```
PlayerEntity (local) → _send_network_update() → rpc("sync_player_position") → PlayerEntity (remote)
```

#### **3. Multiplayer Authority System**
- Each player has authority over their own PlayerEntity node
- RPCs use "any_peer" configuration to allow peer-to-peer communication
- Authority set after scene tree insertion to prevent path resolution issues

## Current Issues

### **🔴 CRITICAL: Node Path Resolution Failure**
**Error**: `get_node: Node not found: "Node2D/SpawnContainer/1"`
**Cause**: Multiplayer system trying to resolve RPC target paths before nodes are properly registered
**Impact**: RPC calls fail, breaking player position synchronization

### **Network Systems**
1. **Primary**: PlayerEntity direct RPC system (`sync_player_position`)
2. **Secondary**: NetworkManager → GameManager system (`update_player_position`) 
3. **Issue**: Two systems may conflict or create redundant network traffic

## File States

### **game_manager.gd**
- **Lines 960-977**: Player spawning logic
- **Key Functions**: `_spawn_player()`, `_despawn_player()`
- **RPC Methods**: `update_player_position()`, `spawn_player()`, `despawn_player()`
- **Recent Changes**: Authority timing fix (add_child before set_authority)

### **entities/players/player_entity.gd**
- **Lines 123-147**: Network update timing and RPC calls
- **Lines 201-207**: `sync_player_position` RPC handler
- **Key Properties**: `is_local_player`, `player_id`, `network_update_timer`
- **Recent Changes**: RPC authority changed from "authority" to "any_peer"

### **network_manager.gd**
- **Purpose**: Rate limiting and position management
- **Key Functions**: `register_player()`, `report_local_movement()`
- **Update Rate**: 60Hz (vs PlayerEntity's 120Hz)
- **Integration**: May be underutilized vs direct PlayerEntity RPCs

## Working Systems

### **✅ Player Authentication & Persistence**
- UserIdentity system manages device binding
- Player data persists across sessions
- World data saves/loads correctly

### **✅ World Management**
- Terrain modification system
- NPC spawning and persistence  
- Pickup system with server authority

### **✅ UI Systems**
- F1-F12 debug controls
- Device binding interface
- Player list and connection UI

## Problem Analysis

### **Root Cause: Multiplayer Path Registration Timing**
The Godot multiplayer system registers node paths when:
1. `set_multiplayer_authority()` is called
2. Node must be in scene tree for proper path registration
3. RPC calls before proper registration cause path resolution failures

### **Current Fix Attempts**
1. ✅ Moved authority setting after `add_child()`
2. ✅ Added initialization delays and safety checks
3. ❌ Still experiencing path resolution failures

### **Likely Issues**
1. **RPC Timing**: RPCs may fire before multiplayer system fully processes authority
2. **Scene Tree Readiness**: Node may need additional frames for proper registration
3. **Authority Conflicts**: Multiple authority systems may interfere

## Immediate Action Items

### **1. Investigate Path Resolution Timing**
- Add debugging to track when authority is set vs when RPCs fire
- Monitor multiplayer system state during spawn sequence
- Test with longer delays between authority setting and RPC activation

### **2. Validate Network Architecture**
- Determine if dual network systems are necessary
- Consolidate to single authoritative network flow
- Remove redundant or conflicting RPC systems

### **3. Test Multiplayer Readiness**
- Verify `multiplayer.get_unique_id()` returns valid values
- Check `multiplayer.is_server()` state consistency  
- Ensure peer connection status before RPC calls

## Technical Debt

### **Network Architecture Confusion**
- PlayerEntity has direct RPC system
- NetworkManager provides separate rate limiting
- GameManager has third RPC pathway
- Unclear which system should be primary

### **Manual Node Management**
- Manual scene tree manipulation vs MultiplayerSpawner
- Custom authority timing vs built-in systems
- Potential for timing edge cases

### **Error Handling**
- Limited validation of multiplayer state
- Missing graceful degradation for connection issues
- Insufficient logging for debugging network problems

## Success Metrics

### **For Fixing Current Issues**
- [ ] Zero node path resolution errors
- [ ] Consistent player position synchronization
- [ ] Clean multiplayer logs without C++ errors

### **For Long-term Stability**
- [ ] Single, well-defined network architecture
- [ ] Robust error handling and recovery
- [ ] Scalable to 10+ concurrent players

## Notes
- Project uses Godot 4.x multiplayer system
- ENetMultiplayerPeer for networking
- Custom player persistence and world management
- Mixed approach of manual spawning + multiplayer authority