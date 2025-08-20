# Composable Architecture: Best of Both Worlds

**Problem with Copy-Everything**: Divergent evolution leads to maintenance hell  
**Problem with Traditional**: Hard to understand, modify, or extend  
**Solution**: Composable modules that **evolve together** but **combine differently**

## Core Principle: Shared Building Blocks

Instead of copying entire folders, create **small, focused modules** that can be mixed and matched but **share improvements** across all combinations.

```
res://
├── core/
│   └── GameComposer.gd         # Assembles modules into complete games
│
├── modules/                    # 🧩 LEGO-LIKE BUILDING BLOCKS
│   ├── entities/               # Shared entity types that evolve together
│   │   ├── base/               # Base classes that improve for everyone
│   │   │   ├── BaseEntity.gd   # ⭐ Core entity functionality
│   │   │   ├── BaseMovable.gd  # Movement, physics, collision
│   │   │   ├── BaseCombat.gd   # Health, damage, death
│   │   │   └── BaseNetworked.gd # Network sync, persistence
│   │   ├── player/
│   │   │   ├── PlayerEntity.gd # extends BaseMovable + BaseCombat + BaseNetworked
│   │   │   ├── PlayerInput.gd  # Input handling module
│   │   │   └── PlayerUI.gd     # Player-specific UI
│   │   ├── projectile/
│   │   │   ├── ProjectileEntity.gd # extends BaseMovable
│   │   │   ├── ProjectileTrail.gd  # Visual effects module
│   │   │   └── ProjectileDamage.gd # Damage dealing module
│   │   ├── building/
│   │   │   ├── BuildingEntity.gd   # extends BaseEntity + BaseCombat
│   │   │   ├── BuildingPlacer.gd   # Placement logic module
│   │   │   └── BuildingShop.gd     # Purchase/upgrade module
│   │   └── npc/
│   │       ├── NPCEntity.gd     # extends BaseMovable + BaseCombat
│   │       ├── NPCAIBasic.gd    # Simple AI module
│   │       └── NPCAIAdvanced.gd # Complex AI module
│   │
│   ├── gameplay/               # Game mechanics that can be mixed/matched
│   │   ├── health/
│   │   │   ├── HealthSystem.gd      # ⭐ Core health mechanics
│   │   │   ├── HealthRegeneration.gd # Health over time
│   │   │   └── HealthPotions.gd     # Consumable healing
│   │   ├── combat/
│   │   │   ├── MeleeCombat.gd       # Sword/melee fighting
│   │   │   ├── RangedCombat.gd      # Bow/gun fighting  
│   │   │   └── MagicCombat.gd       # Spell casting
│   │   ├── movement/
│   │   │   ├── WalkingMovement.gd   # Standard 2D movement
│   │   │   ├── FlyingMovement.gd    # Flying entities
│   │   │   └── VehicleMovement.gd   # Cars, tanks, etc.
│   │   ├── resources/
│   │   │   ├── ResourceGathering.gd # Mining, chopping, etc.
│   │   │   ├── ResourceCrafting.gd  # Combining resources
│   │   │   └── ResourceTrading.gd   # Buying/selling
│   │   ├── progression/
│   │   │   ├── LevelingSystem.gd    # XP and levels
│   │   │   ├── SkillTrees.gd        # Branching upgrades
│   │   │   └── AchievementSystem.gd # Goals and rewards
│   │   └── environmental/
│   │       ├── DayNightCycle.gd     # Time progression
│   │       ├── WeatherSystem.gd     # Rain, snow, etc.
│   │       └── SeasonalChanges.gd   # Seasonal effects
│   │
│   ├── networking/             # Network modules that work together
│   │   ├── connection/
│   │   │   ├── ConnectionManager.gd # ⭐ Core connection handling
│   │   │   ├── ENetProvider.gd      # ENet implementation
│   │   │   ├── WebSocketProvider.gd # WebSocket implementation
│   │   │   └── LocalProvider.gd     # Local/offline "networking"
│   │   ├── synchronization/
│   │   │   ├── EntitySync.gd        # Sync any entity
│   │   │   ├── WorldSync.gd         # Sync world changes
│   │   │   └── EventSync.gd         # Sync game events
│   │   └── persistence/
│   │       ├── PlayerPersistence.gd # Save/load players
│   │       ├── WorldPersistence.gd  # Save/load world
│   │       └── GameStatePersistence.gd # Save/load game state
│   │
│   ├── ui/                     # UI modules that adapt to any game
│   │   ├── core/
│   │   │   ├── UIManager.gd         # ⭐ UI system coordinator
│   │   │   ├── Dialog.gd            # Base dialog class
│   │   │   └── Panel.gd             # Base panel class
│   │   ├── player_ui/
│   │   │   ├── HealthBar.gd         # Works with any health system
│   │   │   ├── InventoryPanel.gd    # Works with any inventory
│   │   │   └── SkillTreePanel.gd    # Works with any progression
│   │   ├── game_ui/
│   │   │   ├── MinimapPanel.gd      # Works with any world type
│   │   │   ├── ChatPanel.gd         # Works with any networking
│   │   │   └── ScoreboardPanel.gd   # Works with any scoring system
│   │   └── menu_ui/
│   │       ├── MainMenu.gd          # Adapts to available game modes
│   │       ├── SettingsMenu.gd      # Adapts to available settings
│   │       └── PauseMenu.gd         # Works with any game state
│   │
│   ├── world/                  # World modules that combine
│   │   ├── terrain/
│   │   │   ├── TerrainRenderer.gd   # ⭐ How terrain looks
│   │   │   ├── TerrainPhysics.gd    # How terrain behaves
│   │   │   └── TerrainModifier.gd   # How terrain changes
│   │   ├── generation/
│   │   │   ├── StaticGeneration.gd  # Pre-made levels
│   │   │   ├── RandomGeneration.gd  # Procedural levels  
│   │   │   └── WaveGeneration.gd    # Spawning waves of enemies
│   │   └── persistence/
│   │       ├── FullPersistence.gd   # Save everything
│   │       ├── PlayerOnlyPersistence.gd # Save just players
│   │       └── NoPersistence.gd     # Nothing saved
│   │
│   └── audio/                  # Audio modules
│       ├── music/
│       │   ├── BackgroundMusic.gd   # Adaptive background music
│       │   └── DynamicMusic.gd      # Music that reacts to gameplay
│       └── effects/
│           ├── SpatialAudio.gd      # 3D positioned sounds
│           └── UIAudio.gd           # Menu/UI sounds
│
└── games/                      # 🎮 SPECIFIC GAME CONFIGURATIONS
    ├── multiplayer_survival/   # ⭐ Your current game - just configuration!
    │   ├── MultiplayerSurvival.gd   # Composes modules together
    │   ├── config/
    │   │   ├── entities.gd          # Which entities to include
    │   │   ├── gameplay.gd          # Which gameplay modules
    │   │   ├── networking.gd        # Which network modules  
    │   │   ├── ui.gd                # Which UI modules
    │   │   └── world.gd             # Which world modules
    │   └── assets/                  # Game-specific art/sound
    │       ├── sprites/
    │       └── sounds/
    │
    ├── tower_defense/          # Different combination of same modules
    │   ├── TowerDefense.gd     # Different module composition
    │   ├── config/
    │   │   ├── entities.gd     # building + npc + projectile modules
    │   │   ├── gameplay.gd     # combat + resources modules (no leveling)
    │   │   ├── networking.gd   # local or multiplayer options
    │   │   ├── ui.gd           # game_ui + menu_ui (no inventory ui)
    │   │   └── world.gd        # static generation + no persistence
    │   └── assets/
    │       ├── tower_sprites/
    │       └── tower_sounds/
    │
    ├── battle_royale/          # Another combination
    │   ├── BattleRoyale.gd
    │   ├── config/
    │   │   ├── entities.gd     # player + projectile + loot modules
    │   │   ├── gameplay.gd     # combat + movement (no crafting/building)
    │   │   ├── networking.gd   # high-performance networking modules
    │   │   ├── ui.gd           # player_ui + game_ui (different layout)
    │   │   └── world.gd        # random generation + no persistence
    │   └── assets/             # Modern military theme
    │
    └── single_player_rpg/
        ├── SinglePlayerRPG.gd
        ├── config/
        │   ├── entities.gd     # player + npc + all entity types
        │   ├── gameplay.gd     # ALL gameplay modules for rich RPG
        │   ├── networking.gd   # local provider (no networking)
        │   ├── ui.gd           # ALL UI modules for complex interface
        │   └── world.gd        # full persistence + static generation
        └── assets/             # Fantasy RPG theme
```

