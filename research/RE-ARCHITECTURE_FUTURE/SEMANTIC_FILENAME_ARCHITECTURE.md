# Semantic Filename Architecture
**Philosophy**: Filenames have magical properties that affect behavior

## The Problem: Artificial Separation

Traditional architecture forces unnatural splits:
```
❌ multiplayer_system/ + combat_system/ = two separate things to learn/maintain
✅ multiplayercombat/ = one cohesive feature that works together
```

## Solution: Magic Filenames + Custom Godot Plugin

### Semantic Filenames That Do Things

```
res://
├── features/
│   ├── multiplayercombat_PROVIDES_networked_fighting_NEEDS_basic_scene/
│   │   ├── MultiplayerCombat_AUTOLOAD.gd      # 🪄 Automatically becomes autoload
│   │   ├── Player_NETWORKABLE_SPAWNABLE.gd    # 🪄 Gets network sync + spawning
│   │   ├── Weapon_INVENTORYABLE.gd            # 🪄 Can be put in inventories  
│   │   ├── CombatUI_ADAPTABLE.tscn            # 🪄 UI adapts to screen size
│   │   └── BloodEffect_POOLABLE.gd            # 🪄 Gets object pooling for performance
│   │
│   ├── worldbuilding_PROVIDES_terrain_editing_NEEDS_basic_scene/
│   │   ├── TerrainPainter_TOOL.gd             # 🪄 Shows up in editor toolbar
│   │   ├── Block_NETWORKABLE_PLACEABLE.gd     # 🪄 Can be placed + synced
│   │   └── BuildingUI_CONTEXTUAL.tscn         # 🪄 Only shows when relevant
│   │
│   ├── playeridentity_PROVIDES_authentication_NEEDS_nothing/
│   │   ├── DeviceID_SINGLETON.gd              # 🪄 One instance across game
│   │   ├── PlayerData_SAVEABLE_NETWORKABLE.gd # 🪄 Saves + syncs automatically
│   │   └── LoginDialog_MODAL.tscn             # 🪄 Blocks other UI when shown
│   │
│   └── visualeffects_PROVIDES_pretty_graphics_NEEDS_entities/
│       ├── ParticleManager_PERFORMANT.gd      # 🪄 Gets performance optimizations
│       ├── Explosion_TEMPORARY.gd             # 🪄 Auto-destroys after animation
│       └── HealthBar_FOLLOWSOWNER.gd          # 🪄 Sticks to entity position
│
├── experiments/                               # 🧪 TRYING STUFF OUT
│   ├── crazyidea_EXPERIMENTAL.gd              # 🪄 Warning: might not work
│   ├── newfeature_PROTOTYPE_UNSTABLE.gd       # 🪄 Don't use in production
│   └── failedtest_DEPRECATED_REMOVE_LATER.gd  # 🪄 Marked for cleanup
│
└── generated/                                 # 🤖 PLUGIN CREATES THESE
    ├── FeatureDependencyGraph.json            # Auto-updated
    ├── NetworkSyncRegistry.json               # All _NETWORKABLE files
    └── AutoloadConfiguration.json             # All _AUTOLOAD files
```

## Magic Filename Keywords

### **Behavior Keywords** (affect how code runs):
- `_AUTOLOAD` - Automatically added to autoload settings
- `_SINGLETON` - Enforces only one instance exists
- `_NETWORKABLE` - Gets automatic network synchronization
- `_SPAWNABLE` - Can be spawned by other systems
- `_POOLABLE` - Uses object pooling for performance
- `_TEMPORARY` - Auto-destroys after use
- `_PERSISTENT` - Survives scene changes

### **UI Keywords** (affect interface behavior):
- `_ADAPTABLE` - UI adapts to screen size/platform
- `_MODAL` - Blocks interaction with other UI
- `_CONTEXTUAL` - Only shows when relevant
- `_FOLLOWSOWNER` - UI element follows an entity
- `_DRAGGABLE` - Can be moved by user

### **Development Keywords** (affect editor behavior):
- `_TOOL` - Available in editor toolbar
- `_EXPERIMENTAL` - Shows warning when used
- `_PROTOTYPE` - Not for production use
- `_DEPRECATED` - Marked for removal

### **Integration Keywords** (affect connections):
- `_INVENTORYABLE` - Can be put in inventories
- `_SAVEABLE` - Automatically saved/loaded
- `_CONFIGURABLE` - Appears in settings menus
- `_DEBUGGABLE` - Gets debug visualization

## Custom Godot Editor Plugin

### Visual Recipe Builder Plugin:

```gdscript
# addons/semantic_architect/plugin.cfg
[plugin]
name="Semantic Architect"
description="Drag-and-drop feature composition with magic filenames"
author="You"
version="1.0"
script="semantic_architect_plugin.gd"

# addons/semantic_architect/semantic_architect_plugin.gd
@tool
extends EditorPlugin

func _enter_tree():
    add_dock_to_container(DOCK_SLOT_LEFT_UL, preload("res://addons/semantic_architect/FeatureComposer.tscn"))

func _exit_tree():
    remove_dock_from_container(DOCK_SLOT_LEFT_UL, preload("res://addons/semantic_architect/FeatureComposer.tscn"))
```

### Drag-and-Drop Feature Composer UI:

