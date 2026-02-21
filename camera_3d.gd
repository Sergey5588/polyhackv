extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector3(10,10,10)
	var a = rad_to_deg(atan(1/sqrt(2)))
	print(a)
	rotation_degrees = Vector3(-a, 45, 0)
