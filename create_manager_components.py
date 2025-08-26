#!/usr/bin/env python
"""
Manager Components Generator
Creates refactored WorldManager and GameManager component files with proper structure.
"""

import os
from pathlib import Path
from typing import Dict, List, Tuple

# Base directory (current directory where script is run)
BASE_DIR = Path(__file__).parent

def create_world_manager_components():
    """Create WorldManager component files with proper structure."""
    
    components = {
        'world_manager_godot_editor_player_search.gd': {
            'class_name': 'WorldManagerGodotEditorPlayerSearch',
            'description': 'Player search, filtering, and focus management in Godot Editor',
            'exports': [
                '@export_group("Player Search & Management")',
                '@export var search_term: String = ""',
                '@export var search_players: bool = false : set = _on_search_players',
                '@export var focus_on_player: String = ""',
                '@export var focus_camera: bool = false : set = _on_focus_camera',
                '@export var list_all_players: bool = false : set = _on_list_all_players',
                '@export var show_player_distances: bool = false : set = _on_show_distances',
                '',
                '@export_group("Player Focus Mode")',
                '@export var focus_player_list: String = "" # Comma-separated list of player IDs',
                '@export var apply_focus: bool = false : set = _on_apply_focus',
                '@export var clear_focus: bool = false : set = _on_clear_focus',
                '@export var highlight_focused: bool = true',
                '',
                '@export_group("Player Filtering & Display")',
                '@export var show_recent_players_only: bool = true',
                '@export var max_recent_players: int = 20',
                '@export var hide_insignificant_players: bool = true',
                '@export var significance_threshold: int = 5',
                '@export var refresh_display_filters: bool = false : set = _on_refresh_filters'
            ],
            'functions': [
                'search_for_players(term: String)',
                'focus_camera_on_player(player_id: String)', 
                'list_all_players_with_positions()',
                'show_player_distances_from_spawn()',
                'apply_player_focus(player_list_string: String)',
                'clear_player_focus()',
                'get_filtered_players(all_players: Dictionary) -> Array',
                'is_player_insignificant(player_info: Dictionary) -> bool'
            ]
        },
        
        'world_manager_godot_editor_display_players.gd': {
            'class_name': 'WorldManagerGodotEditorDisplayPlayers',
            'description': 'Visual player display and editor representation',
            'exports': [
                '@export_group("Editor Player Visibility")',
                '@export var toggle_players_visible: bool = false : set = _on_toggle_players_visible',
                '@export var editor_players_visible: bool = true',
                '@export var use_transparency_gradient: bool = true',
                '@export var oldest_player_alpha: float = 0.3',
                '',
                '@export_group("Editor Diagnostics")',
                '@export var test_editor_display: bool = false : set = _on_test_editor_display'
            ],
            'functions': [
                'sync_editor_players_from_world_data()',
                'spawn_editor_player(player_id: String, spawn_pos: Vector2)',
                'spawn_editor_player_with_styling(player_id: String, spawn_pos: Vector2, player_info: Dictionary, rank: int, total_filtered: int)',
                'clear_editor_players()',
                'toggle_editor_players_visibility()',
                'highlight_player_node(player_node: Node2D)',
                'remove_player_highlight(player_node: Node2D)',
                'test_editor_player_display()',
                '_check_for_editor_player_movement()'
            ]
        },
        
        'world_manager_godot_editor_player_rescue.gd': {
            'class_name': 'WorldManagerGodotEditorPlayerRescue',
            'description': 'Player rescue, cleanup, and manual positioning tools',
            'exports': [
                '@export_group("Player Rescue & Cleanup")',
                '@export var rescue_lost_players: bool = false : set = _on_rescue_lost_players',
                '@export var cleanup_duplicate_players: bool = false : set = _on_cleanup_duplicates',
                '@export var reset_all_players: bool = false : set = _on_reset_all_players',
                '',
                '@export_group("Manual Player Positioning")',
                '@export var player_to_move: String = ""',
                '@export var new_position: Vector2 = Vector2.ZERO',
                '@export var move_player_now: bool = false : set = _on_move_player_now'
            ],
            'functions': [
                'rescue_all_lost_players()',
                'cleanup_duplicate_players_from_identity_bug()',
                'reset_all_players_data()',
                'move_player_to_position(player_id: String, position: Vector2)'
            ]
        },
        
        'world_manager_godot_editor_diagnostics.gd': {
            'class_name': 'WorldManagerGodotEditorDiagnostics',
            'description': 'Editor diagnostic tools and utilities',
            'exports': [
                '@export_group("Editor Tools")',
                '@export var refresh_from_file: bool = false : set = _on_refresh_from_file',
                '@export var export_to_scene: bool = false : set = _on_export_to_scene',
                '@export var sync_scene_to_world: bool = false : set = _on_sync_scene_to_world',
                '@export var show_world_info: bool = false : set = _on_show_world_info',
                '@export var save_world_now: bool = false : set = _on_save_world_now'
            ],
            'functions': [
                'refresh_world_data_from_file()',
                'export_world_to_scene()',
                'sync_scene_to_world_data()',
                'show_world_information()',
                'trigger_manual_save()'
            ]
        },
        
        'world_manager_gameplay_entity_persistence.gd': {
            'class_name': 'WorldManagerGameplayEntityPersistence',
            'description': 'NPC and pickup persistence management',
            'exports': [
                '# NPC persistence settings',
                'var npcs_data: Dictionary = {}',
                'var npc_save_path: String = "user://npc_data.json"',
                '',
                '# Pickup persistence settings',
                'var pickups_data: Dictionary = {}',
                'var pickup_save_path: String = "user://pickup_data.json"'
            ],
            'functions': [
                'save_npcs()',
                'load_npcs()',
                'auto_save_npcs()',
                'save_pickups()',
                'load_pickups()',
                'auto_save_pickups()',
                'serialize_npc_data() -> Dictionary',
                'deserialize_npc_data(data: Dictionary)',
                'serialize_pickup_data() -> Dictionary',
                'deserialize_pickup_data(data: Dictionary)'
            ]
        },
        
        'world_manager_gameplay_tilemap_operations.gd': {
            'class_name': 'WorldManagerGameplayTilemapOperations',
            'description': 'Terrain modification and tilemap operations',
            'exports': [
                '@export var enable_terrain_modification: bool = true',
                '@export var default_tile_source: int = 1',
                '@export var default_tile_coords: Vector2i = Vector2i(0, 0)'
            ],
            'functions': [
                'modify_terrain(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int)',
                'get_terrain_at(coords: Vector2i) -> Dictionary',
                'is_walkable(coords: Vector2i) -> bool',
                'world_position_to_map(world_pos: Vector2) -> Vector2i',
                'map_to_world_position(map_coords: Vector2i) -> Vector2',
                'get_world_bounds() -> Rect2i',
                'sync_terrain_modification(coords: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int)',
                'send_world_state_to_client(peer_id: int)',
                'receive_world_state(tile_data: Dictionary)'
            ]
        },
        
        'world_manager_gameplay_data_io_operations.gd': {
            'class_name': 'WorldManagerGameplayDataIOOperations',
            'description': 'File I/O operations and data persistence',
            'exports': [
                '# Robust saving system',
                'var save_mutex: Mutex = Mutex.new()',
                'var save_in_progress: bool = false',
                'var save_retry_count: int = 0',
                'var max_save_retries: int = 3'
            ],
            'functions': [
                'save_world_data()',
                'load_world_data()',
                '_robust_save_world_data() -> bool',
                '_verify_save_integrity(original_mappings: Dictionary, original_players: Array, original_size: int) -> bool',
                'apply_world_data_to_tilemap()',
                'sync_tilemap_to_world_data()',
                '_check_for_external_changes()',
                '_check_for_tilemap_changes()',
                'create_backup_save()',
                'restore_from_backup()'
            ]
        }
    }
    
    return components

