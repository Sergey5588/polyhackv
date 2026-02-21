extends Node3D

var current_time := 0.0;
var max_time := 0.23;
var last_angle := 0.0;
var target_angle := 0.0;
var is_rotating := false;
# Called when the node enters the scene tree for the first time.

func snap_angle_to_axis(angle: float) -> float:
	var step := PI / 2.0
	return round(angle / step) * step

func _ready() -> void:
		
	pass # Replace with function body.

func get_children_names() -> Array[String]:
	var names: Array[String] = []

	for child in get_children():
		names.append(child.name)

	return names
func can_rotate():
	return not is_rotating and Input.is_action_just_pressed("rotate_1") and ($"../Player".get_nearest_node_along_path().name not in get_children_names())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_rotate():
		is_rotating = true
		target_angle+=PI*0.5
	
	if is_rotating:
		current_time+=delta
		rotation.x = lerp_angle(last_angle, target_angle,current_time/max_time)
	if current_time >= max_time:
		current_time = 0
		rotation.x = target_angle
		last_angle = target_angle
		is_rotating = false
