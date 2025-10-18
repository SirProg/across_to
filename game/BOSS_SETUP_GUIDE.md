# Boss Enemy Setup Guide

Complete guide for implementing the boss enemy system in your Godot 2D platformer.

---

## Architecture Overview

The boss system follows a **modular, state-driven architecture**:

```
BossEnemy (CharacterBody2D)
├── Inherits from: EnemyBase
├── Uses: StateMachine for AI behavior
├── Components: HealthComponent (optional)
├── Spawns: Projectiles for ranged attacks
└── Signals: SignalBus for game-wide events
```

---

## Files Created

### Core Scripts

| File | Location | Purpose |
|------|----------|---------|
| `enemy_base.gd` | `/game/scripts/enemies/` | Base class for all enemies |
| `boss_enemy.gd` | `/game/scripts/enemies/` | Boss-specific logic and attacks |
| `projectile.gd` | `/game/scripts/enemies/` | Projectile for ranged attacks |
| `state_machine.gd` | `/game/scripts/utils/` | Generic FSM for AI |
| `state.gd` | `/game/scripts/utils/` | Base state class |
| `health_component.gd` | `/game/scripts/systems/` | Reusable health system |
| `SignalBus.gd` | `/game/autoload/` | Updated with boss signals |

---

## Scene Setup Instructions

### Step 1: Create Projectile Scene

**File**: `game/scenes/enemies/Projectile.tscn`

1. Create new scene with `Area2D` as root
2. Add these nodes:
```
Projectile (Area2D) [attach projectile.gd]
├── Sprite2D
│   └── Texture: Create a simple circle/bullet sprite
└── CollisionShape2D
	└── Shape: CircleShape2D (radius: 8-16)
```

3. **Configure Area2D**:
   - Collision Layer: 4 (Projectile)
   - Collision Mask: 1 (Player)

4. **Configure Sprite2D**:
   - Set a simple texture (can be a colored circle for prototyping)
   - Default color will be overridden by script

5. Save as `Projectile.tscn`

---

### Step 2: Create Boss Scene

**File**: `game/scenes/enemies/Boss.tscn`

1. Create new scene with `CharacterBody2D` as root
2. Attach `boss_enemy.gd` script
3. Add these nodes:

```
Boss (CharacterBody2D) [attach boss_enemy.gd]
├── Sprite2D
│   └── Texture: Boss sprite (placeholder: 128x128 colored square)
├── CollisionShape2D
│   └── Shape: RectangleShape2D or CapsuleShape2D
├── AnimationPlayer (optional but recommended)
├── MeleeHitbox (Area2D) [optional visual indicator]
│   ├── CollisionShape2D
│   │   └── Shape: CircleShape2D (disabled by default)
│   └── DebugVisual (Polygon2D) [optional]
└── ShockwaveIndicator (Area2D) [optional visual indicator]
	├── CollisionShape2D
	│   └── Shape: CircleShape2D (disabled by default)
	└── DebugVisual (Polygon2D) [optional]
```

4. **Configure CharacterBody2D** (Boss):
   - Motion Mode: Floating (or Grounded if boss walks on ground)
   - Collision Layer: 2 (Enemy)
   - Collision Mask: 1 (Player) + 8 (World/Platforms)

5. **Configure Sprite2D**:
   - Texture: Boss sprite sheet or placeholder
   - Size: 128x128 or larger

6. **Set Boss Script Parameters**:
   - `boss_name`: "Guardian Boss" (or your boss name)
   - `projectile_scene`: Drag `Projectile.tscn` here
   - Configure attack parameters as needed

7. Save as `Boss.tscn`

---

## Boss Configuration

### Script Parameters (Export Variables)

#### Boss Stats
```gdscript
@export var boss_name: String = "Guardian Boss"
@export var phase_transition_invulnerability: float = 2.0
@export var min_attack_distance: float = 100.0
@export var max_attack_distance: float = 400.0
```

#### Attack Timing
```gdscript
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 2.5
@export var attack_cooldown: float = 1.5
```

#### Melee Attack
```gdscript
@export var melee_damage: int = 20
@export var melee_range: float = 150.0
@export var melee_telegraph_time: float = 0.5
@export var melee_active_time: float = 0.3
```

#### Ranged Attack
```gdscript
@export var projectile_damage: int = 15
@export var projectile_speed: float = 300.0
@export var projectile_count_phase1: int = 1
@export var projectile_count_phase2: int = 3
@export var projectile_count_phase3: int = 5
```