def create_game_manager_components():
    """Create GameManager component files with proper structure."""
    
    components = {
        'game_manager_online_f_keys_ui_system.gd': {
            'class_name': 'GameManagerOnlineFKeysUISystem',
            'description': 'F1-F12 key handling and debug UI management',
            'exports': [
                '# UI window tracking',
                'var device_binding_ui: Control = null',
                'var register_ui: Control = null',
                'var custom_join_ui: Control = null',
                'var player_list_ui: Control = null',
                'var reconnection_ui: Control = null'
            ],
            'functions': [
                '_unhandled_key_input(event)',
                '_show_device_binding_ui()',
                '_toggle_device_binding_ui()',
                '_show_register_ui()',
                '_toggle_register_ui()',
                '_show_custom_join_ui()',
                '_toggle_custom_join_ui()',
                '_show_player_list_ui()',
                '_toggle_player_list_ui()',
                '_show_reconnection_ui()',
                '_update_reconnection_ui()',
                '_close_all_ui_windows()',
                '_populate_player_list(container: VBoxContainer)',
                '_on_player_list_refresh(container: VBoxContainer)'
            ]
        },
        
        'game_manager_online_network_connection_system.gd': {
            'class_name': 'GameManagerOnlineNetworkConnectionSystem',
            'description': 'Network connection and reconnection management',
            'exports': [
                '# Connection and reconnection tracking',
                'enum ConnectionState { DISCONNECTED, CONNECTING, CONNECTED, RECONNECTING }',
                'var connection_state: ConnectionState = ConnectionState.DISCONNECTED',
                'var reconnection_attempts: int = 0',
                'var max_reconnection_attempts: int = 10',
                'var reconnection_delay: float = 2.0'
            ],
            'functions': [
                '_connect_to_server(ip: String, port: int)',
                '_connect_to_custom_server(ip: String, port: int)',
                '_attempt_reconnection()',
                '_start_reconnection()',
                '_schedule_next_reconnection()',
                '_on_client_connected_to_server(peer_id: int)',
                '_on_client_disconnected_from_server(peer_id: int)',
                '_on_client_connection_failed()',
                '_on_server_disconnected()',
                '_handle_server_disconnection()',
                '_handle_connection_failure()',
                '_monitor_connection(delta: float)',
                '_send_heartbeat()',
                'client_heartbeat(peer_id: int)'
            ]
        },
        
        'game_manager_online_player_spawning_system.gd': {
            'class_name': 'GameManagerOnlinePlayerSpawningSystem',
            'description': 'Player lifecycle management and peer spawning',
            'exports': [
                '# Player management',
                'var players = {}  # peer_id -> player_node',
                'var player_persistent_ids = {}  # peer_id -> persistent_player_id'
            ],
            'functions': [
                '_on_player_connected(id: int)',
                '_on_player_disconnected(id: int)',
                '_spawn_player(peer_id: int, pos: Vector2, persistent_id: String)',
                '_despawn_player(peer_id: int)',
                'spawn_player(peer_id: int, pos: Vector2, persistent_id: String)',
                'despawn_player(id: int)',
                '_cleanup_all_players()',
                '_cleanup_old_client_instances(client_id: String, new_peer_id: int)',
                '_cleanup_stale_connections()'
            ]
        },
        
        'game_manager_online_entity_spawning_system.gd': {
            'class_name': 'GameManagerOnlineEntitySpawningSystem',
            'description': 'NPC and pickup spawning management',
            'exports': [
                '# NPC Management',
                'var npcs = {}  # npc_id -> npc_node',
                'var next_npc_id: int = 1',
                '',
                '# Pickup Management',
                'var pickups = {}  # item_id -> pickup_node',
                'var next_pickup_id: int = 1'
            ],
            'functions': [
                'spawn_npc(npc_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String',
                '_spawn_npc_locally(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary)',
                'despawn_npc(npc_id: String)',
                '_despawn_npc_locally(npc_id: String)',
                'sync_npc_spawn(npc_id: String, npc_type: String, pos: Vector2, config: Dictionary)',
                'sync_npc_despawn(npc_id: String)',
                'spawn_pickup(item_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String',
                '_spawn_pickup_locally(item_id: String, item_type: String, pos: Vector2, config: Dictionary)',
                'despawn_pickup(item_id: String)',
                '_despawn_pickup_locally(item_id: String)',
                'sync_pickup_spawn(item_id: String, item_type: String, pos: Vector2, config: Dictionary)',
                'sync_pickup_despawn(item_id: String)'
            ]
        },
        
        'game_manager_online_auto_save_system.gd': {
            'class_name': 'GameManagerOnlineAutoSaveSystem',
            'description': 'Automatic position saving and persistence',
            'exports': [
                '# Automatic position saving',
                'var save_timer: float = 0.0',
                'var save_interval: float = 8.0  # Save every 8 seconds'
            ],
            'functions': [
                '_auto_save_all_player_positions()',
                '_emergency_save_all_positions()',
                'update_player_position(peer_id: int, pos: Vector2)',
                'handle_position_update_rpc(peer_id: int, pos: Vector2)'
            ]
        }
    }
    
    return components

