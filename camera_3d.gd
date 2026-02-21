extends Camera3D


func _ready() -> void:
	var a = rad_to_deg(atan(1/sqrt(2)))
	rotation_degrees = Vector3(-a, 45, 0)
