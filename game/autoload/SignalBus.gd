# This script defines every major cross-component event in the game.
extends Node

# --- Player Signals ---
# Emitted when the player's health changes. Passes new health and max health.
signal health_changed(current_health: int, max_health: int)
# Emitted when the player's lives change.
signal lives_changed(current_lives: int)
# Emitted when the player dies.
signal player_died
# Emitted when the player takes damage, passes the damage source position.
signal player_took_damage(damage_source_position: Vector2)


# --- Gameplay Signals ---
# Emitted when any coin is collected. Passes its value.
signal coin_collected(value: int)
# Emitted to update the total score. Passes the new total score.
signal score_updated(new_score: int)
# Emitted when an enemy is defeated.
signal enemy_defeated(enemy_type: String, position: Vector2)


# --- Game State Signals ---
# Emitted from the main game scene when the game/level begins.
signal game_started
# Emitted when the player loses all lives or chooses to quit.
signal game_over
# Emitted when the player reaches the end of a level.
signal level_completed
# Emitted when the pause menu is toggled.
signal pause_toggled(is_paused: bool)


# --- Boss Signals ---
# Emitted when boss takes damage. Passes boss name, current health, and max health.
signal boss_damaged(boss_name: String, current_health: int, max_health: int)
# Emitted when boss transitions to a new phase. Passes boss name and phase number.
signal boss_phase_changed(boss_name: String, phase: int)
# Emitted when boss starts an attack. Passes boss name and attack type.
signal boss_attack_started(boss_name: String, attack_type: String)
# Emitted when boss finishes an attack. Passes boss name and attack type.
signal boss_attack_finished(boss_name: String, attack_type: String)
# Emitted when boss is defeated. Passes boss name.
signal boss_defeated(boss_name: String)


# --- Projectile Signals ---
# Emitted when a projectile impacts something. Passes impact position.
signal projectile_impact(position: Vector2)
