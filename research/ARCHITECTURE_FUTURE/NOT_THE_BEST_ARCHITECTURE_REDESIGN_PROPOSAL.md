# Architecture Redesign Proposal

**Date**: 2025-08-20  
**Purpose**: Restructure the current codebase for better maintainability, testability, and developer experience

## Current Architecture Pain Points

### 1. Monolithic GameManager
- **Issue**: Single file with 1,121 lines handling everything
- **Problems**: Network management, UI creation, player spawning, device binding, reconnection logic all mixed together
- **Impact**: Difficult to debug, test, or modify individual features

### 2. Mixed Responsibilities
- WorldManager does both world persistence AND editor UI management
- UI creation logic scattered throughout game logic files
- Network synchronization mixed with business logic

### 3. Tight Coupling
- Systems find each other via `get_tree().get_first_node_in_group()`
- Direct references between unrelated systems
- Fragile initialization order dependencies

### 4. Complex Data Flow
- Some data flows through RPCs, others through direct method calls
- Inconsistent error handling across systems
- No clear separation between client and server logic

## Proposed Architecture

### Core Principle: Single Responsibility + Event-Driven Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Game Scene                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │   GameSession   │  │   UIManager     │  │  SceneManager   ││
│  │   (Coordinator) │  │   (All UI)      │  │  (Scene Loading)││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│           │                     │                     │       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ NetworkSystem   │  │ PlayerSystem    │  │  WorldSystem    ││
│  │ (Conn/Sync)     │  │ (Spawn/Track)   │  │  (Terrain/Data) ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│           │                     │                     │       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ AuthSystem      │  │ DataSystem      │  │  InputSystem    ││
│  │ (Identity/Auth) │  │ (Save/Load)     │  │  (Controls)     ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## System Responsibilities

### 1. GameSession (Main Coordinator)
**Role**: Lightweight orchestrator that manages system lifecycle
```gdscript
extends Node
class_name GameSession

@onready var network_system = $NetworkSystem
@onready var player_system = $PlayerSystem  
@onready var world_system = $WorldSystem
@onready var ui_manager = $UIManager

func start_server() -> void
func start_client(ip: String) -> void
func shutdown() -> void
```

**Responsibilities**:
- Initialize systems in correct order
- Handle high-level game state transitions (menu → game → shutdown)
- Coordinate system shutdowns
- **Does NOT**: Handle UI, networking, or game logic directly

### 2. NetworkSystem
**Role**: All network communication and connection management
```gdscript
extends Node
class_name NetworkSystem

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed()

func create_server(port: int) -> Error
func connect_to_server(ip: String, port: int) -> Error
func send_reliable(peer_id: int, method: String, data: Dictionary) -> void
func broadcast_unreliable(method: String, data: Dictionary) -> void
```

**Responsibilities**:
- ENet peer management
- Connection/disconnection handling
- RPC routing and rate limiting
- Reconnection logic
- **Does NOT**: Know about players, world, or UI

### 3. PlayerSystem
**Role**: Player spawning, tracking, and lifecycle management
```gdscript
extends Node
class_name PlayerSystem

signal player_spawned(peer_id: int, player_data: PlayerData)
signal player_despawned(peer_id: int)

func spawn_player(peer_id: int, spawn_data: PlayerData) -> void
func despawn_player(peer_id: int) -> void
func get_player_by_peer_id(peer_id: int) -> Node2D
func update_player_position(peer_id: int, position: Vector2) -> void
```

**Responsibilities**:
- Player scene instantiation/removal
- Position synchronization
- Player state management
- **Does NOT**: Handle authentication, networking, or world modification

### 4. WorldSystem
**Role**: Pure world data and terrain management
```gdscript
extends Node
class_name WorldSystem

signal terrain_modified(coords: Vector2i, tile_data: Dictionary)

func get_tile_at(coords: Vector2i) -> Dictionary
func set_tile_at(coords: Vector2i, tile_data: Dictionary) -> void
func is_walkable(coords: Vector2i) -> bool
func get_spawn_position(player_id: String) -> Vector2
```

**Responsibilities**:
- Tile map operations
- World bounds and collision
- Spawn point management
- **Does NOT**: Handle editor UI, player management, or networking

### 5. UIManager
**Role**: All user interface and input handling
```gdscript
extends Node
class_name UIManager

func show_connection_dialog() -> void
func show_device_binding_dialog() -> void
func show_player_list() -> void
func hide_all_dialogs() -> void
```

