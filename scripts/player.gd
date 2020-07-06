extends KinematicBody

export var GRAVITY = -9.81
export var speed = 5
export var sprint_speed = 50
export var MOUSE_SENSITIVITY = -.3
export var jump_speed = 10
export var jump_in_air = true
var vel = Vector3()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var input_movement = Vector2(
		int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")),
		int(Input.is_action_pressed("forward")) - int(Input.is_action_pressed("backward"))
	)
	input_movement = input_movement.normalized()
	var s = speed if not Input.is_action_pressed("sprint") else sprint_speed
	var movement = (Vector3(input_movement.x, 0, -input_movement.y) * s).rotated(Vector3(0, 1, 0), self.rotation.y)
	vel.x = movement.x
	vel.z = movement.z
	
	
	vel.y += delta * GRAVITY
	if is_on_floor() or jump_in_air:
		if Input.is_action_just_pressed("jump"):
			vel.y = jump_speed
	
	vel = self.move_and_slide(vel, Vector3(0, 1, 0), true, 1, deg2rad(60))
# 	if vel.y > 0 && vel.x != 0:
# 		print(vel.x * delta, " ", vel.z * delta)
	
	
	
func _input(event):
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$Head.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY))

		var camera_rot = $Head.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -80, 80)
		$Head.rotation_degrees = camera_rot
