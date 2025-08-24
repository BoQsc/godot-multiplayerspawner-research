# TileMap Layer Integration Guide

## Issue Overview

**Problem**: Position persistence fails when players move from one TileMapLayer to another (e.g., WorldTileMapLayer → WorldMiscTileMapLayer).

**Root Cause**: WorldManager only tracks the primary WorldTileMapLayer, treating positions on other tilemap layers as invalid or untracked game world areas.

**Symptom**: Players spawn at default position (100, 100) after server restart instead of their saved position when last seen on untracked tilemap layers.

## System Architecture

### WorldManager TileMap Tracking
The WorldManager class is responsible for:
- Syncing tilemap data to persistent storage
- Validating world positions
- Managing terrain modifications
- Loading/saving world state

**Critical Requirement**: ALL tilemap layers used for gameplay MUST be registered with WorldManager or position persistence will fail intermittently.

## Integration Steps for New TileMap Layers

### 1. Export Property Declaration
Add the new layer as an exported property in `world_manager.gd`:

```gdscript
@export var world_tile_map_layer: TileMapLayer
@export var world_misc_tile_map_layer: TileMapLayer
@export var your_new_layer: TileMapLayer  # Add this line
```

### 2. Node Path Configuration
Update `main_scene.tscn` WorldManager node configuration:

```
[node name="WorldManager" type="Node2D" parent="." node_paths=PackedStringArray("world_tile_map_layer", "world_misc_tile_map_layer", "your_new_layer") groups=["world_manager"]]
script = ExtResource("3_world")
world_tile_map_layer = NodePath("WorldTileMapLayer")
world_misc_tile_map_layer = NodePath("WorldMiscTileMapLayer")  
your_new_layer = NodePath("YourNewTileMapLayer")  # Add this line
```

### 3. Initialization in _ready()
Add initialization code in `world_manager.gd` `_ready()` function:

```gdscript
if not your_new_layer:
    your_new_layer = get_node_or_null("YourNewTileMapLayer")

if your_new_layer:
    print("WorldManager: Initialized with YourNewTileMapLayer")
else:
    print("WorldManager: No YourNewTileMapLayer found")
```

### 4. Update sync_tilemap_to_world_data()
Add sync logic for the new layer:

```gdscript
# Sync YourNewTileMapLayer
if your_new_layer:
    var used_cells_new = your_new_layer.get_used_cells()
    for coords in used_cells_new:
        var source_id = your_new_layer.get_cell_source_id(coords)
        var atlas_coords = your_new_layer.get_cell_atlas_coords(coords)
        var alternative_tile = your_new_layer.get_cell_alternative_tile(coords)
        world_data.set_tile(coords, source_id, atlas_coords, alternative_tile)
    total_synced += used_cells_new.size()
    print("WorldManager: Synced ", used_cells_new.size(), " tiles from YourNewTileMapLayer")
```

### 5. Update get_terrain_at() Fallback Logic
Add fallback check for the new layer:

```gdscript
# Try YourNewTileMapLayer if not found in previous layers
if your_new_layer:
    var source_id = your_new_layer.get_cell_source_id(coords)
    if source_id != -1:  # Valid tile found
        return {
            "source_id": source_id,
            "atlas_coords": your_new_layer.get_cell_atlas_coords(coords),
            "alternative_tile": your_new_layer.get_cell_alternative_tile(coords),
            "tile_data": your_new_layer.get_cell_tile_data(coords)
        }
```

Also update the tile_data retrieval in the world_data section:

```gdscript
# Try to get tile data from any tilemap layer
var tile_data = null
if world_tile_map_layer:
    tile_data = world_tile_map_layer.get_cell_tile_data(coords)
if not tile_data and world_misc_tile_map_layer:
    tile_data = world_misc_tile_map_layer.get_cell_tile_data(coords)
if not tile_data and your_new_layer:  # Add this line
    tile_data = your_new_layer.get_cell_tile_data(coords)
```

### 6. Update Cell Count Monitoring
Include the new layer in change detection:

```gdscript
# Count cells from all tilemap layers
var current_cell_count = 0
if world_tile_map_layer:
    current_cell_count += world_tile_map_layer.get_used_cells().size()
if world_misc_tile_map_layer:
    current_cell_count += world_misc_tile_map_layer.get_used_cells().size()
if your_new_layer:  # Add this line
    current_cell_count += your_new_layer.get_used_cells().size()
```

### 7. Update Startup Sync Logic
Include the new layer in startup tile counting:

```gdscript
# Check if tilemaps have data but world_data is empty (editor painted tiles)
if world_data and world_data.get_tile_count() == 0:
    var total_cells = 0
    if world_tile_map_layer:
        total_cells += world_tile_map_layer.get_used_cells().size()
    if world_misc_tile_map_layer:
        total_cells += world_misc_tile_map_layer.get_used_cells().size()
    if your_new_layer:  # Add this line
        total_cells += your_new_layer.get_used_cells().size()
```

## Validation Checklist

After adding a new tilemap layer, verify:

- [ ] Export property declared in `world_manager.gd`
- [ ] Node path added to `main_scene.tscn` WorldManager configuration
- [ ] Initialization code added to `_ready()` function
- [ ] Sync logic added to `sync_tilemap_to_world_data()`
- [ ] Fallback logic added to `get_terrain_at()`
- [ ] Cell counting updated in `_check_for_tilemap_changes()`
- [ ] Startup sync updated for empty world_data check
- [ ] Test position persistence across layer boundaries

## Testing Procedure

1. **Movement Test**: Move player to new tilemap layer area
2. **Wait for Auto-Save**: Wait 6+ seconds for auto-save cycle
3. **Server Restart**: Stop and restart server with same player ID
4. **Verify Spawn**: Confirm player spawns at saved position, not default (100, 100)
5. **Cross-Layer Test**: Test movement between all tilemap layers

## Common Pitfalls

### Missing Node Path
**Error**: `WorldManager: No YourNewTileMapLayer found`
**Solution**: Add node path to `main_scene.tscn` WorldManager configuration

### Incomplete Sync Logic
**Symptom**: Tiles from new layer don't persist between sessions
**Solution**: Ensure `sync_tilemap_to_world_data()` includes new layer

### Missing Fallback Logic  
**Symptom**: `get_terrain_at()` returns empty data for new layer positions
**Solution**: Add fallback check in `get_terrain_at()` method

### Forgotten Change Detection
**Symptom**: Editor changes to new layer don't trigger auto-sync
**Solution**: Include new layer in `_check_for_tilemap_changes()` cell counting

## Performance Considerations

- Each additional tilemap layer increases sync time and memory usage
- Consider layer priority order in `get_terrain_at()` for frequently accessed areas
- Monitor total tile count across all layers for performance impact
- Use layer-specific optimizations if certain layers are read-only

## Future Architecture Improvements

Consider implementing:
- Dynamic layer registration system
- Layer-specific sync intervals
- Selective layer loading based on player proximity
- Layer priority/precedence system for overlapping tiles

## Historical Context

This issue was discovered on 2025-08-24 when position persistence failed after players moved from `WorldTileMapLayer` to `WorldMiscTileMapLayer`. The root cause was that only the primary layer was tracked, causing the system to treat positions on secondary layers as invalid.

**Resolution**: Extended WorldManager to track multiple tilemap layers, ensuring consistent position persistence across all game world areas.