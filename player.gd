extends CharacterBody3D

@export var time_per_segment: float = 0.1
@export var click_radius: float = 1.5        # How close click must be to node
@export var movement_nodes_group: String = "movement_nodes"

var path: Array[MovementNode] = []
var path_positions: Array[Vector3] = []

var is_moving: bool = false
var elapsed_time: float = 0.0

var current_segment_index: int = 0
var segment_elapsed_time: float = 0.0

# -------------------------
# INPUT
# -------------------------

func _input(event):

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

			var node = get_clicked_node()
			print(node.name)
			if node != null:
				move_to_node(node)


# -------------------------
# FIND CLICKED NODE
# -------------------------

func get_clicked_node() -> MovementNode:

	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos).normalized()

	var closest_node: MovementNode = null
	var closest_dist := click_radius

	for node in get_tree().get_nodes_in_group("movement_nodes"):

		var node_pos = node.global_position

		# Project node onto ray
		var to_node = node_pos - ray_origin
		var projection_length = to_node.dot(ray_dir)

		# Ignore nodes behind camera
		if projection_length < 0:
			continue

		var closest_point_on_ray = ray_origin + ray_dir * projection_length

		var dist = node_pos.distance_to(closest_point_on_ray)

		if dist < closest_dist:
			closest_dist = dist
			closest_node = node

	return closest_node


# -------------------------
# MOVE COMMAND
# -------------------------

func move_to_node(target: MovementNode):
	current_segment_index = 0
	segment_elapsed_time = 0.0
	is_moving = true
	var start_node = get_closest_node_to_player()

	if start_node == null or target == null:
		return

	path = find_path(start_node, target)

	if path.is_empty():
		return

	build_path_positions()

	elapsed_time = 0.0
	is_moving = true


# -------------------------
# FIND CLOSEST NODE TO PLAYER
# -------------------------

func get_closest_node_to_player() -> MovementNode:

	var closest_node = null
	var closest_dist = INF

	for node in get_tree().get_nodes_in_group(movement_nodes_group):

		var dist = global_position.distance_to(node.global_position)

		if dist < closest_dist:
			closest_dist = dist
			closest_node = node

	return closest_node


# -------------------------
# BUILD POSITION PATH + LENGTH
# -------------------------

func build_path_positions():
	path_positions.clear()

	for i in path.size():
		path_positions.append(path[i].global_position)


# -------------------------
# MOVEMENT UPDATE
# -------------------------

func _physics_process(delta):

	if not is_moving:
		return

	if current_segment_index >= path_positions.size() - 1:
		is_moving = false
		return

	segment_elapsed_time += delta

	var t = segment_elapsed_time / time_per_segment

	var start_pos = path_positions[current_segment_index]
	var end_pos = path_positions[current_segment_index + 1]

	if t >= 1.0:
		global_position = end_pos
		current_segment_index += 1
		segment_elapsed_time = 0.0
	else:
		global_position = start_pos.lerp(end_pos, t)


# -------------------------
# GET POSITION ALONG PATH BY DISTANCE
# -------------------------

func get_position_along_path(distance: float) -> Vector3:

	var walked = 0.0

	for i in range(path_positions.size() - 1):

		var a = path_positions[i]
		var b = path_positions[i + 1]

		var segment = a.distance_to(b)

		if walked + segment >= distance:

			var remain = distance - walked
			var ratio = remain / segment

			return a.lerp(b, ratio)

		walked += segment

	return path_positions[-1]


# -------------------------
# A* PATHFINDING
# -------------------------

func find_path(start: MovementNode, goal: MovementNode) -> Array[MovementNode]:

	var open: Array[MovementNode] = [start]
	var came_from = {}

	var g_score = {}
	g_score[start] = 0.0

	var f_score = {}
	f_score[start] = heuristic(start, goal)

	while open.size() > 0:

		var current: MovementNode = get_lowest_f(open, f_score)

		if current == goal:
			return reconstruct_path(came_from, current)

		open.erase(current)

		for neighbor: MovementNode in current.get_connections():

			var tentative = g_score[current] + current.global_position.distance_to(neighbor.global_position)

			if not g_score.has(neighbor) or tentative < g_score[neighbor]:

				came_from[neighbor] = current
				g_score[neighbor] = tentative
				f_score[neighbor] = tentative + heuristic(neighbor, goal)

				if neighbor not in open:
					open.append(neighbor)

	# Proper typed empty return
	var empty: Array[MovementNode] = []
	return empty


func heuristic(a: MovementNode, b: MovementNode) -> float:
	return a.global_position.distance_to(b.global_position)


func get_lowest_f(open, f_score):

	var best = open[0]

	for node in open:
		if f_score.get(node, INF) < f_score.get(best, INF):
			best = node

	return best


func reconstruct_path(came_from: Dictionary, current: MovementNode) -> Array[MovementNode]:

	var total: Array[MovementNode] = []
	total.append(current)

	while came_from.has(current):
		current = came_from[current] as MovementNode
		total.insert(0, current)

	return total
