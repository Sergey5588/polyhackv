extends CharacterBody3D

@export var time_per_segment: float = 1
@export var click_radius: float = 0.5
@export var movement_nodes_group: String = "movement_nodes"

var path: Array[MovementNode] = []
var path_positions: Array[Vector3] = []

var is_moving: bool = false
var current_target: MovementNode = null

var current_segment_index: int = 0
var segment_elapsed_time: float = 0.0

var counter = 0

# ---------------------------------------------------
# INPUT
# ---------------------------------------------------




# ---------------------------------------------------
# FIND CLICKED NODE
# ---------------------------------------------------




# ---------------------------------------------------
# MOVE COMMAND
# ---------------------------------------------------

func move_to_node(target: MovementNode):

	if is_moving and target == current_target:
		return

	current_target = target

	var start_node: MovementNode = get_closest_node_to_player()
	if start_node == null or target == null:
		return

	var new_path = find_path(start_node, target)
	if new_path.is_empty():
		return

	path = new_path
	build_path_positions()

	current_segment_index = 0
	segment_elapsed_time = 0.0
	is_moving = true


# ---------------------------------------------------
# FIND CLOSEST NODE
# ---------------------------------------------------

func get_closest_node_to_player() -> MovementNode:

	var closest_node: MovementNode = null
	var closest_dist := INF

	for node in get_tree().get_nodes_in_group(movement_nodes_group):

		var dist = global_position.distance_to(node.global_position)

		if dist < closest_dist:
			closest_dist = dist
			closest_node = node

	return closest_node


# ---------------------------------------------------
# BUILD POSITION PATH
# ---------------------------------------------------

func build_path_positions():
	path_positions.clear()

	# First position is current player position
	path_positions.append(global_position)

	for i in range(1, path.size()):
		path_positions.append(path[i].global_position)


# ---------------------------------------------------
# MOVEMENT UPDATE
# ---------------------------------------------------

func _physics_process(delta):
	var plr_node = $"../Player".get_nearest_node_along_path()
	
	if plr_node != null:
		move_to_node(plr_node)
	
	if not is_moving:
		return

	# Validate upcoming segment
	if not is_next_segment_valid():
		handle_invalid_path()
		return

	# End of path
	if current_segment_index >= path_positions.size() - 1:
		stop_movement()
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


# ---------------------------------------------------
# VALIDATION
# ---------------------------------------------------

func is_next_segment_valid() -> bool:

	if current_segment_index >= path.size() - 1:
		return true

	var current_node: MovementNode = path[current_segment_index]
	var next_node: MovementNode = path[current_segment_index + 1]

	if next_node in current_node.get_connections():
		return true

	return false


func handle_invalid_path():

	print("Path invalidated — attempting reroute")

	var new_start: MovementNode = get_closest_node_to_player()

	if new_start == null or current_target == null:
		stop_at_last_valid_node()
		return

	var new_path = find_path(new_start, current_target)

	if new_path.is_empty():
		print("No alternative route found")
		stop_at_last_valid_node()
		return

	print("Rerouted successfully")

	path = new_path
	build_path_positions()

	current_segment_index = 0
	segment_elapsed_time = 0.0


func stop_at_last_valid_node():

	var safe_index = clamp(current_segment_index, 0, path_positions.size() - 1)
	global_position = path_positions[safe_index]

	stop_movement()


func stop_movement():
	is_moving = false
	current_target = null
	current_segment_index = 0
	segment_elapsed_time = 0.0


# ---------------------------------------------------
# GET POSITION ALONG PATH
# ---------------------------------------------------

func get_position_along_path(distance: float) -> Vector3:

	var walked := 0.0

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


# ---------------------------------------------------
# A* PATHFINDING
# ---------------------------------------------------

func find_path(start: MovementNode, goal: MovementNode) -> Array[MovementNode]:

	var open: Array[MovementNode] = [start]
	var came_from := {}

	var g_score := {}
	g_score[start] = 0.0

	var f_score := {}
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

	var empty: Array[MovementNode] = []
	return empty


func heuristic(a: MovementNode, b: MovementNode) -> float:
	return a.global_position.distance_to(b.global_position)


func get_lowest_f(open: Array, f_score: Dictionary) -> MovementNode:

	var best: MovementNode = open[0]

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
	
func get_nearest_node_along_path() -> MovementNode:

	if path.is_empty():
		return $"../MovementNodes/MovementNode"

	var closest_node: MovementNode = null
	var closest_dist := INF

	for node in path:
		var dist = global_position.distance_to(node.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_node = node
	return closest_node
