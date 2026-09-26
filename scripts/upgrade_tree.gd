extends Control

# Widok drzewka ulepszeń. Ten node to "okno" (przycina zawartość — clip_contents),
# a w środku jest $TreeCanvas, na którym leżą przyciski-węzły.
# Przeciąganie myszką po pustym miejscu przesuwa TreeCanvas, czyli całe drzewko.

const UpgradeButtonScene = preload("res://scenes/upgrade_button.tscn")

const SPACING = Vector2(170, 130)       # odległość między kratkami siatki (px): poziomo, pionowo
const NODE_SIZE = Vector2(140, 110)     # rozmiar jednego węzła
const LINE_WIDTH = 4.0
const COLOR_LINE_ON = Color(1, 1, 1)          # wymaganie kupione
const COLOR_LINE_OFF = Color(1, 1, 1, 0.2)    # wymaganie jeszcze nie kupione
const COLOR_FINAL = Color(0.85, 0.15, 0.15)   # ramka węzłów z kilkoma wymaganiami

@onready var canvas: Control = $TreeCanvas


func _ready() -> void:
	for upgrade in GameState.UPGRADES:
		if upgrade.has("pos"):
			_spawn_node(upgrade)
	# Po zakupie zmienia się kolor linii — trzeba je przerysować.
	GameState.changed.connect(queue_redraw)
	# (0, 0) siatki ma być na środku widoku — także po zmianie rozmiaru okna.
	resized.connect(_center)
	_center()


func _spawn_node(upgrade: Dictionary) -> void:
	var button = UpgradeButtonScene.instantiate()
	button.compact = true
	button.custom_minimum_size = NODE_SIZE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.position = _grid_to_canvas(upgrade.pos) - NODE_SIZE / 2
	# Węzły wymagające kilku ulepszeń (czerwone na szkicu) dostają czerwoną ramkę.
	var is_final = upgrade.get("requires", []).size() >= 2
	_style_node(button, is_final)
	canvas.add_child(button)
	button.setup(upgrade)


# Domyślne tło przycisków jest półprzezroczyste — linie by przez nie prześwitywały.
# Kopiujemy style z motywu, ustawiamy pełne krycie i (opcjonalnie) czerwoną ramkę.
func _style_node(button: Button, red_border: bool) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box = button.get_theme_stylebox(state).duplicate()
		if box is StyleBoxFlat:
			box.bg_color = Color(box.bg_color.lightened(0.1), 1.0)
			if red_border:
				box.border_color = COLOR_FINAL
				box.set_border_width_all(3)
			button.add_theme_stylebox_override(state, box)


# Kratka siatki -> piksele na TreeCanvas (środek węzła).
func _grid_to_canvas(grid_pos: Vector2) -> Vector2:
	return grid_pos * SPACING


func _center() -> void:
	canvas.position = size / 2
	queue_redraw()


# _draw() tego node'a rysuje się POD dziećmi, więc linie są za przyciskami.
func _draw() -> void:
	for upgrade in GameState.UPGRADES:
		if not upgrade.has("pos"):
			continue
		var to = canvas.position + _grid_to_canvas(upgrade.pos)
		for req_id in upgrade.get("requires", []):
			var req = _find_upgrade(req_id)
			if not req.has("pos"):
				continue
			var from = canvas.position + _grid_to_canvas(req.pos)
			var color = COLOR_LINE_ON if GameState.get_level(req_id) > 0 else COLOR_LINE_OFF
			draw_line(from, to, color, LINE_WIDTH, true)


func _find_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade in GameState.UPGRADES:
		if upgrade.id == upgrade_id:
			return upgrade
	return {}


# Przesuwanie drzewka. Kliknięcia w przyciski tu nie docierają (przyciski je "zjadają"),
# więc przeciąga się tylko pustym tłem.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		canvas.position += event.relative
		queue_redraw()