## How Game Assembly Works

### Each Game is Just a Recipe:
```gdscript
# games/tower_defense/TowerDefense.gd
extends Node
class_name TowerDefense

func _ready():
    # Load the modules this game needs
    var entity_config = preload("res://games/tower_defense/config/entities.gd").new()
    var gameplay_config = preload("res://games/tower_defense/config/gameplay.gd").new()
    var world_config = preload("res://games/tower_defense/config/world.gd").new()
    
    # Compose the game from modules
    GameComposer.create_game(self, {
        "entities": entity_config.get_entities(),
        "gameplay": gameplay_config.get_gameplay_modules(),
        "world": world_config.get_world_modules(),
        "networking": ["local_provider"], # Tower defense can be single player
        "ui": ["game_ui/minimap", "game_ui/scoreboard", "menu_ui/pause"]
    })
```

### Configuration Files Are Simple Lists:
```gdscript
# games/tower_defense/config/entities.gd
extends Resource

func get_entities() -> Array[String]:
    return [
        "entities/building",    # Towers are buildings
        "entities/npc",         # Enemies are NPCs with AI
        "entities/projectile",  # Towers shoot projectiles
    ]
```

```gdscript
# games/tower_defense/config/gameplay.gd
extends Resource

func get_gameplay_modules() -> Array[String]:
    return [
        "gameplay/combat/ranged_combat",     # Towers shoot at enemies
        "gameplay/resources/resource_gathering", # Earn money from kills
        "gameplay/environmental/wave_spawner",   # Enemies come in waves
        # No leveling, no crafting, no trading for tower defense
    ]
```

