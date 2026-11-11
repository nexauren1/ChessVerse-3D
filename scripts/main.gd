extends Node3D

const BOARD_SIZE := 8
const CELL_SIZE := 1.0
const BOARD_SURFACE_Y := 0.075

var camera: Camera3D
var pieces: Dictionary = {}
var selected_square := Vector2i(-1, -1)
var selected_piece: Node3D

var dark_piece_material: StandardMaterial3D

func _ready() -> void:
	_build_environment()
	_build_board_model()
	_build_piece_materials()
	_build_starting_position()
	_build_camera()
	_build_lighting()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.018, 0.026, 0.05)
	sky_material.sky_horizon_color = Color(0.18, 0.14, 0.09)
	sky_material.ground_bottom_color = Color(0.008, 0.01, 0.016)
	sky_material.ground_horizon_color = Color(0.09, 0.075, 0.06)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)

func _build_board_model() -> void:
	var board_scene := load("res://assets/models/board.glb") as PackedScene
	if board_scene != null:
		add_child(board_scene.instantiate())
	else:
		push_warning("board.glb is not imported yet. Run the Generate ChessVerse 3D models workflow.")

	# Invisible touch targets are kept separate from the visual GLB board.
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
	dark_piece_material = StandardMaterial3D.new()
	dark_piece_material.resource_name = "Black Chrome"
	dark_piece_material.albedo_color = Color(0.105, 0.135, 0.18)
	dark_piece_material.metallic = 0.98
	dark_piece_material.roughness = 0.16
	dark_piece_material.clearcoat_enabled = true
	dark_piece_material.clearcoat = 0.7

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
		push_warning("Missing 3D model: " + model_path)
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
	if not is_white:
		_apply_dark_metal(model)

	pieces[Vector2i(x, z)] = root

func _apply_dark_metal(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.mesh.surface_get_material(surface)
			if surface_material != null and surface_material.resource_name.contains("Polished Platinum"):
				mesh_instance.set_surface_override_material(surface, dark_piece_material)
	for child in node.get_children():
		_apply_dark_metal(child)

func _build_camera() -> void:
	camera = Camera3D.new()
	# Long lens distance keeps the full square board visible on a portrait phone screen.
	camera.position = Vector3(0.0, 16.4, 13.2)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 42.0
	camera.current = true
	add_child(camera)

func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -32, 0)
	key.light_energy = 1.8
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.5, 4.0, -2.0)
	fill.light_energy = 0.7
	fill.omni_range = 13.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(4.5, 3.2, 3.5)
	rim.light_color = Color(1.0, 0.72, 0.38)
	rim.light_energy = 1.1
	rim.omni_range = 10.0
	add_child(rim)

func _square_position(x: int, z: int) -> Vector3:
	return Vector3((x - 3.5) * CELL_SIZE, BOARD_SURFACE_Y, (z - 3.5) * CELL_SIZE)

func _input(event: InputEvent) -> void:
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
		if pieces.has(square):
			selected_square = square
			selected_piece = pieces[square]
			selected_piece.scale = Vector3.ONE * 1.08
		return

	if square == selected_square:
		selected_piece.scale = Vector3.ONE
		selected_piece = null
		return

	# Temporary visual prototype: move legality will be enforced by chess_rules.gd.
	if pieces.has(square) and pieces[square] != selected_piece:
		pieces[square].queue_free()
	pieces.erase(selected_square)
	pieces[square] = selected_piece
	selected_piece.position = _square_position(square.x, square.y)
	selected_piece.scale = Vector3.ONE
	selected_piece.set_meta("square", square)
	selected_piece = null
	selected_square = Vector2i(-1, -1)
