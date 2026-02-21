extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var a = $MovementNode5
	#var b = $MovementNode10
	var a = $MovementNode5
	var b = $MovementNode10
	a.connect_bidirectional(b)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
