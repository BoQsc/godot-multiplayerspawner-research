# Entity-First Architecture Proposal

**Core Philosophy**: "Open folder, duplicate scene, modify to create new entity"

## The Copy-to-Create Workflow

Instead of abstract "systems", organize around **concrete entities** that you can see, duplicate, and modify:

```
res://
├── core/
│   ├── GameSession.gd          # Main coordinator
│   ├── GameConfig.gd           # Global settings
│   └── GameEvents.gd           # Event bus
├── entities/
│   ├── player/                 # 👤 PLAYER ENTITY
│   │   ├── Player.tscn         # ⭐ Main scene file
│   │   ├── Player.gd           # Behavior script
│   │   ├── PlayerData.gd       # Data structure
│   │   ├── PlayerSpawner.gd    # How to spawn this entity
│   │   ├── PlayerSaver.gd      # How to save/load this entity
│   │   ├── ui/
│   │   │   ├── PlayerHUD.tscn  # UI that appears with this entity
│   │   │   ├── PlayerList.tscn # UI to manage multiple players
│   │   │   └── PlayerCard.gd   # Reusable player UI component
│   │   └── assets/
│   │       ├── player_sprite.png
│   │       └── player_animations.tres
│   │
│   ├── npc/                    # 🤖 NPC ENTITY (copied from player/)
│   │   ├── NPC.tscn            # ⭐ Duplicated Player.tscn and modified
│   │   ├── NPC.gd              # Started with Player.gd, removed input handling
│   │   ├── NPCData.gd          # Based on PlayerData.gd
│   │   ├── NPCSpawner.gd       # How to spawn NPCs
│   │   ├── NPCSaver.gd         # NPC persistence (simpler than player)
│   │   ├── ai/
│   │   │   ├── AIBehavior.gd   # AI-specific logic
│   │   │   └── PathFollower.gd # Movement AI
│   │   ├── ui/
│   │   │   ├── NPCDialog.tscn  # Interaction UI
│   │   │   └── NPCHealthBar.gd # Simple health display
│   │   └── assets/
│   │       └── npc_sprites/    # Different sprites per NPC type
│   │
│   ├── enemy/                  # 👹 ENEMY ENTITY (copied from npc/)
│   │   ├── Enemy.tscn          # ⭐ Started with NPC.tscn
│   │   ├── Enemy.gd            # Added combat behavior to NPC.gd
│   │   ├── EnemyData.gd        # Added damage, loot to NPCData.gd
│   │   ├── EnemySpawner.gd     # Spawn with combat stats
│   │   ├── combat/
│   │   │   ├── AttackSystem.gd # Combat-specific logic
│   │   │   └── LootDropper.gd  # What enemies drop
│   │   ├── ui/
│   │   │   └── DamageNumbers.gd # Floating damage text
│   │   └── assets/
│   │       └── enemy_sprites/
│   │
│   ├── item/                   # 💎 ITEM ENTITY (much simpler)
│   │   ├── Item.tscn           # ⭐ Simple scene - just sprite + area
│   │   ├── Item.gd             # Pickup logic
│   │   ├── ItemData.gd         # Item stats
│   │   ├── ItemSpawner.gd      # Spawn loot/collectibles
│   │   ├── ui/
│   │   │   ├── ItemTooltip.gd  # Hover information
│   │   │   └── Inventory.gd    # Inventory management
│   │   └── assets/
│   │       └── item_icons/
│   │
│   ├── projectile/             # 🏹 PROJECTILE ENTITY (copied from item/)
│   │   ├── Projectile.tscn     # ⭐ Started with Item.tscn, added movement
│   │   ├── Projectile.gd       # Added physics, collision, damage
│   │   ├── ProjectileData.gd   # Damage, speed, lifetime
│   │   ├── effects/
│   │   │   ├── TrailEffect.gd  # Visual trail
│   │   │   └── ImpactEffect.gd # Explosion/impact
│   │   └── assets/
│   │       ├── arrow.png
│   │       ├── fireball.png
│   │       └── bullet.png
│   │
│   ├── particle_effect/        # ✨ PARTICLE ENTITY (copied from projectile/)
│   │   ├── ParticleEffect.tscn # ⭐ Simple scene with particles
│   │   ├── ParticleEffect.gd   # Lifetime, cleanup
│   │   ├── effects/
│   │   │   ├── ExplosionFX.tscn
│   │   │   ├── HealingFX.tscn
│   │   │   └── MagicFX.tscn
│   │   └── assets/
│   │       └── particle_textures/
│   │
│   └── building/               # 🏠 BUILDING ENTITY (copied from npc/)
│       ├── Building.tscn       # ⭐ Started with NPC.tscn, removed movement
│       ├── Building.gd         # Interaction, doors, functions
│       ├── BuildingData.gd     # What building provides
│       ├── ui/
│       │   ├── ShopUI.tscn     # If it's a shop
│       │   └── CraftingUI.tscn # If it has crafting
│       └── assets/
│           └── building_sprites/
│
├── world/                      # 🌍 WORLD MANAGEMENT
│   ├── WorldSystem.gd          # Coordinate all entities
│   ├── WorldData.gd            # Save all entity states
│   ├── TerrainManager.gd       # Tile-based terrain
│   ├── SpawnPointManager.gd    # Where entities can spawn
│   └── editor/
│       └── WorldEditor.gd      # Editor tools for placing entities
│
├── networking/                 # 🌐 NETWORKING
│   ├── NetworkSystem.gd        # Connection management
│   ├── EntitySynchronizer.gd   # Sync any entity across network
│   └── NetworkData.gd          # Network message formats
│
├── authentication/             # 🔐 AUTH (player-specific)
│   ├── AuthSystem.gd
│   ├── ClientData.gd
│   └── ui/
│       └── LoginDialog.tscn
│
└── ui/                        # 🖥️ GLOBAL UI
    ├── MainMenu.tscn
    ├── SettingsMenu.tscn
    └── shared/
        └── Dialog.gd           # Base classes for entity UIs
```

