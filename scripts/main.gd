extends Node3D

const SIZE := 8
const CELL := 1.0

var camera: Camera3D
var pieces: Dictionary = {}
var selected_square := Vector2i(-1, -1)
var selected_piece: Node3D

func _ready() -> void:
	_build_environment()
	_build_board()
	_build_pieces()
	_build_camera()
	_build_lights()

func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.022, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.50, 0.58)
	env.ambient_light_energy = 0.6
	world.environment = env
	add_child(world)

func _build_board() -> void:
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(8.45, 0.3, 8.45)
	plinth.mesh = plinth_mesh
	plinth.position.y = -0.19
	plinth.material_override = _mat(Color(0.12, 0.075, 0.045), 0.55, 0.28)
	add_child(plinth)
	for z in range(SIZE):
		for x in range(SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(CELL, 0.08, CELL)
			tile.mesh = mesh
			tile.position = _pos(x, z) + Vector3(0, -0.025, 0)
			tile.material_override = _mat(Color(0.72, 0.62, 0.44) if (x + z) % 2 == 0 else Color(0.065, 0.078, 0.105), 0.25, 0.34)
			var body := StaticBody3D.new()
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(CELL, 0.1, CELL)
			collision.shape = shape
			body.add_child(collision)
			body.set_meta("square", Vector2i(x, z))
			tile.add_child(body)
			add_child(tile)

func _build_pieces() -> void:
	var rank := ["rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook"]
	for x in range(SIZE):
		_add_piece(x, 0, rank[x], false)
		_add_piece(x, 1, "pawn", false)
		_add_piece(x, 6, "pawn", true)
		_add_piece(x, 7, rank[x], true)

func _add_piece(x: int, z: int, kind: String, white: bool) -> void:
	var root := Node3D.new()
	root.name = "%s_%d_%d" % [kind, x, z]
	root.position = _pos(x, z)
	root.set_meta("square", Vector2i(x, z))
	root.set_meta("kind", kind)
	root.set_meta("white", white)
	add_child(root)
	var metal := _mat(Color(0.9, 0.77, 0.48) if white else Color(0.22, 0.29, 0.42), 0.86, 0.2)
	var base := _mat(Color(0.055, 0.06, 0.075), 0.35, 0.35)
	_cylinder(root, 0.28, 0.11, 0.055, base)
	_cylinder(root, 0.22, 0.12, 0.17, metal)
	match kind:
		"pawn":
			_cylinder(root, 0.12, 0.3, 0.38, metal)
			_sphere(root, 0.13, 0.6, metal)
		"rook":
			_cylinder(root, 0.17, 0.43, 0.43, metal)
			_cylinder(root, 0.22, 0.1, 0.7, metal)
		"knight":
			_cylinder(root, 0.15, 0.35, 0.42, metal)
			_box(root, Vector3(0.2, 0.34, 0.18), Vector3(0, 0.78, 0), metal)
			_sphere(root, 0.1, 0.98, metal)
		"bishop":
			_cylinder(root, 0.15, 0.48, 0.45, metal)
			_sphere(root, 0.13, 0.78, metal)
			_sphere(root, 0.055, 0.94, metal)
		"queen":
			_cylinder(root, 0.17, 0.58, 0.5, metal)
			_sphere(root, 0.18, 0.88, metal)
			for i in range(5):
				var angle := TAU * float(i) / 5.0
				_sphere_at(root, 0.05, Vector3(cos(angle) * 0.15, 1.05, sin(angle) * 0.15), metal)
		"king":
			_cylinder(root, 0.18, 0.65, 0.53, metal)
			_sphere(root, 0.16, 0.96, metal)
			_box(root, Vector3(0.07, 0.28, 0.07), Vector3(0, 1.23, 0), metal)
			_box(root, Vector3(0.22, 0.07, 0.07), Vector3(0, 1.28, 0), metal)
	pieces[Vector2i(x, z)] = root

func _cylinder(parent: Node3D, radius: float, height: float, y: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.88
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position.y = y
	node.material_override = material
	parent.add_child(node)

func _sphere(parent: Node3D, radius: float, y: float, material: Material) -> void:
	_sphere_at(parent, radius, Vector3(0, y, 0), material)

func _sphere_at(parent: Node3D, radius: float, position: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)

func _box(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 10.8, 10.8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 42
	camera.current = true
	add_child(camera)

func _build_lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -32, 0)
	key.light_energy = 1.6
	key.shadow_enabled = true
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.5, 4.0, -2.0)
	fill.light_energy = 0.65
	fill.omni_range = 12
	add_child(fill)

func _pos(x: int, z: int) -> Vector3:
	return Vector3((x - 3.5) * CELL, 0, (z - 3.5) * CELL)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(event.position)

func _tap(point: Vector2) -> void:
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.collider
	if not collider.has_meta("square"):
		return
	_choose_square(collider.get_meta("square"))

func _choose_square(square: Vector2i) -> void:
	if selected_piece == null:
		if pieces.has(square):
			selected_square = square
			selected_piece = pieces[square]
			selected_piece.scale = Vector3.ONE * 1.12
		return
	if square == selected_square:
		selected_piece.scale = Vector3.ONE
		selected_piece = null
		return
	# Prototype interaction only: legal move validation is a separate milestone.
	if pieces.has(square) and pieces[square] != selected_piece:
		pieces[square].queue_free()
	pieces.erase(selected_square)
	pieces[square] = selected_piece
	selected_piece.position = _pos(square.x, square.y)
	selected_piece.scale = Vector3.ONE
	selected_piece.set_meta("square", square)
	selected_piece = null
	selected_square = Vector2i(-1, -1)
