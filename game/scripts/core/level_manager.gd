class_name LevelManager
extends Node2D
## Manages level state, connects player and boss, and handles game flow
## This is the COMPLETE WORKING version for ecuador_level

# ===== EXPORTED REFERENCES =====
# Drag and drop these from your scene tree in the Godot editor!
@export_group("Core References")
@export var player: CharacterBody2D  # Your Bolon character
@export var boss: BossEnemy# The boss enemy
@export var camera: Camera2D  # Level camera (not the one in player scene!)
@export var spawn_point: Marker2D  # Where player respawns

# ===== LEVEL STATE =====
var level_started: bool = false
var boss_defeated: bool = false


func _ready() -> void:
    print("=== LEVEL MANAGER STARTING ===")
    _connect_signals()
    _initialize_level()


func _connect_signals() -> void:
    # Connect to game-wide signals
    SignalBus.boss_defeated.connect(_on_boss_defeated)
    SignalBus.player_died.connect(_on_player_died)
    SignalBus.game_over.connect(_on_game_over)
    print("Signals connected")


func _initialize_level() -> void:
    # CRITICAL: Connect boss to player so it can track and shoot at player
    if boss and player:
        boss.set_player_reference(player)
        print("Boss connected to player: ", player.name)
    else:
        push_warning("Missing boss or player reference! Drag them to LevelManager in inspector.")

    # Setup camera to follow player
    if camera and player:
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 5.0
        # Note: You'll need to update camera position in _process or use a camera script
        print("Camera set up")

    # Wait a moment then start
    await get_tree().create_timer(0.5).timeout
    start_level()


func _process(_delta: float) -> void:
    # Simple camera follow (basic implementation)
    if camera and player and is_instance_valid(player):
        camera.global_position = player.global_position


func start_level() -> void:
    if level_started:
        return

    level_started = true
    SignalBus.game_started.emit()
    print("=== LEVEL STARTED ===")
    print("Boss health: ", boss.current_health if boss else "NO BOSS")
    print("Player position: ", player.global_position if player else "NO PLAYER")


# ===== SIGNAL HANDLERS =====
func _on_boss_defeated(boss_name: String) -> void:
    if boss_defeated:
        return

    boss_defeated = true
    print("=== BOSS DEFEATED: ", boss_name, " ===")

    # Wait for death animation
    await get_tree().create_timer(2.0).timeout

    # Complete level
    SignalBus.level_completed.emit()
    print("Level completed!")

    # Victory screen or restart
    await get_tree().create_timer(2.0).timeout
    print("Restarting level...")
    restart_level()


func _on_player_died() -> void:
    print("=== PLAYER DIED ===")

    # You could implement a lives system here
    # For now, just wait and restart
    await get_tree().create_timer(2.0).timeout
    restart_level()


func _on_game_over() -> void:
    print("=== GAME OVER ===")
    await get_tree().create_timer(3.0).timeout
    restart_level()


# ===== UTILITY FUNCTIONS =====
func restart_level() -> void:
    print("Reloading scene...")
    get_tree().reload_current_scene()


func _input(event: InputEvent) -> void:
    # Quick restart for testing (R key)
    if event.is_action_pressed("ui_cancel"):  # ESC key
        restart_level()

    # Pause toggle (P key or Start button)
    if event.is_action_pressed("ui_select"):
        toggle_pause()


func toggle_pause() -> void:
    var is_paused = not get_tree().paused
    get_tree().paused = is_paused
    SignalBus.pause_toggled.emit(is_paused)
    print("Game paused: ", is_paused)
