extends Node2D

var stars: Array[Dictionary] = []
var t: float = 0.0

func _ready() -> void:
	for i in 140:
		stars.append({
			"pos": Vector2(randf_range(0.0, 1152.0), randf_range(0.0, 600.0)),
			"size": randf_range(1.0, 3.0),
			"speed": randf_range(8.0, 40.0),
			"phase": randf_range(0.0, TAU)
		})

func _process(delta: float) -> void:
	t += delta
	for s in stars:
		var p: Vector2 = s["pos"]
		p.y += float(s["speed"]) * delta
		if p.y > 620.0:
			p.y = 0.0
			p.x = randf_range(0.0, 1152.0)
		s["pos"] = p
	queue_redraw()

func _draw() -> void:
	# Night sky
	var sky := PackedVector2Array([Vector2(0, 0), Vector2(1152, 0), Vector2(1152, 648), Vector2(0, 648)])
	var sky_cols := PackedColorArray([Color("#04051a"), Color("#04051a"), Color("#1b0c3d"), Color("#1b0c3d")])
	draw_polygon(sky, sky_cols)
	# Nebula glows
	draw_circle(Vector2(260, 170), 300.0, Color(0.35, 0.10, 0.60, 0.08))
	draw_circle(Vector2(260, 170), 180.0, Color(0.45, 0.15, 0.75, 0.08))
	draw_circle(Vector2(900, 380), 320.0, Color(0.05, 0.30, 0.60, 0.08))
	draw_circle(Vector2(900, 380), 190.0, Color(0.10, 0.45, 0.80, 0.08))
	# Twinkling stars
	for s in stars:
		var pos: Vector2 = s["pos"]
		var sz: float = float(s["size"])
		var tw: float = 0.5 + 0.5 * sin(t * 2.0 + float(s["phase"]))
		draw_rect(Rect2(pos, Vector2(sz, sz)), Color(1, 1, 1, 0.3 + 0.7 * tw))
	# Earth's glow along the bottom
	var glow := PackedVector2Array([Vector2(0, 580), Vector2(1152, 580), Vector2(1152, 648), Vector2(0, 648)])
	var glow_cols := PackedColorArray([Color(0.2, 0.6, 1.0, 0.0), Color(0.2, 0.6, 1.0, 0.0), Color(0.2, 0.6, 1.0, 0.55), Color(0.2, 0.6, 1.0, 0.55)])
	draw_polygon(glow, glow_cols)
	draw_rect(Rect2(0, 640, 1152, 8), Color(0.06, 0.26, 0.58))