### GameComposer Assembles Everything:
```gdscript
# core/GameComposer.gd
extends Node
class_name GameComposer

static func create_game(game_node: Node, config: Dictionary):
    # Load and instantiate each requested module
    for entity_type in config.entities:
        var entity_module = load("res://modules/" + entity_type + "/" + entity_type.get_file().capitalize() + ".gd")
        game_node.add_child(entity_module.new())
    
    for gameplay_module in config.gameplay:
        var module = load("res://modules/" + gameplay_module + ".gd")
        game_node.add_child(module.new())
    
    # Connect modules together
    connect_modules(game_node)
```

## The Magic: Shared Evolution

### When you improve BaseEntity.gd:
- ✅ **Multiplayer Survival** gets better entities
- ✅ **Tower Defense** gets better entities  
- ✅ **Battle Royale** gets better entities
- ✅ **Single Player RPG** gets better entities

### When you add a new feature to RangedCombat.gd:
- ✅ **Tower Defense** gets better tower shooting
- ✅ **Battle Royale** gets better gun combat
- ✅ **Single Player RPG** gets better archery
- ❌ **Multiplayer Survival** doesn't get it (because it only uses MeleeCombat)

### When you create a completely new module:
```gdscript
# modules/gameplay/magic/SpellCasting.gd - brand new magic system
```
- Any game can add `"gameplay/magic/spell_casting"` to their config
- All existing games continue working unchanged
- New games can use magic from day one

## Benefits Over Copy-Everything

### 1. **Shared Improvements**
- Fix a bug once → fixed everywhere that uses that module
- Add a feature once → available everywhere it makes sense
- Optimize performance once → everyone gets faster

### 2. **Modular Complexity**
- Simple games use few modules (tower defense = 6 modules)
- Complex games use many modules (RPG = 20+ modules)
- Each module stays focused and understandable

### 3. **Safe Experimentation**
- Want to try a new AI system? Create `NPCAIExperimental.gd`
- Games can opt-in by changing their config
- No risk to existing games using `NPCAIBasic.gd`

### 4. **Clear Dependencies**
- Each module declares what it needs
- GameComposer ensures compatible combinations
- Impossible combinations are caught early

### 5. **Team Scaling**
- Person A improves the networking modules → everyone benefits
- Person B adds new gameplay modules → available to all games
- Person C creates new game → uses existing, proven modules

## Example: Adding New Feature

### Old Way (Copy-Everything):
1. Add feature to one game
2. Manually copy to 3 other games
3. Each copy diverges slightly  
4. Bug found in one → must fix in all 4 places
5. Eventually only one game has the good version

### New Way (Composable):
1. Add feature as new module: `modules/gameplay/inventory/AdvancedCrafting.gd`
2. Any game wanting advanced crafting adds it to their config
3. Bug found → fix in one place → fixed everywhere
4. All games can benefit from the improvement

## Migration Strategy

### Phase 1: Extract Base Classes
- Create `modules/entities/base/BaseEntity.gd`
- Make existing Player.gd extend BaseEntity
- No functional changes, just better structure

### Phase 2: Extract Gameplay Modules  
- Create `modules/gameplay/combat/MeleeCombat.gd`
- Move combat logic from Player.gd to the module
- Player.gd becomes mostly a composition of modules

### Phase 3: Create Game Configurations
- Create `games/multiplayer_survival/config/` files
- List which modules the current game uses
- GameComposer assembles the same functionality

### Phase 4: Add New Games
- Create new game configs that mix modules differently
- Reuse 80% of existing code, customize 20%
- All games benefit from ongoing module improvements

---

**The Result**: You get the **flexibility** of copy-everything with the **maintainability** of shared code. Each game is different, but improvements flow to all games automatically.