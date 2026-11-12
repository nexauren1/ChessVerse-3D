extends Node3D

const BOARD_SIZE := 8
const CELL_SIZE := 1.0
const BOARD_SURFACE_Y := 0.075
const HUD_SCRIPT = preload("res://scripts/chess_hud.gd")

var camera: Camera3D
var pieces: Dictionary = {}
var selected_square := Vector2i(-1, -1)
var selected_piece: Node3D
var white_to_move := true
var white_piece_material: StandardMaterial3D
var silver_piece_material: StandardMaterial3D
var hud

func _ready() -> void:
	_build_environment()
	_build_architecture()
	_build_board_model()
	_build_piece_materials()
	_build_starting_position()
	_build_camera()
	_build_lighting()
	_build_hud()

func _build_hud() -> void:
	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.restart_requested.connect(_restart_game)
	hud.resign_requested.connect(_resign_game)
	hud.set_turn(true)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.008, 0.018, 0.048)
	sky_material.sky_horizon_color = Color(0.035, 0.10, 0.19)
	sky_material.ground_bottom_color = Color(0.006, 0.008, 0.015)
	sky_material.ground_horizon_color = Color(0.035, 0.055, 0.085)
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.82
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_strength = 0.72
	world.environment = env
	add_child(world)

	var probe := ReflectionProbe.new()
	probe.position = Vector3(0, 3.0, -2.0)
	probe.size = Vector3(19.0, 11.0, 29.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 1.15
	add_child(probe)

func _build_architecture() -> void:
	var floor_material := _material(Color(0.018, 0.025, 0.04), 0.78, 0.22)
	var gold_material := _material(Color(0.72, 0.43, 0.12), 0.94, 0.17)
	var column_material := _material(Color(0.035, 0.045, 0.065), 0.88, 0.2)
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(70.0, 70.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0, -0.34, -7.0)
	floor.material_override = floor_material
	add_child(floor)

	for x in [-10.0, 10.0]:
		_add_box(Vector3(0.045, 0.018, 34.0), Vector3(x, -0.315, -7.0), gold_material)
	for z in [-22.0, 8.0]:
		_add_box(Vector3(20.0, 0.018, 0.045), Vector3(0, -0.315, z), gold_material)

	for side in [-1.0, 1.0]:
		_build_column(Vector3(side * 7.7, -0.34, -4.0), column_material, gold_material)
		_build_column(Vector3(side * 7.7, -0.34, 3.7), column_material, gold_material)
		_add_box(Vector3(0.22, 7.7, 0.22), Vector3(side * 7.7, 3.51, -4.0), gold_material)
		_add_box(Vector3(0.22, 7.7, 0.22), Vector3(side * 7.7, 3.51, 3.7), gold_material)

	_add_box(Vector3(16.0, 0.48, 0.55), Vector3(0, 7.55, -4.0), gold_material)
	_add_box(Vector3(15.4, 0.32, 0.36), Vector3(0, 7.22, -4.0), column_material)
	_build_skyline()
	_build_moon()

func _build_column(pos: Vector3, dark_material: StandardMaterial3D, gold_material: StandardMaterial3D) -> void:
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.43
	shaft_mesh.bottom_radius = 0.56
	shaft_mesh.height = 7.8
	shaft_mesh.radial_segments = 28
	shaft.mesh = shaft_mesh
	shaft.position = pos + Vector3(0, 3.9, 0)
	shaft.material_override = dark_material
	add_child(shaft)

	for y in [0.28, 0.55, 7.1, 7.4]:
		var collar := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.47 if y < 1.0 else 0.39
		ring.outer_radius = 0.61 if y < 1.0 else 0.51
		ring.rings = 8
		ring.ring_segments = 32
		collar.mesh = ring
		collar.position = pos + Vector3(0, y, 0)
		collar.material_override = gold_material
		add_child(collar)

	for y in [0.12, 0.48, 7.28, 7.6]:
		var cap := MeshInstance3D.new()
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.68
		cap_mesh.bottom_radius = 0.68
		cap_mesh.height = 0.12
		cap_mesh.radial_segments = 28
		cap.mesh = cap_mesh
		cap.position = pos + Vector3(0, y, 0)
		cap.material_override = gold_material
		add_child(cap)

func _build_skyline() -> void:
	var building_material := _material(Color(0.025, 0.055, 0.105), 0.42, 0.36)
	var window_gold := _material(Color(0.95, 0.55, 0.18), 0.3, 0.24, Color(1.0, 0.42, 0.10), 1.6)
	var window_blue := _material(Color(0.12, 0.45, 0.85), 0.25, 0.22, Color(0.08, 0.32, 0.95), 1.2)
	var gold_transforms: Array[Transform3D] = []
	var blue_transforms: Array[Transform3D] = []
	var heights := [5.0, 8.0, 4.0, 10.0, 6.0, 12.0, 5.0, 9.0, 4.5, 8.0, 6.0, 11.0, 5.0]

	for i in range(heights.size()):
		var x := -20.0 + float(i) * 3.35
		var h: float = heights[i]
		var width := 2.25 if i % 3 == 0 else 2.65
		var depth := 1.5
		var z := -25.0 - float(i % 3) * 1.4
		_add_box(Vector3(width, h, depth), Vector3(x, h * 0.5 - 0.34, z), building_material)
		_add_box(Vector3(width + 0.12, 0.12, depth + 0.12), Vector3(x, h - 0.40, z), building_material)

		var rows := int(h / 1.25)
		for row in range(rows):
			for col in range(2):
				var wx := x + (float(col) - 0.5) * (width * 0.48)
				var wy := 0.55 + float(row) * 1.1
				if wy < h - 0.35:
					var transform := Transform3D(Basis.IDENTITY, Vector3(wx, wy, z + depth * 0.51))
					if (i + row + col) % 4 == 0:
						blue_transforms.append(transform)
					else:
						gold_transforms.append(transform)

	_add_window_multimesh(gold_transforms, window_gold)
	_add_window_multimesh(blue_transforms, window_blue)

func _add_window_multimesh(transforms: Array[Transform3D], material: Material) -> void:
	if transforms.is_empty():
		return
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(0.12, 0.24, 0.035)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = window_mesh
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)