def generate_component_file(filename: str, component_data: dict) -> str:
    """Generate the content for a component file."""
    
    class_name = component_data['class_name']
    description = component_data['description']
    exports = component_data.get('exports', [])
    functions = component_data.get('functions', [])
    
    # Determine if it's a @tool script (editor components)
    is_editor_tool = 'godot_editor' in filename
    tool_directive = '@tool\n' if is_editor_tool else ''
    
    content = f"""{tool_directive}extends Node
class_name {class_name}

# {description}

"""
    
    # Add exports/variables
    if exports:
        for export in exports:
            content += f"{export}\n"
        content += "\n"
    
    # Add world_manager reference for components
    manager_type = "WorldManager" if filename.startswith('world_manager') else "GameManager"
    content += f"# Reference to parent {manager_type}\n"
    content += f"var {manager_type.lower()}: {manager_type}\n\n"
    
    # Add ready function
    content += f"""func _ready():
\tprint("{class_name}: Component initialized")
\t# Initialize component-specific setup here

"""
    
    # Add function stubs
    if functions:
        content += "# Component Functions\n"
        for func in functions:
            # Extract just the function signature for stub
            func_signature = func.split('(')[0] if '(' in func else func
            content += f"""
func {func}:
\t# TODO: Implement {func_signature} functionality
\tpass
"""
    
    # Add component-specific helper functions
    content += f"""

# Component Communication
func set_{manager_type.lower()}(manager: {manager_type}):
\t{manager_type.lower()} = manager
\tprint("{class_name}: Connected to {manager_type}")

func get_{manager_type.lower()}() -> {manager_type}:
\treturn {manager_type.lower()}
"""
    
    return content