#### Area Attack
```gdscript
@export var shockwave_damage: int = 25
@export var shockwave_radius: float = 250.0
@export var shockwave_telegraph_time: float = 0.8
@export var shockwave_active_time: float = 0.4
```

#### Dash Attack
```gdscript
@export var dash_speed: float = 600.0
@export var dash_damage: int = 30
@export var dash_duration: float = 0.5
```

---

## Integration with Game

### 1. Add Boss to Level

In your level scene (`game/scenes/levels/Level1.tscn` or similar):

1. Instance `Boss.tscn`
2. Position the boss where you want it to spawn
3. Set up player reference via script:

```gdscript
# In your level or game manager script
@onready var boss = $Boss
@onready var player = $Player

func _ready():
	boss.set_player_reference(player)
```

---

### 2. Connect to UI/HUD

Listen to boss signals for UI updates:

```gdscript
# In your HUD script (game/scripts/ui/hud.gd or similar)
func _ready():
	SignalBus.boss_damaged.connect(_on_boss_damaged)
	SignalBus.boss_phase_changed.connect(_on_boss_phase_changed)
	SignalBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_damaged(boss_name: String, current_health: int, max_health: int):
	# Update boss health bar
	var percentage = float(current_health) / float(max_health)
	$BossHealthBar.value = percentage

func _on_boss_phase_changed(boss_name: String, phase: int):
	# Show phase transition notification
	print("%s entered Phase %d!" % [boss_name, phase])

func _on_boss_defeated(boss_name: String):
	# Show victory screen
	SignalBus.level_completed.emit()
```

---

### 3. Audio Integration

Connect attack signals to audio:

```gdscript
# In your AudioManager (game/scripts/core/audio_manager.gd)
func _ready():
	SignalBus.boss_attack_started.connect(_on_boss_attack_started)
	SignalBus.projectile_impact.connect(_on_projectile_impact)

func _on_boss_attack_started(boss_name: String, attack_type: String):
	match attack_type:
		"melee_slam":
			play_sfx("boss_slam")
		"ranged_projectile":
			play_sfx("boss_projectile_shoot")
		"area_shockwave":
			play_sfx("boss_shockwave")
		"dash_attack":
			play_sfx("boss_dash")

func _on_projectile_impact(position: Vector2):
	play_sfx("projectile_hit")
```

---

## Boss Behavior Explained

### State Machine Flow

```
Idle State
	↓
	├─→ Chase State (player far away)
	│       ↓
	│   Attack State (in range)
	│       ↓
	│   Back to Idle
	│
	└─→ Attack State (already in range)
			↓
		Back to Idle
```

### Phase System

The boss has **3 phases** based on health:

| Phase | Health Range | Behavior |
|-------|--------------|----------|
| **Phase 1** | 100% - 66% | Basic attacks, slower patterns |
| **Phase 2** | 66% - 33% | Mixed attacks, faster movement |
| **Phase 3** | 33% - 0% | All attacks available, aggressive |

**Phase Transitions**:
- Boss becomes invulnerable for 2 seconds
- Signal emitted: `SignalBus.boss_phase_changed`
- Use this for visual effects, camera shake, etc.

---

### Attack Types

#### 1. **Melee Slam** (AttackType.MELEE_SLAM)
- **Range**: 150 units
- **Damage**: 20
- **Telegraph Time**: 0.5s (warning before attack)
- **Active Time**: 0.3s (damage window)
- **Usage**: When player is close

**Implementation**:
- Uses `PhysicsShapeQueryParameters2D` for circular area check
- Damages all entities in range with `take_damage()` method

#### 2. **Ranged Projectile** (AttackType.RANGED_PROJECTILE)
- **Projectiles**: 1 (Phase 1), 3 (Phase 2), 5 (Phase 3)
- **Speed**: 300 units/second
- **Damage**: 15 per projectile
- **Pattern**: Spread (multiple) or aimed (single)
- **Usage**: When player is far away

**Implementation**:
- Spawns projectile instances from `projectile_scene`
- Phase 1: Single aimed projectile
- Phase 2/3: Radial spread pattern

#### 3. **Area Shockwave** (AttackType.AREA_SHOCKWAVE)
- **Radius**: 250 units
- **Damage**: 25
- **Telegraph Time**: 0.8s (longer warning)
- **Active Time**: 0.4s
- **Usage**: Mixed with melee in Phase 2+

