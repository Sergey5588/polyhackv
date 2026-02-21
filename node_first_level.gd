extends Node3D

var step = 0.1;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MovementNode9.connect_bidirectional($MovementNode10)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var curr_angle = fmod($"../Bridge".rotation_degrees.x, 360)
	print(curr_angle)
	if  270-step <= curr_angle and curr_angle <= 270+step:
		$MovementNode10.connect_bidirectional($"../Bridge/MovementNode11")
	else:
		$MovementNode10.disconnect_from($"../Bridge/MovementNode11")
	pass
