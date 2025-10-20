class_name BossEnemy
extends EnemyBase
## Boss enemy with multiple attack patterns and phases
## Uses state machine for AI behavior and health-based phase transitions
## Attacks: Melee slam, ranged projectiles, and area-of-effect attacks


enum AttackType {
	MELEE_SLAM,
	RANGED_PROJECTILE,
	AREA_SHOCKWAVE,
	DASH_ATTACK
}

enum BossPhase {
	PHASE_1,  ## 100%-66% health: Basic attacks
	PHASE_2,  ## 66%-33% health: Faster, mixed attacks
	PHASE_3   ## 33%-0% health: Aggressive, all attacks
}

@export_group("Boss Stats")
@export var boss_name: String = "Guardian Boss"
@export var phase_transition_invulnerability: float = 2.0
@export var min_attack_distance: float = 100.0
@export var max_attack_distance: float = 400.0

@export_group("Attack Timing")
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 2.5
@export var attack_cooldown: float = 1.5

@export_group("Melee Attack")
@export var melee_damage: int = 20
@export var melee_range: float = 150.0
@export var melee_telegraph_time: float = 0.5
@export var melee_active_time: float = 0.3

@export_group("Ranged Attack")
@export var projectile_damage: int = 15
@export var projectile_speed: float = 300.0
@export var projectile_count_phase1: int = 1
@export var projectile_count_phase2: int = 3
@export var projectile_count_phase3: int = 5

@export_group("Area Attack")
@export var shockwave_damage: int = 25
@export var shockwave_radius: float = 250.0
@export var shockwave_telegraph_time: float = 0.8
@export var shockwave_active_time: float = 0.4

@export_group("Dash Attack")
@export var dash_speed: float = 600.0
@export var dash_damage: int = 30
@export var dash_duration: float = 0.5

@export_group("Projectile Scene")
@export var projectile_scene: PackedScene = preload("uid://dv4hyog1dbkri")

var current_phase: BossPhase = BossPhase.PHASE_1
var state_machine: StateMachine
var attack_cooldown_timer: Timer
var can_attack: bool = true


func _on_ready() -> void:
	super._on_ready()  # Call parent's _on_ready if it exists
	print("🔴 BOSS: Starting initialization - ", boss_name)
	_setup_boss_specific()
	_setup_state_machine()
	_setup_attack_cooldown()
	print("🔴 BOSS: Initialization complete")


func _setup_boss_specific() -> void:
	# Override base stats for boss
	max_health = 500
	current_health = max_health
	movement_speed = 120.0
	knockback_resistance = 0.8
	score_value = 1000
	print("🔴 BOSS: Stats set - HP:", current_health, "/", max_health, " Speed:", movement_speed)


func _setup_state_machine() -> void:
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)

	# Create states
	var idle_state = BossIdleState.new()
	idle_state.name = "Idle"
	state_machine.add_child(idle_state)

	var chase_state = BossChaseState.new()
	chase_state.name = "Chase"
	state_machine.add_child(chase_state)

	var attack_state = BossAttackState.new()
	attack_state.name = "Attack"
	state_machine.add_child(attack_state)

	var phase_transition_state = BossPhaseTransitionState.new()
	phase_transition_state.name = "PhaseTransition"
	state_machine.add_child(phase_transition_state)

	var death_state = BossDeathState.new()
	death_state.name = "Death"
	state_machine.add_child(death_state)

	# IMPORTANT: Manually initialize state machine since we're creating it dynamically
	# Register all states
	for child in state_machine.get_children():
		if child is State:
			state_machine.states[child.name] = child
			child.state_machine = state_machine
			child.finished.connect(state_machine._on_state_finished)

	# Start with idle state
	state_machine.current_state = idle_state
	state_machine.current_state.enter()

	print("🔴 BOSS: State machine set up with initial state: Idle")
	print("🔴 BOSS: Player reference exists:", player != null)


func _setup_attack_cooldown() -> void:
	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.name = "AttackCooldown"
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)


func _process_physics(_delta: float) -> void:
	# Physics is handled by state machine states
	pass


func _on_take_damage(damage: int, source_position: Vector2) -> void:
	var old_health = current_health
	var old_phase = current_phase

	print("🔴 BOSS: ⚔️ TOOK DAMAGE! Damage:", damage, " HP:", old_health, "→", current_health, "/", max_health)
	print("🔴 BOSS: Damage source position:", source_position)

	# Check for phase transition
	var previous_phase = current_phase
	_update_phase()

	if previous_phase != current_phase:
		print("🔴 BOSS: ⚡ PHASE TRANSITION! Phase", previous_phase + 1, "→", current_phase + 1)
		# Trigger phase transition
		state_machine.transition_to("PhaseTransition")
		# Emit boss phase change signal
		SignalBus.boss_phase_changed.emit(boss_name, current_phase + 1)

	# Emit boss damage signal
	SignalBus.boss_damaged.emit(boss_name, current_health, max_health)

	# Show health percentage
	var health_percent = (float(current_health) / float(max_health)) * 100.0
	print("🔴 BOSS: Health:", health_percent, "% (", current_health, "/", max_health, ")")


