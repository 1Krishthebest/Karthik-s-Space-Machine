
extends CharacterBody2D

const SPEED: float = 700.0
const FIXED_Y: float = 600.0

var half_w: float = 70.0
var animation_time: float = 0.0


func _ready() -> void:
	position.y = FIXED_Y

	if has_node("ColorRect"):
		(get_node("ColorRect") as ColorRect).visible = false

	set_width(140.0)


func set_width(w: float) -> void:
	half_w = w / 2.0

	var cs: CollisionShape2D = $CollisionShape2D
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 20.0)
	cs.shape = rect

	queue_redraw()


func _physics_process(delta: float) -> void:
	var dir: float = Input.get_axis("ui_left", "ui_right")

	position.x += dir * SPEED * delta
	position.x = clampf(position.x, half_w, 1152.0 - half_w)
	position.y = FIXED_Y

	animation_time += delta
	queue_redraw()


func _draw() -> void:
	var w: float = half_w * 2.0
	var pulse: float = 0.8 + sin(animation_time * 8.0) * 0.2

	# Engine glow
	draw_circle(Vector2(-w * 0.30, 13), 10.0, Color(0.0, 0.7, 1.0, 0.18))
	draw_circle(Vector2(w * 0.30, 13), 10.0, Color(0.0, 0.7, 1.0, 0.18))

	# Thruster flames
	var flame_length: float = 12.0 + sin(animation_time * 18.0) * 5.0

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-w * 0.30 - 5, 10),
			Vector2(-w * 0.30 + 5, 10),
			Vector2(-w * 0.30, 10 + flame_length)
		]),
		Color(0.1, 0.7, 1.0, pulse)
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(w * 0.30 - 5, 10),
			Vector2(w * 0.30 + 5, 10),
			Vector2(w * 0.30, 10 + flame_length)
		]),
		Color(0.1, 0.7, 1.0, pulse)
	)

	# Outer energy glow
	draw_rect(
		Rect2(-w / 2.0 - 7, -13, w + 14, 26),
		Color(0.0, 0.6, 1.0, 0.10 * pulse)
	)

	# Left wing
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-w * 0.5, 8),
			Vector2(-w * 0.30, -8),
			Vector2(-w * 0.12, -3),
			Vector2(-w * 0.22, 12)
		]),
		Color(0.05, 0.35, 0.65)
	)

	# Right wing
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(w * 0.5, 8),
			Vector2(w * 0.30, -8),
			Vector2(w * 0.12, -3),
			Vector2(w * 0.22, 12)
		]),
		Color(0.05, 0.35, 0.65)
	)

	# Main spacecraft hull
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-w * 0.38, 7),
			Vector2(-w * 0.28, -5),
			Vector2(-w * 0.12, -11),
			Vector2(0, -17),
			Vector2(w * 0.12, -11),
			Vector2(w * 0.28, -5),
			Vector2(w * 0.38, 7),
			Vector2(0, 11)
		]),
		Color(0.05, 0.65, 0.95)
	)

	# Hull highlight
	draw_line(
		Vector2(-w * 0.27, -4),
		Vector2(0, -15),
		Color(0.6, 0.95, 1.0),
		2.0
	)

	draw_line(
		Vector2(0, -15),
		Vector2(w * 0.27, -4),
		Color(0.6, 0.95, 1.0),
		2.0
	)

	# Cockpit
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9, -5),
			Vector2(-5, -12),
			Vector2(0, -15),
			Vector2(5, -12),
			Vector2(9, -5),
			Vector2(0, 1)
		]),
		Color(0.75, 1.0, 1.0)
	)

	# Cockpit shine
	draw_line(
		Vector2(-4, -9),
		Vector2(0, -13),
		Color.WHITE,
		2.0
	)

	# Wing lights
	draw_circle(Vector2(-w * 0.32, 0), 3.0, Color(0.2, 1.0, 1.0))
	draw_circle(Vector2(w * 0.32, 0), 3.0, Color(0.2, 1.0, 1.0))

	# Energy core
	draw_circle(Vector2(0, 3), 3.0, Color.WHITE)
