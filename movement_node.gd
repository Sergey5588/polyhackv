extends Node3D
class_name MovementNode

@export var auto_connect_radius: float = 1.01
@export var connections: Array[MovementNode] = []

@export var debug_enabled: bool = true
@export var debug_color: Color = Color.GREEN

var debug_mesh_instance: MeshInstance3D
var debug_mesh: ImmediateMesh


func _enter_tree():
	add_to_group("movement_nodes")


func _ready():
	auto_connect_nearby()
	setup_debug_mesh()


func _process(delta):
	if debug_enabled:
		draw_debug_lines()


# -------------------------
# AUTO CONNECT
# -------------------------

func auto_connect_nearby():

	var all_nodes = get_tree().get_nodes_in_group("movement_nodes")

	for node in all_nodes:

		if node == self:
			continue

		if is_connected_to(node):
			continue

		var distance = global_position.distance_to(node.global_position)

		if distance <= auto_connect_radius:
			connect_bidirectional(node)


# -------------------------
# CONNECTION FUNCTIONS
# -------------------------

func connect_to(node: MovementNode):

	if node == null:
		return

	if node == self:
		return

	if node in connections:
		return

	connections.append(node)


func connect_bidirectional(node: MovementNode):

	connect_to(node)
	node.connect_to(self)


func disconnect_from(node: MovementNode):

	connections.erase(node)
	node.connections.erase(self)


func is_connected_to(node: MovementNode) -> bool:
	return node in connections


func get_connections() -> Array[MovementNode]:
	return connections


# -------------------------
# DEBUG DRAWING SYSTEM
# -------------------------

func setup_debug_mesh():

	debug_mesh = ImmediateMesh.new()

	debug_mesh_instance = MeshInstance3D.new()
	debug_mesh_instance.mesh = debug_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = debug_color

	debug_mesh_instance.material_override = material

	add_child(debug_mesh_instance)


func draw_debug_lines():

	debug_mesh.clear_surfaces()

	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for node in connections:

		debug_mesh.surface_add_vertex(Vector3.ZERO)
		debug_mesh.surface_add_vertex(to_local(node.global_position))

	debug_mesh.surface_end()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if get_node_or_null("MeshInstance3D") != null:
			get_node("MeshInstance3D").queue_free()
			body.counter+=1
	pass # Replace with function body.
