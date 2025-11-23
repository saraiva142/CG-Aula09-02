extends Node2D

# --- Posições dos polígonos na tela ---
const TRI_POS := Vector2(150, 120)
const HEX_POS := Vector2(420, 120)
const STAR_POS := Vector2(690, 120)
const R := 70  # raio base para as formas

# --- Cores usadas em todos os modos ---
var c_line: Color = Color(0.6, 0.1, 0.9)
var c_fill: Color = Color(0.1, 0.8, 0.2)
var c_v0: Color = Color(1, 0, 0)
var c_v1: Color = Color(0, 1, 0)
var c_v2: Color = Color(0, 0, 1)
var c_v3: Color = Color(1, 0, 1)

# Texturas para modo tileado
@export var stripes_tex: Texture2D
@export var dots_tex: Texture2D
@export var tiles_x := 4
@export var tiles_y := 4
var pattern_tint: Color = Color(1, 1, 1, 1)
var current_pattern: Texture2D

func _ready() -> void:
	randomize()
	# Começar com a textura de listras como padrão
	if stripes_tex:
		current_pattern = stripes_tex
	queue_redraw()

func _input(event):
	# Alterar padrão com teclas 1 e 2
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if stripes_tex:
					current_pattern = stripes_tex
					print("Mudou para padrão: Listras")
					queue_redraw()
			KEY_2:
				if dots_tex:
					current_pattern = dots_tex
					print("Mudou para padrão: Pontos")
					queue_redraw()
	
	# Gerar nova paleta de cores com clique do mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_randomize_palette()
		queue_redraw()

func _randomize_palette():
	c_line = Color(randf(), randf(), randf())
	c_fill = Color(randf(), randf(), randf())

	c_v0 = Color(randf(), 0.0, 0.0)
	c_v1 = Color(0.0, randf(), 0.0)
	c_v2 = Color(0.0, 0.0, randf())
	c_v3 = Color(randf(), randf(), randf())

	pattern_tint = c_fill
	print("Nova paleta de cores gerada!")

func _draw():
	# Desenhar os três polígonos
	_draw_triangle()
	_draw_hexagon()
	_draw_star()

func _draw_triangle():
	var tri := _polygon_regular(TRI_POS, 3, R)
	_draw_full_polygon(tri, "Triângulo")

func _draw_hexagon():
	var hex := _polygon_regular(HEX_POS, 6, R)
	_draw_full_polygon(hex, "Hexágono")

func _draw_star():
	var star := _polygon_star(STAR_POS, 5, R, R * 0.45)
	_draw_full_polygon(star, "Estrela")

# ===================================================================
# =============== FUNÇÕES DE DESENHO DE CADA MODO ====================
# ===================================================================

func _draw_full_polygon(poly: PackedVector2Array, name: String = ""):
	# 1) CONTORNO
	draw_polyline(poly + PackedVector2Array([poly[0]]), c_line, 3.0)
	
	# 2) SÓLIDO
	draw_polygon(poly, PackedColorArray([c_fill]))
	
	# 3) INTERPOLAÇÃO POR VÉRTICE (gradiente)
	var colors := PackedColorArray([])
	for i in range(poly.size()):
		match i % 4:
			0: colors.append(c_v0)
			1: colors.append(c_v1)
			2: colors.append(c_v2)
			3: colors.append(c_v3)
	draw_polygon(poly, colors)
	
	# 4) TEXTURA TILEADA
	if current_pattern:
		_draw_pattern_on_polygon(poly)

# ===================================================================
# =============== DESENHO DO TILE EM UM POLÍGONO ====================
# ===================================================================

func _draw_pattern_on_polygon(poly: PackedVector2Array):
	if not current_pattern:
		return

	# Encontrar os limites do polígono
	var min_x = poly[0].x
	var max_x = poly[0].x
	var min_y = poly[0].y
	var max_y = poly[0].y

	for p in poly:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	# Criar retângulo que envolve o polígono
	var rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	var cell_w = rect.size.x / tiles_x
	var cell_h = rect.size.y / tiles_y

	# Desenhar cada tile
	for j in range(tiles_y):
		for i in range(tiles_x):
			var pos = rect.position + Vector2(i * cell_w, j * cell_h)
			var tile_rect = Rect2(pos, Vector2(cell_w, cell_h))
			draw_texture_rect(current_pattern, tile_rect, false, pattern_tint)

# ===================================================================
# ================= FUNÇÕES PARA GERAR POLÍGONOS =====================
# ===================================================================

func _polygon_regular(center: Vector2, sides: int, radius: float) -> PackedVector2Array:
	var arr := PackedVector2Array()
	for i in range(sides):
		var ang = i * TAU / sides - PI / 2
		arr.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return arr

func _polygon_star(center: Vector2, tips: int, r1: float, r2: float) -> PackedVector2Array:
	var arr := PackedVector2Array()
	for i in range(tips * 2):
		var radius = r1 if i % 2 == 0 else r2
		var ang = i * TAU / (tips * 2) - PI / 2
		arr.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return arr