func _on_death() -> void:
	state_machine.transition_to("Death")
	SignalBus.boss_defeated.emit(boss_name)


func get_enemy_type() -> String:
	return boss_name


func _update_phase() -> void:
	var health_percentage = float(current_health) / float(max_health)

	if health_percentage > 0.66:
		current_phase = BossPhase.PHASE_1
	elif health_percentage > 0.33:
		current_phase = BossPhase.PHASE_2
	else:
		current_phase = BossPhase.PHASE_3


func get_distance_to_player() -> float:
	if player and is_instance_valid(player):
		return global_position.distance_to(player.global_position)
	return INF


func choose_attack() -> AttackType:
	var distance = get_distance_to_player()

	match current_phase:
		BossPhase.PHASE_1:
			# Simple pattern: melee if close, ranged if far
			if distance < melee_range * 1.5:
				return AttackType.MELEE_SLAM
			else:
				return AttackType.RANGED_PROJECTILE

		BossPhase.PHASE_2:
			# Mixed attacks
			if distance < melee_range * 1.5:
				return [AttackType.MELEE_SLAM, AttackType.AREA_SHOCKWAVE].pick_random()
			else:
				return AttackType.RANGED_PROJECTILE

		BossPhase.PHASE_3:
			# All attacks available, more aggressive
			if distance < melee_range:
				return [AttackType.MELEE_SLAM, AttackType.AREA_SHOCKWAVE].pick_random()
			elif distance > max_attack_distance:
				return AttackType.DASH_ATTACK
			else:
				return [AttackType.RANGED_PROJECTILE, AttackType.DASH_ATTACK].pick_random()

	return AttackType.MELEE_SLAM


func execute_attack(attack_type: AttackType) -> void:
	can_attack = false
	attack_cooldown_timer.start()

	match attack_type:
		AttackType.MELEE_SLAM:
			_execute_melee_attack()
		AttackType.RANGED_PROJECTILE:
			_execute_ranged_attack()
		AttackType.AREA_SHOCKWAVE:
			_execute_area_attack()
		AttackType.DASH_ATTACK:
			_execute_dash_attack()


func _execute_melee_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "melee_slam")

	# Telegraph phase
	await get_tree().create_timer(melee_telegraph_time).timeout

	# Attack active
	var hits = _check_melee_hit()
	if hits > 0:
		# Player was hit
		pass

	await get_tree().create_timer(melee_active_time).timeout

	SignalBus.boss_attack_finished.emit(boss_name, "melee_slam")
	state_machine.transition_to("Idle")


func _execute_ranged_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "ranged_projectile")

	var projectile_count = projectile_count_phase1
	match current_phase:
		BossPhase.PHASE_2:
			projectile_count = projectile_count_phase2
		BossPhase.PHASE_3:
			projectile_count = projectile_count_phase3

	await get_tree().create_timer(0.3).timeout

	_spawn_projectiles(projectile_count)

	SignalBus.boss_attack_finished.emit(boss_name, "ranged_projectile")
	state_machine.transition_to("Idle")


func _execute_area_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "area_shockwave")

	# Telegraph
	await get_tree().create_timer(shockwave_telegraph_time).timeout

	# Execute shockwave
	_check_shockwave_hit()

	await get_tree().create_timer(shockwave_active_time).timeout

	SignalBus.boss_attack_finished.emit(boss_name, "area_shockwave")
	state_machine.transition_to("Idle")


func _execute_dash_attack() -> void:
	SignalBus.boss_attack_started.emit(boss_name, "dash_attack")

	if player:
		var dash_direction = direction_to_player
		var dash_timer = 0.0

		while dash_timer < dash_duration:
			velocity = dash_direction * dash_speed
			dash_timer += get_physics_process_delta_time()
			await get_tree().process_frame

		velocity = Vector2.ZERO

	SignalBus.boss_attack_finished.emit(boss_name, "dash_attack")
	state_machine.transition_to("Idle")


func _check_melee_hit() -> int:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	# Create circle shape for melee range
	var shape = CircleShape2D.new()
	shape.radius = melee_range
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1  # Assuming player is on layer 1

	var results = space_state.intersect_shape(query, 10)
	var hit_count = 0

	for result in results:
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(melee_damage, global_position)
			hit_count += 1

	return hit_count


func _check_shockwave_hit() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	var shape = CircleShape2D.new()
	shape.radius = shockwave_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1

	var results = space_state.intersect_shape(query, 10)

	for result in results:
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(shockwave_damage, global_position)


func _spawn_projectiles(count: int) -> void:
	if not projectile_scene:
		print("🔴 BOSS: ERROR - No projectile scene assigned!")
		return

	if not player:
		print("🔴 BOSS: ERROR - No player reference!")
		return

	print("🔴 BOSS: Spawning ", count, " projectiles at player")

	var angle_step = 360.0 / count
	var start_angle = -90.0  # Start from top

	if count == 1:
		# Single projectile aimed at player
		_spawn_single_projectile(direction_to_player)
	else:
		# Spread pattern
		for i in range(count):
			var angle = deg_to_rad(start_angle + (angle_step * i))
			var direction = Vector2(cos(angle), sin(angle))
			_spawn_single_projectile(direction)


