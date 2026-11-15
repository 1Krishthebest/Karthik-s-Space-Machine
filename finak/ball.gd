
extends CharacterBody2D

const START_SPEED: float = 450.0
const MAX_SPEED: float = 850.0
const COMBO_TIMEOUT: float = 2.0
const MAX_ABILITY_ENERGY: float = 100.0
const LASER_COOLDOWN: float = 0.35

var speed: float = START_SPEED
var launched: bool = false
var game_over: bool = false
var score: int = 0
var lives: int = 3

# Combo system
var combo: int = 0
var combo_timer: float = 0.0

# Ability system
var ability_energy: float = 0.0
var shield_armed: bool = false
var laser_cooldown: float = 0.0


func _ready() -> void:
	if has_node("ColorRect"):
		(get_node("ColorRect") as ColorRect).visible = false

	# Glowing comet trail
	var trail := CPUParticles2D.new()
	trail.amount = 40
	trail.lifetime = 0.45
	trail.local_coords = false
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 5.0
	trail.gravity = Vector2.ZERO
	trail.direction = Vector2(-1, 0)
	trail.spread = 180.0
	trail.initial_velocity_min = 15.0
	trail.initial_velocity_max = 70.0
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 5.0
	trail.color = Color(0.3, 0.8, 1.0, 0.9)
	trail.emitting = true
	add_child(trail)

	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 25.0, Color(0.2, 0.7, 1.0, 0.08))
	draw_circle(Vector2.ZERO, 19.0, Color(0.3, 0.8, 1.0, 0.15))
	draw_circle(Vector2.ZERO, 15.0, Color(0.5, 0.85, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 10.0, Color(0.85, 0.97, 1.0))
	draw_circle(Vector2(-3, -3), 3.0, Color.WHITE)

	if shield_armed:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 64, Color(0.1, 0.8, 1.0, 0.9), 4.0)
		draw_circle(Vector2.ZERO, 38.0, Color(0.1, 0.7, 1.0, 0.12))


func _explode(pos: Vector2, explosion_color: Color = Color(0.4, 1.0, 0.5)) -> void:
	var p := CPUParticles2D.new()
	get_parent().add_child(p)

	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 40
	p.lifetime = 0.65
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 8.0
	p.color = explosion_color
	p.emitting = true

	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