```gdscript
# addons/semantic_architect/FeatureComposer.gd
@tool
extends Control

@onready var available_features: ItemList = $VBox/AvailableFeatures
@onready var recipe_builder: ItemList = $VBox/RecipeBuilder
@onready var dependency_graph: Control = $VBox/DependencyGraph

func _ready():
    scan_for_features()
    setup_drag_and_drop()

func scan_for_features():
    # Scan filesystem for folders with _PROVIDES_ keywords
    var features = []
    var dir = DirAccess.open("res://features/")
    
    for folder in dir.get_directories():
        if "_PROVIDES_" in folder:
            var provides = extract_provides_from_name(folder)
            var needs = extract_needs_from_name(folder)
            
            features.append({
                "name": folder.split("_PROVIDES_")[0],
                "provides": provides,
                "needs": needs,
                "path": "res://features/" + folder
            })
    
    populate_feature_list(features)

func setup_drag_and_drop():
    # Allow dragging features from available to recipe
    available_features.gui_input.connect(_on_feature_dragged)
    recipe_builder.gui_input.connect(_on_recipe_drop)

func _on_feature_dragged(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        var selected = available_features.get_selected_items()[0]
        var feature = available_features.get_item_text(selected)
        
        # Start drag preview
        set_drag_preview(create_feature_preview(feature))

func _on_recipe_drop(event: InputEvent):
    if can_drop_data(Vector2.ZERO, get_drag_data()):
        var feature = get_drag_data()
        add_feature_to_recipe(feature)
        update_dependency_graph()

func update_dependency_graph():
    # Visual representation of feature dependencies
    dependency_graph.queue_redraw()
    
func _draw():
    # Draw arrows between features showing dependencies
    for feature in current_recipe:
        draw_dependency_arrows(feature)
```

## How Magic Keywords Work

### Filename Processing Plugin:

```gdscript
# addons/semantic_architect/filename_processor.gd
@tool
extends EditorPlugin

func _enter_tree():
    # Hook into file system to process magic filenames
    var filesystem = EditorInterface.get_resource_filesystem()
    filesystem.filesystem_changed.connect(_on_files_changed)

func _on_files_changed():
    process_magic_filenames()

func process_magic_filenames():
    var magic_files = find_files_with_keywords()
    
    for file_path in magic_files:
        var keywords = extract_keywords_from_filename(file_path)
        apply_magic_behaviors(file_path, keywords)

func apply_magic_behaviors(file_path: String, keywords: Array):
    for keyword in keywords:
        match keyword:
            "_AUTOLOAD":
                add_to_autoload_settings(file_path)
            "_NETWORKABLE":
                add_to_network_sync_registry(file_path)
            "_TOOL":
                add_to_editor_toolbar(file_path)
            "_SPAWNABLE":
                register_as_spawnable_entity(file_path)
            # ... handle all other magic keywords
```

### Auto-Generated Integration Code:

```gdscript
# generated/NetworkSyncRegistry.gd (auto-created by plugin)
# This file is automatically generated from _NETWORKABLE files
extends Node

const NETWORKABLE_ENTITIES = {
    "Player": preload("res://features/multiplayercombat_PROVIDES_networked_fighting_NEEDS_basic_scene/Player_NETWORKABLE_SPAWNABLE.gd"),
    "Block": preload("res://features/worldbuilding_PROVIDES_terrain_editing_NEEDS_basic_scene/Block_NETWORKABLE_PLACEABLE.gd"),
    "PlayerData": preload("res://features/playeridentity_PROVIDES_authentication_NEEDS_nothing/PlayerData_SAVEABLE_NETWORKABLE.gd")
}

func sync_entity(entity_name: String, data: Dictionary):
    if entity_name in NETWORKABLE_ENTITIES:
        var entity_class = NETWORKABLE_ENTITIES[entity_name]
        entity_class.receive_network_update(data)
```

## Feature Composition in Editor

### Visual Recipe Builder Interface:

```
┌─────────────────────────────────────────────────────────┐
│ 🎛️ Semantic Architect                                   │
├─────────────────────────────────────────────────────────┤
│ Available Features:          Current Recipe:            │
│ ┌─────────────────────────┐  ┌─────────────────────────┐ │
│ │ 🥊 multiplayercombat    │  │ 1. ✅ playeridentity    │ │
│ │ 🏗️ worldbuilding        │  │ 2. ⬇️ multiplayercombat  │ │  
│ │ 👤 playeridentity       │  │ 3. ❌ worldbuilding     │ │
│ │ ✨ visualeffects        │  │    (needs entities)      │ │
│ └─────────────────────────┘  └─────────────────────────┘ │
│                                                          │
│ Dependency Graph:                                        │
│ ┌─────────────────────────────────────────────────────┐ │
│ │  playeridentity ──→ multiplayercombat ──→ ❌        │ │
│ │       │                      │                      │ │
│ │       └──────────────────────┼──→ visualeffects     │ │
│ │                              │                      │ │
│ │                              └──→ worldbuilding     │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ 🎯 [Generate Game]  🔧 [Add Custom Feature]             │
└─────────────────────────────────────────────────────────┘
```

## Benefits

### 1. **Natural Feature Grouping**
- No artificial separation between related functionality
- `multiplayercombat` is one cohesive thing, not scattered pieces
- Features work together by design

### 2. **Magic Behavior Without Complexity**  
- Filename tells you what the file does
- No need to remember complex configuration
- Editor automatically handles integration

### 3. **Visual Composition**
- Drag and drop features to build your game
- See dependencies visually
- Impossible combinations prevented automatically

### 4. **Self-Maintaining**
- Plugin keeps everything synchronized
- Magic keywords ensure consistent behavior
- Dependencies tracked automatically

### 5. **Extensible**
- Add new magic keywords anytime
- Create custom features that others can use
- Plugin system handles all the complexity

The filename `Player_NETWORKABLE_SPAWNABLE.gd` **tells the whole story** - it's a Player that can be networked and spawned. The plugin makes it **actually work** without you writing integration code!