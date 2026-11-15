
extends Node2D

const MAX_LEVEL: int = 3
const MAX_LIVES: int = 3

# Game progression
var level: int = 1
var state: String = "title"

# Player progression
var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 100

# UI tracking
var msg_id: int = 0
var score_label: Label
var level_label: Label
var lives_label: Label
var player_level_label: Label
var xp_label: Label
var banner: Label
var title_label: Label
var hint_label: Label
var button: Button
var flash_rect: ColorRect


func _make_label(pos: Vector2, sz: Vector2, font: int, center: bool) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))

	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	return l


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Flash effect
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(1152, 648)
	flash_rect.color = Color(1.0, 0.1, 0.1, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash_rect)

	# Main HUD
	score_label = _make_label(Vector2(20, 10), Vector2(350, 40), 23, false)
	layer.add_child(score_label)

	level_label = _make_label(Vector2(426, 10), Vector2(300, 40), 26, true)
	layer.add_child(level_label)

	lives_label = _make_label(Vector2(860, 10), Vector2(272, 40), 26, false)
	layer.add_child(lives_label)

	# Player XP HUD
	player_level_label = _make_label(Vector2(20, 48), Vector2(300, 30), 20, false)
	layer.add_child(player_level_label)

	xp_label = _make_label(Vector2(860, 48), Vector2(272, 30), 20, false)
	layer.add_child(xp_label)

	# Message banner
	banner = _make_label(Vector2(0, 250), Vector2(1152, 140), 40, true)
	banner.visible = false
	layer.add_child(banner)

	# Title
	title_label = _make_label(Vector2(0, 170), Vector2(1152, 90), 64, true)
	title_label.text = "REBOOT: ONE LAST LIFE"
	title_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	layer.add_child(title_label)

	hint_label = _make_label(Vector2(0, 290), Vector2(1152, 220), 30, true)
	hint_label.text = "Bounce the comet. Bounce back.\n\nARROW KEYS move     SPACE launch\n\nPRESS SPACE TO START"
	layer.add_child(hint_label)

	# Restart button
	button = Button.new()
	button.text = "REBOOT"
	button.position = Vector2(476, 420)
	button.size = Vector2(200, 60)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 28)
	button.visible = false
	button.pressed.connect(_restart)
	layer.add_child(button)

	# Initialize HUD
	set_score(0)
	set_lives(MAX_LIVES)
	_update_level()
	_update_player_xp_display()

	get_node("Ball").set("game_over", true)
	get_node("Bricks").call("build", level)


func _process(_delta: float) -> void:
	if state == "title" and Input.is_action_just_pressed("ui_accept"):
		_start_game()


func _start_game() -> void:
	state = "play"
	title_label.visible = false
	hint_label.visible = false

	show_message("STAGE 1\nPRESS SPACE TO LAUNCH", 0.0)

	await get_tree().create_timer(0.3).timeout
	get_node("Ball").set("game_over", false)


func _update_level() -> void:
	level_label.text = "STAGE " + str(level) + " / " + str(MAX_LEVEL)


func level_cleared() -> void:
	# Stage completion XP reward
	add_xp(50)

	var ball: Node = get_node("Ball")
	ball.set("game_over", true)
	ball.set("launched", false)

	# Final stage completed
	if level >= MAX_LEVEL:
		state = "over"
		show_message("EARTH IS SAVED.", 0.0)

		await get_tree().create_timer(2.2).timeout

		end_game("WAIT... WHO SENT THEM?\nFINAL SCORE: " + str(ball.get("score")))
		return

	# Stage cleared
	show_message("STAGE " + str(level) + " CLEARED!", 0.0)

	await get_tree().create_timer(1.8).timeout

	# Advance to next stage
	level += 1
	_update_level()

	# RESET SHIELDS TO 3
	ball.set("lives", MAX_LIVES)
	set_lives(MAX_LIVES)

	# Build next stage
	get_node("Bricks").call("build", level)

	ball.set("game_over", false)

	show_message(
		"STAGE " + str(level) + "\nSHIELDS RESTORED!\nPRESS SPACE TO LAUNCH",
		0.0
	)


func flash() -> void:
	flash_rect.color = Color(1.0, 0.1, 0.1, 0.35)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.5)


func set_score(n: int) -> void:
	score_label.text = "ALIENS DESTROYED: " + str(n)


func set_lives(n: int) -> void:
	lives_label.text = "SHIELD: " + str(maxi(n, 0))


# Update player XP display
func _update_player_xp_display() -> void:
	player_level_label.text = "PLAYER LEVEL: " + str(player_level)
	xp_label.text = "XP: " + str(player_xp) + " / " + str(xp_to_next_level)


# Add XP and handle player level-ups
func add_xp(amount: int) -> void:
	player_xp += amount

	while player_xp >= xp_to_next_level:
		player_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level += 50

		show_message("LEVEL UP!\nPLAYER LEVEL " + str(player_level), 2.5)
		print("PLAYER LEVEL: ", player_level)

	_update_player_xp_display()


func show_message(text: String, duration: float) -> void:
	msg_id += 1
	var my_id: int = msg_id

	banner.text = text
	banner.visible = true

	if duration > 0.0:
		await get_tree().create_timer(duration).timeout

		if my_id == msg_id:
			banner.visible = false


func clear_message() -> void:
	msg_id += 1
	banner.visible = false


func end_game(text: String) -> void:
	state = "over"
	msg_id += 1

	banner.text = text
	banner.visible = true
	button.visible = true


func _restart() -> void:
	get_tree().reload_current_scene()