def create_main_manager_updates():
    """Create updated main manager files with component initialization."""
    
    # WorldManager update
    world_manager_content = """@tool
extends Node2D
class_name WorldManager

# Core properties
@export var world_tile_map_layer: TileMapLayer
@export var world_misc_tile_map_layer: TileMapLayer
@export var enable_terrain_modification: bool = true
@export var world_data: WorldData : set = set_world_data
@export var world_save_path: String = "user://world_data.tres"

# Component references
var editor_player_search: WorldManagerGodotEditorPlayerSearch
var editor_display_players: WorldManagerGodotEditorDisplayPlayers
var editor_player_rescue: WorldManagerGodotEditorPlayerRescue
var editor_diagnostics: WorldManagerGodotEditorDiagnostics
var gameplay_entity_persistence: WorldManagerGameplayEntityPersistence
var gameplay_tilemap_operations: WorldManagerGameplayTilemapOperations
var gameplay_data_io_operations: WorldManagerGameplayDataIOOperations

func _ready():
\tprint("WorldManager: Initializing component-based architecture")
\t_initialize_components()
\t_setup_component_communication()

func _initialize_components():
\t# Initialize editor components
\tif Engine.is_editor_hint():
\t\teditor_player_search = WorldManagerGodotEditorPlayerSearch.new()
\t\teditor_display_players = WorldManagerGodotEditorDisplayPlayers.new()
\t\teditor_player_rescue = WorldManagerGodotEditorPlayerRescue.new()
\t\teditor_diagnostics = WorldManagerGodotEditorDiagnostics.new()
\t\t
\t\tadd_child(editor_player_search)
\t\tadd_child(editor_display_players)
\t\tadd_child(editor_player_rescue)
\t\tadd_child(editor_diagnostics)
\t
\t# Initialize gameplay components
\tgameplay_entity_persistence = WorldManagerGameplayEntityPersistence.new()
\tgameplay_tilemap_operations = WorldManagerGameplayTilemapOperations.new()
\tgameplay_data_io_operations = WorldManagerGameplayDataIOOperations.new()
\t
\tadd_child(gameplay_entity_persistence)
\tadd_child(gameplay_tilemap_operations)
\tadd_child(gameplay_data_io_operations)

func _setup_component_communication():
\t# Connect components to world manager
\tif editor_player_search:
\t\teditor_player_search.set_world_manager(self)
\tif editor_display_players:
\t\teditor_display_players.set_world_manager(self)
\tif editor_player_rescue:
\t\teditor_player_rescue.set_world_manager(self)
\tif editor_diagnostics:
\t\teditor_diagnostics.set_world_manager(self)
\t
\tgameplay_entity_persistence.set_world_manager(self)
\tgameplay_tilemap_operations.set_world_manager(self)
\tgameplay_data_io_operations.set_world_manager(self)

func set_world_data(new_world_data: WorldData):
\tworld_data = new_world_data
\tprint("WorldManager: World data updated")

# Core coordination functions remain here
func get_world_bounds() -> Rect2i:
\tif gameplay_tilemap_operations:
\t\treturn gameplay_tilemap_operations.get_world_bounds()
\treturn Rect2i()

func save_world_data():
\tif gameplay_data_io_operations:
\t\tgameplay_data_io_operations.save_world_data()

func load_world_data():
\tif gameplay_data_io_operations:
\t\tgameplay_data_io_operations.load_world_data()
"""
    
    # GameManager update
    game_manager_content = """extends Node
class_name GameManager

# Core constants and references
const PORT = 4443

# System references
var network_manager: NetworkManager
var world_manager: WorldManager
var user_identity: UserIdentity
var register: Register
var login: Login

# Component references
var f_keys_ui_system: GameManagerOnlineFKeysUISystem
var network_connection_system: GameManagerOnlineNetworkConnectionSystem
var player_spawning_system: GameManagerOnlinePlayerSpawningSystem
var entity_spawning_system: GameManagerOnlineEntitySpawningSystem
var auto_save_system: GameManagerOnlineAutoSaveSystem

func _ready():
\tprint("GameManager: Initializing online component-based architecture")
\t_initialize_components()
\t_setup_component_communication()
\t_setup_system_references()

func _initialize_components():
\tf_keys_ui_system = GameManagerOnlineFKeysUISystem.new()
\tnetwork_connection_system = GameManagerOnlineNetworkConnectionSystem.new()
\tplayer_spawning_system = GameManagerOnlinePlayerSpawningSystem.new()
\tentity_spawning_system = GameManagerOnlineEntitySpawningSystem.new()
\tauto_save_system = GameManagerOnlineAutoSaveSystem.new()
\t
\tadd_child(f_keys_ui_system)
\tadd_child(network_connection_system)
\tadd_child(player_spawning_system)
\tadd_child(entity_spawning_system)
\tadd_child(auto_save_system)

func _setup_component_communication():
\tf_keys_ui_system.set_game_manager(self)
\tnetwork_connection_system.set_game_manager(self)
\tplayer_spawning_system.set_game_manager(self)
\tentity_spawning_system.set_game_manager(self)
\tauto_save_system.set_game_manager(self)

func _setup_system_references():
\t# Get references to other managers
\tnetwork_manager = get_node("../NetworkManager")
\tworld_manager = get_node("../WorldManager") 
\tuser_identity = get_node("../UserIdentity")
\tregister = get_node("../world/account/Register")
\tlogin = get_node("../world/account/Login")

func _process(delta):
\t# Delegate to auto-save system
\tif auto_save_system:
\t\tauto_save_system._process(delta)

func _unhandled_key_input(event):
\t# Delegate to F-keys UI system
\tif f_keys_ui_system:
\t\tf_keys_ui_system._unhandled_key_input(event)

# Public API functions that delegate to components
func spawn_player(peer_id: int, pos: Vector2, persistent_id: String):
\tif player_spawning_system:
\t\tplayer_spawning_system.spawn_player(peer_id, pos, persistent_id)

func despawn_player(id: int):
\tif player_spawning_system:
\t\tplayer_spawning_system.despawn_player(id)

func spawn_npc(npc_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String:
\tif entity_spawning_system:
\t\treturn entity_spawning_system.spawn_npc(npc_type, spawn_pos, config_data)
\treturn ""

func spawn_pickup(item_type: String, spawn_pos: Vector2, config_data: Dictionary = {}) -> String:
\tif entity_spawning_system:
\t\treturn entity_spawning_system.spawn_pickup(item_type, spawn_pos, config_data)
\treturn ""
"""
    
    return {
        'world_manager_refactored.gd': world_manager_content,
        'game_manager_refactored.gd': game_manager_content
    }