**Implementation**:
- Circular AoE damage using physics queries
- Long telegraph allows skilled players to dodge

#### 4. **Dash Attack** (AttackType.DASH_ATTACK)
- **Speed**: 600 units/second
- **Damage**: 30
- **Duration**: 0.5s
- **Usage**: Phase 3 when player is very far

**Implementation**:
- Boss rapidly dashes toward player
- Deals damage on collision
- High risk, high reward for boss

---

## Attack Selection Logic

The boss intelligently chooses attacks based on:
1. **Current Phase** (1, 2, or 3)
2. **Distance to Player**
3. **Random variation** (keeps fights interesting)

### Phase 1 (100-66% Health)
```
IF player within 225 units:
	→ Melee Slam
ELSE:
	→ Ranged Projectile
```

### Phase 2 (66-33% Health)
```
IF player within 225 units:
	→ Random: Melee Slam OR Area Shockwave
ELSE:
	→ Ranged Projectile (3 projectiles)
```

### Phase 3 (33-0% Health)
```
IF player within 150 units:
	→ Random: Melee Slam OR Area Shockwave
ELSE IF player beyond 400 units:
	→ Dash Attack
ELSE:
	→ Random: Ranged Projectile (5 projectiles) OR Dash Attack
```

---

## Signals Reference

### Boss Signals (Added to SignalBus)

```gdscript
# Emitted when boss takes damage
signal boss_damaged(boss_name: String, current_health: int, max_health: int)

# Emitted on phase transition
signal boss_phase_changed(boss_name: String, phase: int)

# Emitted at start of attack (telegraph phase)
signal boss_attack_started(boss_name: String, attack_type: String)

# Emitted when attack completes
signal boss_attack_finished(boss_name: String, attack_type: String)

# Emitted when boss dies
signal boss_defeated(boss_name: String)

# Emitted when projectile hits something
signal projectile_impact(position: Vector2)
```

### Usage Examples

```gdscript
# Update boss health bar
SignalBus.boss_damaged.connect(func(name, health, max_health):
	boss_health_bar.value = float(health) / float(max_health)
)

# Camera shake on phase change
SignalBus.boss_phase_changed.connect(func(name, phase):
	camera.shake(1.0, 20.0)
)

# Show attack warning
SignalBus.boss_attack_started.connect(func(name, type):
	show_warning_text(type)
)
```

---

## Testing the Boss

### Quick Test Scene Setup

1. Create `game/scenes/levels/BossTest.tscn`
2. Add:
   - TileMap or ground platform
   - Boss instance
   - Player instance
3. Connect player reference:

```gdscript
# BossTest scene script
extends Node2D

func _ready():
	$Boss.set_player_reference($Player)
```

4. Run scene to test boss behavior

---

## Customization Tips

### Easy Difficulty Adjustments

**Easier Boss**:
```gdscript
melee_damage = 10          # Lower damage
attack_cooldown = 3.0      # Longer cooldown
melee_telegraph_time = 1.0 # Longer warning
projectile_speed = 200.0   # Slower projectiles
```

**Harder Boss**:
```gdscript
melee_damage = 30          # Higher damage
attack_cooldown = 0.8      # Shorter cooldown
melee_telegraph_time = 0.2 # Shorter warning
dash_speed = 800.0         # Faster dash
```

### Adding New Attack Types

1. Add enum entry:
```gdscript
enum AttackType {
	MELEE_SLAM,
	RANGED_PROJECTILE,
	AREA_SHOCKWAVE,
	DASH_ATTACK,
	YOUR_NEW_ATTACK  # Add here
}
```

2. Implement attack method:
```gdscript
func _execute_your_new_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "your_new_attack")
	# Your attack logic here
	await get_tree().create_timer(1.0).timeout
	SignalBus.boss_attack_finished.emit(boss_name, "your_new_attack")
	state_machine.transition_to("Idle")
```

3. Add to attack selection in `choose_attack()`

---

## Animation Integration (Optional)

If using AnimationPlayer:

```gdscript
# In boss_enemy.gd, modify attack methods:
func _execute_melee_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "melee_slam")

	# Play telegraph animation
	if $AnimationPlayer.has_animation("melee_telegraph"):
		$AnimationPlayer.play("melee_telegraph")

	await get_tree().create_timer(melee_telegraph_time).timeout

	# Play attack animation
	if $AnimationPlayer.has_animation("melee_attack"):
		$AnimationPlayer.play("melee_attack")

	var hits = _check_melee_hit()
	await get_tree().create_timer(melee_active_time).timeout

	SignalBus.boss_attack_finished.emit(boss_name, "melee_slam")
	state_machine.transition_to("Idle")
```