func _spawn_single_projectile(direction: Vector2) -> void:
	if not projectile_scene:
		return

	var projectile = projectile_scene.instantiate()

	# IMPORTANT: Initialize BEFORE adding to scene tree
	# This ensures direction is set before _ready() is called
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, projectile_damage)

	# Now add to scene tree
	get_parent().add_child(projectile)
	projectile.global_position = global_position

	print("🔴 BOSS: Projectile spawned - Dir:", direction, " Speed:", projectile_speed, " Dmg:", projectile_damage)


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


# ===========================
# BOSS STATE CLASSES
# ===========================

class BossIdleState extends State:
	var boss: BossEnemy
	var idle_timer: float = 0.0
	var idle_duration: float = 0.0
	var debug_timer: float = 0.0

	func enter(_data: Dictionary = {}) -> void:
		boss = state_machine.get_parent() as BossEnemy
		boss.velocity = Vector2.ZERO
		idle_duration = randf_range(boss.idle_time_min, boss.idle_time_max)
		idle_timer = 0.0
		debug_timer = 0.0
		print("🟡 BOSS STATE: Entered IDLE - Duration:", idle_duration, "s")
		print("🟡 BOSS STATE: Boss position:", boss.global_position)
		if boss.player:
			print("🟡 BOSS STATE: Player position:", boss.player.global_position)
			print("🟡 BOSS STATE: Distance to player:", boss.get_distance_to_player())

	func update(delta: float) -> void:
		idle_timer += delta
		debug_timer += delta

		# Debug print every 1 second
		if debug_timer >= 1.0:
			debug_timer = 0.0
			var distance = boss.get_distance_to_player()
			print("🟡 IDLE: Timer:", idle_timer, "/", idle_duration, " Distance:", distance, " Can attack:", boss.can_attack)

		if idle_timer >= idle_duration:
			var distance = boss.get_distance_to_player()
			# Decide next action
			if boss.can_attack and distance < boss.max_attack_distance:
				print("🟡 BOSS STATE: IDLE → ATTACK (Player in range:", distance, ")")
				finish("Attack")
			else:
				print("🟡 BOSS STATE: IDLE → CHASE (Player distance:", distance, ")")
				finish("Chase")


class BossChaseState extends State:
	var boss: BossEnemy
	var debug_timer: float = 0.0

	func enter(_data: Dictionary = {}) -> void:
		boss = state_machine.get_parent() as BossEnemy
		debug_timer = 0.0
		print("🟢 BOSS STATE: Entered CHASE - Targeting player")

	func update(delta: float) -> void:
		debug_timer += delta

		if not boss.player:
			print("🟢 BOSS STATE: CHASE → IDLE (No player)")
			finish("Idle")
			return

		var distance = boss.get_distance_to_player()

		# Debug every 0.5 seconds
		if debug_timer >= 0.5:
			debug_timer = 0.0
			print("🟢 CHASE: Distance:", distance, " Velocity:", boss.velocity, " Direction:", boss.direction_to_player)

		# Check if in attack range
		if boss.can_attack and distance < boss.max_attack_distance:
			print("🟢 BOSS STATE: CHASE → ATTACK (In range:", distance, ")")
			finish("Attack")
			return

		# Move toward player
		boss.velocity.x = boss.direction_to_player.x * boss.movement_speed

		# Stop chasing if too far
		if distance > boss.max_attack_distance * 2:
			print("🟢 BOSS STATE: CHASE → IDLE (Too far:", distance, ")")
			finish("Idle")


class BossAttackState extends State:
	var boss: BossEnemy

	func enter(_data: Dictionary = {}) -> void:
		boss = state_machine.get_parent() as BossEnemy
		boss.velocity = Vector2.ZERO

		# Choose and execute attack
		var attack_type = boss.choose_attack()
		var attack_names = ["MELEE_SLAM", "RANGED_PROJECTILE", "AREA_SHOCKWAVE", "DASH_ATTACK"]
		print("🔴 BOSS STATE: Entered ATTACK - Type:", attack_names[attack_type], " Phase:", boss.current_phase + 1)
		boss.execute_attack(attack_type)


class BossPhaseTransitionState extends State:
	var boss: BossEnemy

	func enter(_data: Dictionary = {}) -> void:
		boss = state_machine.get_parent() as BossEnemy
		boss.velocity = Vector2.ZERO
		boss.is_invulnerable = true

		# Wait for transition duration
		await boss.get_tree().create_timer(boss.phase_transition_invulnerability).timeout

		boss.is_invulnerable = false
		finish("Idle")


class BossDeathState extends State:
	var boss: BossEnemy

	func enter(_data: Dictionary = {}) -> void:
		boss = state_machine.get_parent() as BossEnemy
		boss.velocity = Vector2.ZERO
		# Death animation and cleanup handled by base class