func _build_moon() -> void:
	var moon_material := _material(Color(0.43, 0.68, 0.9), 0.08, 0.72, Color(0.18, 0.43, 0.85), 0.75)
	var moon := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 4.0
	sphere.height = 8.0
	sphere.radial_segments = 40
	sphere.rings = 24
	moon.mesh = sphere
	moon.position = Vector3(0, 10.5, -30.0)
	moon.material_override = moon_material
	add_child(moon)

	var moon_light := OmniLight3D.new()
	moon_light.position = moon.position
	moon_light.light_color = Color(0.24, 0.48, 0.95)
	moon_light.light_energy = 1.0
	moon_light.omni_range = 15.0
	add_child(moon_light)

func _build_board_model() -> void:
	var board_scene := load("res://assets/models/board.glb") as PackedScene
	if board_scene != null:
		add_child(board_scene.instantiate())
	else:
		push_warning("board.glb não foi importado. Executa o workflow de geração dos modelos.")

	for z in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var body := StaticBody3D.new()
			body.name = "Square_%d_%d" % [x, z]
			body.position = Vector3((x - 3.5) * CELL_SIZE, 0.025, (z - 3.5) * CELL_SIZE)
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(CELL_SIZE, 0.09, CELL_SIZE)
			collision.shape = shape
			body.add_child(collision)
			body.set_meta("square", Vector2i(x, z))
			add_child(body)

func _build_piece_materials() -> void:
	white_piece_material = _material(Color(0.78, 0.48, 0.16), 0.99, 0.13)
	white_piece_material.clearcoat_enabled = true
	white_piece_material.clearcoat = 0.8
	silver_piece_material = _material(Color(0.62, 0.72, 0.84), 0.99, 0.12)
	silver_piece_material.clearcoat_enabled = true
	silver_piece_material.clearcoat = 0.85

func _build_starting_position() -> void:
	var back_rank: Array[String] = ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	for x in range(BOARD_SIZE):
		_add_piece(x, 0, back_rank[x], false)
		_add_piece(x, 1, "pawn", false)
		_add_piece(x, 6, "pawn", true)
		_add_piece(x, 7, back_rank[x], true)

func _add_piece(x: int, z: int, kind: String, is_white: bool) -> void:
	var model_path := "res://assets/models/pieces/%s.glb" % kind
	var packed_piece := load(model_path) as PackedScene
	if packed_piece == null:
		push_warning("Modelo 3D em falta: " + model_path)
		return

	var root := Node3D.new()
	root.name = "%s_%d_%d" % [kind, x, z]
	root.position = _square_position(x, z)
	if is_white:
		root.rotation.y = PI
	root.set_meta("square", Vector2i(x, z))
	root.set_meta("kind", kind)
	root.set_meta("white", is_white)
	add_child(root)

	var model := packed_piece.instantiate() as Node3D
	if model == null:
		root.queue_free()
		return
	root.add_child(model)
	_apply_piece_finish(model, white_piece_material if is_white else silver_piece_material)
	pieces[Vector2i(x, z)] = root

func _apply_piece_finish(node: Node, finish: StandardMaterial3D) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.mesh.surface_get_material(surface)
			if surface_material != null and surface_material.resource_name == "Polished Platinum":
				mesh_instance.set_surface_override_material(surface, finish)
	for child in node.get_children():
		_apply_piece_finish(child, finish)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 12.6, 14.8)
	camera.look_at(Vector3(0.0, 0.0, -2.0), Vector3.UP)
	camera.fov = 49.0
	camera.current = true
	add_child(camera)

func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -26, 0)
	key.light_color = Color(1.0, 0.78, 0.52)
	key.light_energy = 2.25
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-4.5, 5.2, 2.5)
	fill.light_color = Color(0.34, 0.55, 1.0)
	fill.light_energy = 1.05
	fill.omni_range = 18.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(4.8, 4.5, -4.0)
	rim.light_color = Color(1.0, 0.58, 0.22)
	rim.light_energy = 1.5
	rim.omni_range = 15.0
	add_child(rim)

	var back_light := SpotLight3D.new()
	back_light.position = Vector3(0, 7.0, -11.0)
	back_light.rotation_degrees = Vector3(-20, 0, 0)
	back_light.light_color = Color(0.16, 0.42, 1.0)
	back_light.light_energy = 2.0
	back_light.spot_range = 22.0
	back_light.spot_angle = 55.0
	add_child(back_light)