**Responsibilities**:
- UI panel creation and management
- Input event routing
- Menu state transitions
- **Does NOT**: Handle game logic or networking directly

### 6. AuthSystem
**Role**: Player identity and device binding
```gdscript
extends Node
class_name AuthSystem

signal authentication_complete(client_data: ClientData)
signal authentication_failed(reason: String)

func authenticate_player(device_fingerprint: String) -> ClientData
func bind_device_to_player(player_id: String, device_id: String) -> void
func can_access_player(player_id: String, device_id: String) -> bool
```

**Responsibilities**:
- Player identity generation
- Device fingerprinting
- Access validation
- **Does NOT**: Handle networking or UI directly

### 7. DataSystem
**Role**: Persistent data management
```gdscript
extends Node
class_name DataSystem

func save_world_data(world_data: WorldData) -> Error
func load_world_data() -> WorldData
func save_player_data(player_data: PlayerData) -> Error
func load_player_data(player_id: String) -> PlayerData
```

**Responsibilities**:
- File I/O operations
- Data serialization
- Auto-save scheduling
- **Does NOT**: Know about game objects or UI

## Event-Driven Communication

Replace direct method calls with signals for loose coupling:

```gdscript
# GameEvents.gd - Central event hub
class_name GameEvents
extends Node

# Network Events
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed()

# Player Events  
signal player_spawn_requested(peer_id: int, spawn_data: PlayerData)
signal player_position_updated(peer_id: int, position: Vector2)
signal player_despawn_requested(peer_id: int)

# World Events
signal terrain_modification_requested(coords: Vector2i, tile_data: Dictionary)
signal world_data_loaded(world_data: WorldData)

# UI Events
signal dialog_requested(dialog_type: String, data: Dictionary)
signal input_received(action: String, data: Dictionary)
```

### Communication Example:
```gdscript
# Instead of: game_manager.spawn_player(peer_id, position)
GameEvents.player_spawn_requested.emit(peer_id, spawn_data)

# Instead of: world_manager.modify_terrain(coords, tile_data) 
GameEvents.terrain_modification_requested.emit(coords, tile_data)

# Instead of: ui_manager.show_connection_dialog()
GameEvents.dialog_requested.emit("connection", {})
```

## File Structure (Domain-Driven Organization)

**MUCH BETTER APPROACH: Organize by Feature/Domain**

The original proposal separated data and logic artificially. Here's the intuitive approach:

```
res://
├── core/
│   ├── GameSession.gd          # Main coordinator
│   ├── GameConfig.gd           # Global configuration
│   └── GameEvents.gd           # Event definitions
├── networking/
│   ├── NetworkSystem.gd        # Connection management
│   ├── NetworkData.gd          # Network-related data structures
│   ├── ReconnectionHandler.gd  # Reconnection logic
│   └── RPCManager.gd           # RPC routing and rate limiting
├── players/
│   ├── PlayerSystem.gd         # Player management logic
│   ├── PlayerData.gd           # Player data model
│   ├── PlayerEntity.gd         # Player scene/entity
│   ├── PlayerSpawner.gd        # Spawning logic
│   └── ui/
│       ├── PlayerList.gd       # Player list UI
│       └── PlayerHUD.gd        # Player HUD
├── world/
│   ├── WorldSystem.gd          # World management logic
│   ├── WorldData.gd            # World data model  
│   ├── TerrainManager.gd       # Tile operations
│   ├── SpawnPointManager.gd    # Spawn management
│   └── editor/
│       ├── WorldEditor.gd      # Editor-specific world tools
│       └── WorldEditorUI.gd    # Editor UI panels
├── authentication/
│   ├── AuthSystem.gd           # Authentication logic
│   ├── ClientData.gd           # Client identity model
│   ├── DeviceBinding.gd        # Device binding logic
│   └── ui/
│       ├── LoginDialog.gd      # Login UI
│       ├── RegisterDialog.gd   # Registration UI
│       └── DeviceBindingUI.gd  # Device binding UI
├── persistence/
│   ├── DataSystem.gd           # Save/load coordination
│   ├── WorldSaver.gd           # World persistence
│   ├── PlayerSaver.gd          # Player persistence
│   ├── GameSave.gd             # Save file format
│   └── SaveMigrator.gd         # Handle save format changes
└── ui/
    ├── UIManager.gd            # UI coordination only
    ├── ConnectionDialog.gd     # Server connection UI
    ├── MainMenu.gd             # Main menu
    └── shared/
        ├── Dialog.gd           # Base dialog class
        └── UIHelpers.gd        # Reusable UI utilities
```