# Combo tracking
func _update_combo(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta

		if combo_timer <= 0.0:
			combo = 0


func _register_hit() -> int:
	combo += 1
	combo_timer = COMBO_TIMEOUT

	var multiplier: int = mini(combo, 5)

	if combo >= 2:
		print("COMBO x", multiplier, "!")

	return multiplier


# Energy charging
func _gain_energy(amount: float) -> void:
	if shield_armed:
		return

	ability_energy = minf(ability_energy + amount, MAX_ABILITY_ENERGY)

	print("ABILITY ENERGY: ", ability_energy, "%")

	if ability_energy >= MAX_ABILITY_ENERGY:
		print("ABILITY READY! PRESS E OR Q")


# Energy shield
func _activate_energy_shield() -> void:
	if shield_armed:
		return

	if ability_energy < MAX_ABILITY_ENERGY:
		print("NOT ENOUGH ENERGY!")
		return

	ability_energy = 0.0
	shield_armed = true
	queue_redraw()

	get_parent().call("show_message", "ENERGY SHIELD ACTIVATED!", 1.5)
	print("ENERGY SHIELD ACTIVATED!")


# Twin laser ability
func _fire_lasers() -> void:
	if laser_cooldown > 0.0:
		return

	if ability_energy < MAX_ABILITY_ENERGY:
		print("NOT ENOUGH ENERGY FOR LASERS!")
		return

	if game_over:
		return

	var main: Node2D = get_parent()
	var paddle: Node2D = main.get_node("Paddle")

	ability_energy = 0.0
	laser_cooldown = LASER_COOLDOWN

	# Fire two lasers
	for side in [-1.0, 1.0]:
		var laser := Area2D.new()
		laser.name = "PlayerLaser"
		laser.collision_layer = 0
		laser.collision_mask = 1
		laser.monitoring = true
		laser.monitorable = false

		main.add_child(laser)

		laser.global_position = paddle.global_position + Vector2(side * 35.0, -20.0)

		# Laser collision shape
		var shape_node := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(8.0, 24.0)
		shape_node.shape = rectangle
		laser.add_child(shape_node)

		# Glowing laser appearance
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([
			Vector2(-3.0, 12.0),
			Vector2(-3.0, -12.0),
			Vector2(3.0, -12.0),
			Vector2(3.0, 12.0)
		])
		beam.color = Color(0.2, 0.9, 1.0)
		laser.add_child(beam)

		# Bright laser core
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([
			Vector2(-1.0, 12.0),
			Vector2(-1.0, -12.0),
			Vector2(1.0, -12.0),
			Vector2(1.0, 12.0)
		])
		core.color = Color.WHITE
		laser.add_child(core)

		laser.body_entered.connect(_on_laser_hit.bind(laser))

		# Move laser upwards
		var tween := create_tween()
		tween.tween_property(laser, "global_position:y", -50.0, 0.8)
		tween.tween_callback(laser.queue_free)

	print("TWIN LASERS FIRED!")
	main.call("show_message", "TWIN LASERS!", 0.7)


# Laser collision
func _on_laser_hit(body: Node2D, laser: Area2D) -> void:
	if not is_instance_valid(laser):
		return

	if game_over:
		laser.queue_free()
		return

	if body.is_in_group("bricks"):
		laser.set_deferred("monitoring", false)
		laser.queue_free()
		_damage_drone(body)


# Damage drones using lasers
func _damage_drone(collider: Node2D) -> void:
	if not is_instance_valid(collider) or collider.is_queued_for_deletion():
		return

	var main: Node = get_parent()
	var hp: int = int(collider.get_meta("hp", 1)) - 1

	if hp > 0:
		collider.set_meta("hp", hp)

		var spr: Sprite2D = collider.get_child(1) as Sprite2D
		spr.modulate = Color(0.5, 1.0, 0.6)

		score += 5
		main.call("set_score", score)
		main.call("add_xp", 5)

		_gain_energy(5.0)
		_explode(collider.global_position, Color(0.2, 0.8, 1.0))

	else:
		var remaining: int = get_tree().get_nodes_in_group("bricks").size() - 1

		_explode(collider.global_position, Color(0.1, 0.9, 1.0))
		collider.queue_free()

		score += 10
		main.call("set_score", score)
		main.call("add_xp", 10)

		_gain_energy(10.0)

		if remaining <= 0:
			launched = false
			game_over = true
			main.call("level_cleared")


func _physics_process(delta: float) -> void:
	if game_over:
		return

	_update_combo(delta)

	laser_cooldown = maxf(0.0, laser_cooldown - delta)

	# Activate abilities
	if Input.is_key_pressed(KEY_E) and not shield_armed:
		_activate_energy_shield()

	if Input.is_key_pressed(KEY_Q):
		_fire_lasers()

	var main: Node = get_parent()
	var paddle: Node2D = main.get_node("Paddle")
	var hw: float = paddle.get("half_w")

	# Riding on the paddle
	if not launched:
		position = Vector2(paddle.position.x, paddle.position.y - 30.0)

		if Input.is_action_just_pressed("ui_accept"):
			launched = true
			var level: int = main.get("level")
			speed = START_SPEED + (level - 1) * 50.0
			velocity = Vector2(randf_range(-0.5, 0.5), -1.0).normalized() * speed
			main.call("clear_message")

		return

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision:
		var collider: Node = collision.get_collider() as Node

		if collider == paddle:
			if collision.get_normal().y < -0.5:
				var offset: float = clampf((position.x - paddle.position.x) / hw, -0.9, 0.9)
				velocity = Vector2(offset, -1.0).normalized() * speed
			else:
				velocity = velocity.bounce(collision.get_normal())

		else:
			velocity = velocity.bounce(collision.get_normal())

			if collider.is_in_group("bricks"):
				var hp: int = int(collider.get_meta("hp", 1)) - 1

				if hp > 0:
					collider.set_meta("hp", hp)

					var spr: Sprite2D = collider.get_child(1) as Sprite2D
					spr.modulate = Color(0.5, 1.0, 0.6)

					var multiplier: int = _register_hit()
					score += 5 * multiplier

					main.call("set_score", score)
					main.call("add_xp", 5)
					_gain_energy(5.0)

					_explode(collider.global_position, Color(0.4, 0.8, 1.0))

				else:
					var remaining: int = get_tree().get_nodes_in_group("bricks").size() - 1
					var multiplier: int = _register_hit()

					_explode(collider.global_position, Color(0.3, 1.0, 0.5))
					collider.queue_free()

					score += 10 * multiplier
					main.call("set_score", score)
					main.call("add_xp", 10)
					_gain_energy(10.0)

					speed = minf(speed + 6.0, MAX_SPEED)
					velocity = velocity.normalized() * speed

					if remaining <= 0:
						main.call("level_cleared")
						return

	# Walls and ceiling
	if position.x < 10.0:
		position.x = 10.0
		velocity.x = absf(velocity.x)

	elif position.x > 1142.0:
		position.x = 1142.0
		velocity.x = -absf(velocity.x)

	if position.y < 10.0:
		position.y = 10.0
		velocity.y = absf(velocity.y)

	# Comet dropped
	if position.y > 680.0:

		# Energy shield catches the comet
		if shield_armed:
			shield_armed = false
			launched = false
			velocity = Vector2.ZERO
			queue_redraw()

			_explode(position, Color(0.1, 0.8, 1.0))
			main.call("show_message", "SHIELD SAVED YOU!", 2.0)

			print("ENERGY SHIELD USED!")
			return

		# Normal life loss
		lives -= 1
		launched = false

		combo = 0
		combo_timer = 0.0

		main.call("set_lives", lives)
		main.call("flash")

		if lives <= 0:
			game_over = true
			main.call("end_game", "SHIELD DOWN.\nEARTH HAS FALLEN.")

		else:
			paddle.call("set_width", 190.0)

			main.call(
				"show_message",
				"ALIEN COMMANDER: You failed. Again.\nYOU: I'M NOT DONE YET.\n(Shield upgraded!)",
				3.5
			)
