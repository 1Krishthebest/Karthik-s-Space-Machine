extends Node2D

const COLS: int = 5
const BRICK_W: float = 150.0
const BRICK_H: float = 70.0
const GAP: float = 60.0

var tex: Texture2D
var time: float = 0.0

func _ready() -> void:
	tex = load("res://drone.png")

func build(level: int) -> void:
	var rows: int = 2
	if level == 2:
		rows = 4
	elif level == 3:
		rows = 5
	var tints: Array[Color] = [
		Color(0.5, 1.0, 0.6),
		Color(0.5, 0.9, 1.0),
		Color(1.0, 0.6, 0.9)
	]
	var start_x: float = (1152.0 - (COLS * (BRICK_W + GAP) - GAP)) / 2.0 + BRICK_W / 2.0
	for r in rows:
		for c in COLS:
			if level == 2 and (r + c) % 2 == 1:
				continue
			var hp: int = 1
			var tint: Color = tints[r % 3]
			if level == 3 and r == 0:
				hp = 2
				tint = Color(1.0, 0.4, 0.4)

			var brick := StaticBody2D.new()
			brick.position = Vector2(start_x + c * (BRICK_W + GAP), 90.0 + r * (BRICK_H + GAP))
			brick.set_meta("hp", hp)

			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(BRICK_W, BRICK_H)
			shape.shape = rect
			brick.add_child(shape)

			var sprite := Sprite2D.new()
			sprite.texture = tex
			var tex_size: Vector2 = tex.get_size()
			var s: float = minf(BRICK_W / tex_size.x, BRICK_H / tex_size.y)
			sprite.scale = Vector2(s, s)
			sprite.modulate = tint
			brick.add_child(sprite)

			brick.add_to_group("bricks")
			add_child(brick)

func _process(delta: float) -> void:
	time += delta
	for node in get_tree().get_nodes_in_group("bricks"):
		var n: Node2D = node as Node2D
		var spr: Node2D = n.get_child(1) as Node2D
		spr.position.y = sin(time * 2.5 + n.position.x * 0.02) * 4.0