**Why Domain-Driven is Much Better:**

1. **Everything related to players is in one place** - data, logic, UI, spawning
2. **Want to modify networking?** Everything is in the `networking/` folder  
3. **Working on authentication?** All related files are together
4. **Adding world features?** You know exactly where to look and add code
5. **Each folder can be developed independently** by different team members
6. **When you think "I need to fix player spawning"** → go to `players/` folder
7. **New developer asks "where's the auth code?"** → point to `authentication/` folder

**The Technical Layer Approach is Backwards:**
- Splits related functionality across multiple folders
- Forces you to remember "data goes here, logic goes there, UI goes over there"  
- Makes simple changes require editing files in 3+ different locations
- Optimizes for framework categories instead of human mental models

## Centralized Configuration

```gdscript
# GameConfig.gd - Single source of truth
class_name GameConfig
extends Resource

# Network Settings
const PORT = 4443
const MAX_RECONNECT_ATTEMPTS = 10
const HEARTBEAT_INTERVAL = 2.0

# Game Settings  
const SAVE_INTERVAL = 5.0
const MAX_PLAYERS = 16
const DEFAULT_SPAWN = Vector2(100, 100)

# Paths
const WORLD_SAVE_PATH = "user://world_data.tres"
const PLAYER_SAVE_PATH = "user://players/"
const DEVICE_BINDINGS_PATH = "user://device_bindings.json"
```

## Data Models

```gdscript
# PlayerData.gd
class_name PlayerData extends Resource

@export var player_id: String
@export var client_id: String  
@export var position: Vector2
@export var level: int = 1
@export var health: int = 100
@export var max_health: int = 100
@export var last_seen: float
@export var device_fingerprint: String

# WorldData.gd  
class_name WorldData extends Resource

@export var world_name: String
@export var tiles: Dictionary = {}  # Vector2i -> TileData
@export var spawn_points: Array[Vector2] = []
@export var world_bounds: Rect2i

# ClientData.gd
class_name ClientData extends Resource

@export var client_id: String
@export var device_fingerprint: String  
@export var chosen_player_number: int = -1
@export var created_at: float
```

## Migration Strategy

### Phase 1: Extract Systems (No Breaking Changes)
1. Create system classes alongside existing code
2. Gradually move methods from GameManager to appropriate systems
3. Keep existing interfaces working during transition

### Phase 2: Implement Event System  
1. Add GameEvents singleton
2. Replace direct calls with event emissions
3. Systems subscribe to relevant events

### Phase 3: Clean Up
1. Remove old monolithic files
2. Update scene structure
3. Clean up unused code and references

## Benefits of This Architecture

### 1. Single Responsibility
- Each file has one clear, well-defined purpose
- Easier to understand what each component does
- Simpler to debug issues

### 2. Loose Coupling
- Systems don't directly reference each other
- Changes to one system don't break others
- Easier to add/remove features

### 3. Testability
- Each system can be unit tested in isolation
- Clear interfaces make mocking possible
- Deterministic behavior

### 4. Maintainability  
- Adding features requires touching fewer files
- Bug fixes are isolated to relevant systems
- Code reviews are more focused

### 5. Scalability
- Easy to add new systems without modifying existing ones
- Clear patterns for extending functionality
- Performance optimizations can be system-specific

## Implementation Priority

### High Priority (Core Improvements)
1. **Extract NetworkSystem** - Isolate connection logic
2. **Extract UIManager** - Separate UI from game logic  
3. **Create GameEvents** - Enable loose coupling
4. **Simplify GameSession** - Reduce monolithic GameManager

### Medium Priority (Quality of Life)
1. **Extract PlayerSystem** - Clean up player management
2. **Extract AuthSystem** - Isolate identity logic
3. **Centralize Configuration** - Single source of truth
4. **Standardize Data Models** - Type-safe data structures

### Low Priority (Polish)
1. **Extract DataSystem** - Isolate save/load logic
2. **Clean File Structure** - Organize by responsibility
3. **Add System Tests** - Ensure reliability
4. **Performance Optimization** - Profile and optimize

---

**Recommendation**: Start with NetworkSystem extraction as it provides the biggest immediate benefit with the least risk of breaking existing functionality.