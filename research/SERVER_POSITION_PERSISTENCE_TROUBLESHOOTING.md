# Server Position Persistence Troubleshooting Guide

## Issue Overview

**Problem**: Server players using `--server --player <identifier>` spawn at starting position instead of last saved location after restart.

**Root Cause**: Server client mappings with "server_" prefix were not being persisted to `world_data.tres`, causing returning servers to be treated as "NEW" players instead of "EXISTING" ones.

## Symptoms

- Server starts successfully with chosen player identifier
- Player can move around and auto-save works (every 5 seconds)
- After server restart, player spawns at default position (100, 100) instead of saved location
- Debug output shows "NEW" instead of "EXISTING" for returning players
- `client_to_player_mapping` in world_data.tres contains only "client_" prefixed entries

## Technical Details

### Expected Flow
1. Server starts with `--server --player <identifier>`
2. `UserIdentity` generates server client ID: `server_<uuid>`
3. `GameManager._register_player_with_client_id()` calls `world_data.register_client()`
4. Client mapping saved: `"server_<uuid>" -> "player_<identifier>"`
5. On restart, mapping is found and saved position is loaded

### Broken Flow (Before Fix)
1. Server client mapping was set in memory: `client_to_player_mapping[client_id] = persistent_id`
2. Player data was created and saved: `save_player(persistent_id, position)`
3. **BUG**: Client mapping was not immediately persisted to disk
4. On restart, server client ID not found in `client_to_player_mapping`
5. System creates new player instead of loading existing one

## Resolution Applied

### Primary Fix: Immediate Save After Registration

**File**: `game_manager.gd` lines 1347-1349 and 1340-1342

**Change**:
```gdscript
# BEFORE:
return world_manager.world_data.register_client(client_id, peer_id, chosen_player_num, chosen_player_id)

# AFTER:
var persistent_id = world_manager.world_data.register_client(client_id, peer_id, chosen_player_num, chosen_player_id)
world_manager.save_world_data()  # Save immediately to persist client mapping
return persistent_id
```

### Secondary Fix: Enhanced String Player ID Support

**File**: `user_identity.gd` lines 46-61

**Added**: `get_chosen_player_id_from_args()` function to handle non-numeric player identifiers.

## Verification Steps

### 1. Test Position Persistence
```bash
# Start server with custom player
"path\to\godot.exe" --headless --server --player testplayer123

# Wait for auto-save (6+ seconds), then stop server
# Restart with same command - should spawn at last position, not (100, 100)
```

### 2. Check Debug Output
Look for these patterns in console output:
```
=== REGISTER_CLIENT CALLED ===
Client ID: server_<uuid>
Peer ID: 1
Chosen player id: testplayer123

DEBUG: Set client mapping: server_<uuid> -> player_testplayer123
DEBUG: Final mapping contains our client: true

Registered new client: server_<uuid> (peer 1) -> persistent ID player_testplayer123 (NEW)
# On restart:
Registered returning client: server_<uuid> (peer 1) -> persistent ID player_testplayer123 (EXISTING)
```

### 3. Inspect Saved Data
Check `world_data.tres` for server client mappings:
```bash
grep "server_" "C:\Users\<user>\AppData\Roaming\Godot\app_userdata\godot-multiplayerspawner-research\world_data.tres"
```

Should contain entries like:
```
"server_<uuid>": "player_testplayer123"
```

## Troubleshooting Similar Issues

### If Position Persistence Still Fails

1. **Check Client Mapping Creation**
   - Add debug output in `world_data.gd` `register_client()` function
   - Verify `client_to_player_mapping[client_id] = persistent_id` is executed

2. **Check Save Operation**
   - Verify `world_manager.save_world_data()` is called after registration
   - Check for ResourceSaver.save() errors in console

3. **Check File Persistence**
   - Manually inspect `world_data.tres` after server shutdown
   - Look for your specific server client ID in `client_to_player_mapping`

4. **Check Player Data Integrity**
   - Verify player data exists: search for `"player_<identifier>"` in world_data.tres
   - Check position values are not default (100, 100)

### Common Variations of This Issue

1. **Client Position Persistence**: Similar issue could affect regular clients
   - Solution: Same fix applies to client connections

2. **Device Binding Conflicts**: Player bound to different device
   - Symptom: "Server cannot use player X - bound to different device"
   - Solution: Use different player identifier or transfer device binding

3. **Numeric vs String Player IDs**: Inconsistent identifier handling
   - Solution: Use `get_chosen_player_id_from_args()` for string support

## Prevention Guidelines

### Code Review Checklist
- [ ] Any function that modifies `client_to_player_mapping` calls save afterwards
- [ ] Client registration functions include immediate persistence
- [ ] Player identity functions support both numeric and string identifiers
- [ ] Device binding validation occurs before client registration

### Testing Protocol
1. Test with numeric player IDs: `--player 999`
2. Test with string player IDs: `--player myplayer`  
3. Test with mixed identifiers: `--player player123abc`
4. Verify position persistence across server restarts
5. Check both server and client modes

## Architecture Notes

### Client-to-Player Mapping System
```
client_to_player_mapping: Dictionary = {
    "client_<uuid>": "player_<identifier>",  # Regular clients
    "server_<uuid>": "player_<identifier>"   # Server clients
}

peer_to_client_mapping: Dictionary = {
    1: "server_<uuid>",    # Server is always peer ID 1
    2: "client_<uuid>",    # First client connection
    3: "client_<uuid>",    # Second client connection
}
```

### Save/Load Flow
1. **Registration**: `register_client()` → Update mapping → `save_world_data()`
2. **Auto-Save**: Every 5 seconds → `save_player()` → `save_world_data()`
3. **Load**: Startup → `load_world_data()` → Check mapping → Load position

### Critical Functions
- `game_manager.gd`: `_register_player_with_client_id()`
- `world_data.gd`: `register_client()`
- `world_manager.gd`: `save_world_data()`
- `user_identity.gd`: `get_chosen_player_id_from_args()`

## Related Files

- `game_manager.gd` - Client registration and multiplayer coordination
- `world_data.gd` - Data persistence and client mapping management
- `world_manager.gd` - World state and save/load operations
- `user_identity.gd` - Player identity and device binding
- `world_data.tres` - Persistent world state file

## Historical Context

**Date Fixed**: 2025-08-24  
**Issue Duration**: Multiple sessions of position persistence failures  
**Impact**: Server players always spawned at start position after restart  
**Fix Complexity**: Low - required 2-line addition per registration function  

This issue existed because the original implementation assumed that auto-save would handle client mapping persistence, but auto-save only handled player position data, not the client-to-player mapping dictionary.