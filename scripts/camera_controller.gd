class_name CameraController
extends Camera3D

var mouse_sensitivity = 0.002
var movement_speed = 10.0
var current_velocity = Vector3.ZERO
var acceleration = 50.0
var friction = 5.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var new_rotation = rotation.x - event.relative.y * mouse_sensitivity
		rotation.x = clamp(new_rotation, -PI/2, PI/2)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y += 1
	if Input.is_action_pressed("move_down"):
		input_dir.y -= 1
	
	input_dir = input_dir.normalized()
	
	var basis = global_transform.basis
	var direction = basis * Vector3(input_dir.x, 0, input_dir.z)
	direction.y = input_dir.y
	
	var target = direction * movement_speed
	
	current_velocity = current_velocity.move_toward(target, acceleration * delta)
	
	if input_dir == Vector3.ZERO:
		current_velocity = current_velocity.move_toward(Vector3.ZERO, friction * delta)
	
	position += current_velocity * delta