## The Magic Workflow

### Creating a New Enemy Type:
1. **Copy `entities/npc/` → `entities/goblin/`**
2. **Rename `NPC.tscn` → `Goblin.tscn`**
3. **Open `Goblin.tscn`, change sprite to goblin artwork**
4. **Modify `Goblin.gd` to be more aggressive than base NPC**
5. **Done!** You have a working goblin with all the networking, saving, AI systems already working

### Creating a Magic Projectile:
1. **Copy `entities/projectile/` → `entities/fireball/`**
2. **Open `Fireball.tscn`, change sprite and add fire particles**
3. **Modify `Fireball.gd` to add burn damage over time**
4. **Add explosion effect in `effects/`**
5. **Done!** Networking and physics already work

### Creating a Healing Potion:
1. **Copy `entities/item/` → `entities/health_potion/`**
2. **Change sprite to potion bottle**
3. **Modify pickup behavior to heal player**
4. **Done!** Inventory integration already works

## Entity Template Structure

Each entity folder follows the same predictable pattern:

```
entities/ENTITY_NAME/
├── ENTITY_NAME.tscn           # ⭐ The main scene file
├── ENTITY_NAME.gd             # Core behavior script
├── ENTITY_NAMEData.gd         # Data structure/stats
├── ENTITY_NAMESpawner.gd      # How to create this entity
├── ENTITY_NAMESaver.gd        # How to persist this entity (optional)
├── ui/                        # UI specific to this entity
│   ├── ENTITY_NAMETooltip.gd
│   └── ENTITY_NAMEDialog.tscn
├── assets/                    # Visual/audio assets
│   ├── sprites/
│   ├── sounds/
│   └── animations/
└── special_systems/           # Entity-specific subsystems
    └── (varies by entity type)
```

## Base Entity Classes

To avoid duplicating common code, use inheritance:

```gdscript
# entities/base/BaseEntity.gd
extends Node2D
class_name BaseEntity

@export var entity_data: BaseEntityData
var spawner: BaseSpawner
var network_id: int = -1

func _ready():
    setup_networking()
    setup_persistence()

func spawn_at(pos: Vector2, data: BaseEntityData):
    position = pos
    entity_data = data
    apply_data()

func save_state() -> Dictionary:
    return entity_data.to_dict()

func load_state(data: Dictionary):
    entity_data.from_dict(data)
    apply_data()

# Override in specific entities
func apply_data(): pass
```

```gdscript
# entities/player/Player.gd
extends BaseEntity
class_name Player

func apply_data():
    super.apply_data()
    health = entity_data.health
    level = entity_data.level
    # Player-specific setup

func handle_input():
    # Player-only input handling
    pass
```

```gdscript
# entities/npc/NPC.gd  
extends BaseEntity
class_name NPC

func apply_data():
    super.apply_data() 
    # NPC gets most functionality from BaseEntity
    setup_ai()

func setup_ai():
    # NPC-specific AI
    pass
```

## Universal Systems Work With Any Entity

### NetworkSystem.gd
```gdscript
func sync_entity(entity: BaseEntity):
    # Works with any entity automatically
    rpc("update_entity", entity.network_id, entity.save_state())
```

### WorldSystem.gd  
```gdscript
func spawn_entity(entity_type: String, position: Vector2, data: Dictionary):
    # Can spawn any entity type dynamically
    var entity_scene = load("res://entities/" + entity_type + "/" + entity_type.capitalize() + ".tscn")
    var entity = entity_scene.instantiate()
    entity.spawn_at(position, data)
    get_tree().current_scene.add_child(entity)
```

## Benefits of Entity-First Architecture

### 1. **Intuitive Mental Model**
- "I want a new enemy" → look in `entities/`, copy existing enemy
- "How do projectiles work?" → open `entities/projectile/`
- "Player UI not working" → it's in `entities/player/ui/`

### 2. **Rapid Prototyping**
- Copy existing entity → tweak → done
- No need to understand complex systems
- Artists can duplicate entities and change assets independently

### 3. **Self-Contained Features**
- Everything for an entity is in one place
- Delete entity folder = completely remove feature
- Easy to backup/share specific entity types

### 4. **Team-Friendly**
- Designer works on `entities/npc/`
- Programmer works on `entities/player/`  
- No merge conflicts, clear ownership

### 5. **Modding-Friendly**
- Modders can add new entity types by copying existing folders
- Clear template for how entities should be structured
- Assets and code are co-located

### 6. **Visual Development**
- Each entity has a `.tscn` file you can open and see immediately
- No abstract "systems" - everything is concrete and visual
- Scene tree shows you exactly how entity is structured

## Migration Strategy

### Phase 1: Extract Player Entity
1. Create `entities/player/` folder
2. Move all player-related code there
3. Keep existing interfaces working

### Phase 2: Extract World as Foundation  
1. Create `entities/world/` folder
2. Move terrain and world management
3. Make it work with entity spawning

### Phase 3: Create First Duplicatable Entity
1. Create `entities/npc/` by copying and simplifying `entities/player/`
2. Remove input handling, add basic AI
3. Test that copying the folder creates new NPC types

### Phase 4: Expand Entity Types
1. Create remaining entity types by copying existing ones
2. Extract common functionality to BaseEntity
3. Migrate existing systems to work with entity model

---

**The Result**: A codebase that matches how game developers actually think and work - with concrete, duplicatable, self-contained entities rather than abstract systems.