---

## Collision Layers Reference

Recommended setup:

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | Player | Player character |
| 2 | Enemy | Enemies and boss |
| 4 | Projectile | Enemy projectiles |
| 8 | World | Platforms and walls |

**Boss Settings**:
- Collision Layer: 2 (Enemy)
- Collision Mask: 1 (Player) + 8 (World)

**Projectile Settings**:
- Collision Layer: 4 (Projectile)
- Collision Mask: 1 (Player)

---

## Performance Optimization

For a 48-hour game jam:

1. **Limit projectile count**: Max 10 active projectiles
2. **Use object pooling** (optional): Reuse projectiles instead of creating new ones
3. **Disable off-screen**: Pause boss when not visible
4. **Simple visuals**: Use basic shapes/sprites during development

---

## Common Issues & Solutions

### Boss doesn't attack
- **Check**: Player reference is set via `set_player_reference()`
- **Check**: `projectile_scene` is assigned in inspector
- **Check**: Boss is not stuck in Phase Transition state

### Projectiles don't damage player
- **Check**: Collision layers (Projectile layer 4, mask 1)
- **Check**: Player has `take_damage()` method
- **Check**: CollisionShape2D is enabled on projectile

### Boss takes no damage
- **Check**: Player attacks set correct collision layer
- **Check**: Boss's `take_damage()` is being called
- **Check**: Boss is not stuck in invulnerable state

### State machine not working
- **Check**: StateMachine node is added as child of Boss
- **Check**: State nodes are children of StateMachine
- **Check**: `initial_state` is set correctly

---

## Next Steps

1. **Create projectile scene** → Test basic projectile spawning
2. **Create boss scene** → Test with placeholder sprites
3. **Add to level** → Wire up player reference
4. **Create boss health UI** → Connect to signals
5. **Add visual effects** → Use signals for particles/screen shake
6. **Polish animations** → Add AnimationPlayer sequences
7. **Balance difficulty** → Tweak export parameters

---

## File Structure Summary

```
game/
├── autoload/
│   └── SignalBus.gd                    ✅ Updated with boss signals
├── scripts/
│   ├── enemies/
│   │   ├── enemy_base.gd              ✅ Base class
│   │   ├── boss_enemy.gd              ✅ Boss implementation
│   │   └── projectile.gd              ✅ Projectile
│   ├── systems/
│   │   └── health_component.gd        ✅ Reusable health system
│   └── utils/
│       ├── state_machine.gd           ✅ FSM
│       └── state.gd                   ✅ Base state
└── scenes/
    └── enemies/
        ├── Boss.tscn                  ⏳ Create this
        └── Projectile.tscn            ⏳ Create this
```

---

## Architecture Highlights

### ✅ Modular Design
- Boss inherits from EnemyBase (code reuse)
- State machine is generic (reusable for other enemies)
- HealthComponent can be used for player, enemies, destructibles

### ✅ Event-Driven
- All major events emit signals through SignalBus
- Decoupled systems (UI, audio, effects)
- Easy to add new listeners without modifying boss code

### ✅ Expert Patterns
- **State Pattern**: Clean AI behavior management
- **Strategy Pattern**: Different attacks via enum
- **Component Pattern**: Health as separate component
- **Observer Pattern**: SignalBus for communication

### ✅ Game Jam Friendly
- Configurable via export variables (no code changes needed)
- Easy to balance (tweak numbers in inspector)
- Fast iteration (add/remove attacks easily)
- Scalable (add more bosses by inheriting)

---

## Quick Start Checklist

- [ ] Create `Projectile.tscn` scene
- [ ] Create `Boss.tscn` scene
- [ ] Assign `projectile_scene` in Boss inspector
- [ ] Add boss to level scene
- [ ] Set player reference in level script
- [ ] Create boss health bar UI
- [ ] Connect signals to UI/audio
- [ ] Test all 4 attack types
- [ ] Test phase transitions (damage boss to 66%, 33%)
- [ ] Balance difficulty via inspector parameters

---

**You're ready to create an epic boss fight!** 🎮

This architecture provides a solid foundation that's both professional and practical for a 48-hour game jam.
