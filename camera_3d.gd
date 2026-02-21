extends Camera3D

var initial_radius: float
var initial_height: float
var angle: float

func _input(event):
	if event.is_action_pressed("r") or (event is InputEventKey and event.keycode == KEY_R and event.pressed):
		angle -= deg_to_rad(90)
		update_camera_position()

func update_camera_position():
	var x = initial_radius * sin(angle)
	var z = initial_radius * cos(angle)
	position = Vector3(x, initial_height, z)
	# Always face the origin
	look_at(Vector3.ZERO, Vector3.UP)
func _ready() -> void:
	update_camera_position()
	position = Vector3(10,10,10)
	var a = rad_to_deg(atan(1/sqrt(2)))
	rotation_degrees = Vector3(-a, 45, 0)
	var pos = position
	initial_radius = Vector2(pos.x, pos.z).length()
	initial_height = pos.y

	angle = atan2(pos.x, pos.z)

	update_camera_position()