def main():
    """Main function to create all component files."""
    
    print("🏗️  Creating Manager Component Files...")
    print("=" * 50)
    
    # Create components directory if it doesn't exist
    components_dir = BASE_DIR / "manager_components"
    components_dir.mkdir(exist_ok=True)
    
    # Get all components
    world_components = create_world_manager_components()
    game_components = create_game_manager_components()
    main_managers = create_main_manager_updates()
    
    all_components = {**world_components, **game_components}
    
    created_files = []
    
    # Create component files
    for filename, component_data in all_components.items():
        file_path = components_dir / filename
        content = generate_component_file(filename, component_data)
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            created_files.append(filename)
            print(f"✅ Created: {filename}")
        except Exception as e:
            print(f"❌ Error creating {filename}: {e}")
    
    # Create updated main manager files
    for filename, content in main_managers.items():
        file_path = components_dir / filename
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            created_files.append(filename)
            print(f"✅ Created: {filename}")
        except Exception as e:
            print(f"❌ Error creating {filename}: {e}")
    
    # Create summary file
    summary_content = f"""# Manager Components Summary

## Created Files ({len(created_files)} total)

### WorldManager Components (7 files)
- world_manager_refactored.gd - Updated main WorldManager
- world_manager_godot_editor_player_search.gd - Player search & filtering
- world_manager_godot_editor_display_players.gd - Visual player display
- world_manager_godot_editor_player_rescue.gd - Player rescue tools
- world_manager_godot_editor_diagnostics.gd - Editor utilities
- world_manager_gameplay_entity_persistence.gd - Entity persistence
- world_manager_gameplay_tilemap_operations.gd - Terrain operations
- world_manager_gameplay_data_io_operations.gd - File I/O operations

### GameManager Components (6 files)
- game_manager_refactored.gd - Updated main GameManager
- game_manager_online_f_keys_ui_system.gd - F1-F12 debug UI
- game_manager_online_network_connection_system.gd - Network connections
- game_manager_online_player_spawning_system.gd - Player lifecycle
- game_manager_online_entity_spawning_system.gd - NPC/pickup spawning
- game_manager_online_auto_save_system.gd - Position auto-save

## Usage Instructions

1. **Review generated files** in the manager_components/ directory
2. **Copy functions** from original managers to appropriate components
3. **Update main managers** with the refactored versions
4. **Test component communication** and fix any missing references
5. **Update scene references** to use component-based architecture

## Component Architecture

### WorldManager Domain
- **godot_editor_***: Development tools for Godot Editor
- **gameplay_***: Game mechanics and world systems

### GameManager Domain  
- **online_***: Network coordination and multiplayer features

Generated on: {created_files.__len__()} files created successfully!
"""
    
    summary_path = components_dir / "README.md"
    try:
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write(summary_content)
        print(f"✅ Created: README.md")
    except Exception as e:
        print(f"❌ Error creating README.md: {e}")
    
    print("=" * 50)
    print(f"🎉 Successfully created {len(created_files)} component files!")
    print(f"📁 Files created in: {components_dir}")
    print("📋 Check README.md for usage instructions")

if __name__ == "__main__":
    main()