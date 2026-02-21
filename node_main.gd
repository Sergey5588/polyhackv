extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var a = $MovementNode5
	#var b = $MovementNode10
	pass

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var a = $MovementNode5
	var b = $MovementNode10
	if $"../Camera3D".rotation_degrees.y == 45:
		a.connect_bidirectional(b)
	else:
		a.disconnect_from(b)
		
	pass