func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	if emission_energy > 0.0:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = emission_energy
	return result

func _add_box(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	add_child(instance)
	return instance

func _square_position(x: int, z: int) -> Vector3:
	return Vector3((x - 3.5) * CELL_SIZE, BOARD_SURFACE_Y, (z - 3.5) * CELL_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)

func _handle_tap(screen_position: Vector2) -> void:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 100.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider: Object = hit.get("collider")
	if collider == null or not collider.has_meta("square"):
		return
	_select_or_move(collider.get_meta("square"))

func _select_or_move(square: Vector2i) -> void:
	if selected_piece == null:
		_try_select_piece(square)
		return

	if square == selected_square:
		selected_piece.scale = Vector3.ONE
		selected_piece = null
		selected_square = Vector2i(-1, -1)
		return

	if pieces.has(square):
		var tapped_piece: Node3D = pieces[square]
		if bool(tapped_piece.get_meta("white")) == white_to_move:
			selected_piece.scale = Vector3.ONE
			selected_piece = null
			selected_square = Vector2i(-1, -1)
			_try_select_piece(square)
			return

	if not _is_valid_basic_move(selected_square, square, selected_piece):
		hud.set_status("Jogada inválida")
		return

	if pieces.has(square):
		var captured: Node3D = pieces[square]
		captured.queue_free()
	pieces.erase(selected_square)
	pieces[square] = selected_piece
	selected_piece.set_meta("square", square)
	selected_piece.scale = Vector3.ONE
	var moving_piece := selected_piece
	selected_piece = null
	selected_square = Vector2i(-1, -1)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(moving_piece, "position", _square_position(square.x, square.y), 0.28)

	white_to_move = not white_to_move
	hud.set_turn(white_to_move)
	hud.set_status("Vez das pretas" if not white_to_move else "Vez das brancas")

func _try_select_piece(square: Vector2i) -> void:
	if not pieces.has(square):
		return
	var candidate: Node3D = pieces[square]
	if bool(candidate.get_meta("white")) != white_to_move:
		return
	selected_square = square
	selected_piece = candidate
	selected_piece.scale = Vector3.ONE * 1.08
	hud.set_status("Peça seleccionada")

func _is_valid_basic_move(from_square: Vector2i, to_square: Vector2i, piece: Node3D) -> bool:
	if from_square == to_square:
		return false

	var dx := to_square.x - from_square.x
	var dz := to_square.y - from_square.y
	var kind: String = piece.get_meta("kind")
	var is_white: bool = piece.get_meta("white")

	if pieces.has(to_square):
		var target: Node3D = pieces[to_square]
		if bool(target.get_meta("white")) == is_white:
			return false

	match kind:
		"pawn":
			var direction := -1 if is_white else 1
			if dx == 0 and not pieces.has(to_square):
				if dz == direction:
					return true
				var starting_rank := 6 if is_white else 1
				var middle_square := Vector2i(from_square.x, from_square.y + direction)
				if from_square.y == starting_rank and dz == direction * 2 and not pieces.has(middle_square):
					return true
			if abs(dx) == 1 and dz == direction and pieces.has(to_square):
				return true
			return false
		"knight":
			return (abs(dx) == 1 and abs(dz) == 2) or (abs(dx) == 2 and abs(dz) == 1)
		"bishop":
			return abs(dx) == abs(dz) and _is_path_clear(from_square, to_square)
		"rook":
			return (dx == 0 or dz == 0) and _is_path_clear(from_square, to_square)
		"queen":
			var straight := dx == 0 or dz == 0
			var diagonal := abs(dx) == abs(dz)
			return (straight or diagonal) and _is_path_clear(from_square, to_square)
		"king":
			return max(abs(dx), abs(dz)) == 1
	return false

func _is_path_clear(from_square: Vector2i, to_square: Vector2i) -> bool:
	var step_x := int(sign(to_square.x - from_square.x))
	var step_z := int(sign(to_square.y - from_square.y))
	var cursor := from_square + Vector2i(step_x, step_z)
	while cursor != to_square:
		if pieces.has(cursor):
			return false
		cursor += Vector2i(step_x, step_z)
	return true

func _restart_game() -> void:
	for piece in pieces.values():
		if is_instance_valid(piece):
			piece.queue_free()
	pieces.clear()
	selected_piece = null
	selected_square = Vector2i(-1, -1)
	white_to_move = true
	_build_starting_position()
	hud.set_turn(true)
	hud.set_status("Nova partida iniciada")

func _resign_game() -> void:
	selected_piece = null
	selected_square = Vector2i(-1, -1)
	hud.show_result("Partida terminada", "O jogador desistiu. Inicia uma nova partida para voltar a jogar.")
