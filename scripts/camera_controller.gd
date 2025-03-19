class_name CameraController
extends Camera3D

var mouse_sensitivity = 0.002
var movement_speed = 10.0
var current_velocity = Vector3.ZERO
var acceleration = 50.0
var friction = 5.0
var selected_block_type = BlockTypes.Type.STONE

var voxel_interaction: VoxelInteraction

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_voxel_interaction(interaction: VoxelInteraction):
	voxel_interaction = interaction

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var new_rotation = rotation.x - event.relative.y * mouse_sensitivity
		rotation.x = clamp(new_rotation, -PI/2, PI/2)
	
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_voxel_breaking()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_voxel_placing()
	
	elif event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Block selection hotkeys (1-6)
	elif event.is_action_pressed("select_block_1"):
		selected_block_type = BlockTypes.Type.STONE
	elif event.is_action_pressed("select_block_2"):
		selected_block_type = BlockTypes.Type.DIRT
	elif event.is_action_pressed("select_block_3"):
		selected_block_type = BlockTypes.Type.GRASS
	elif event.is_action_pressed("select_block_4"):
		selected_block_type = BlockTypes.Type.OAK_PLANKS
	elif event.is_action_pressed("select_block_5"):
		selected_block_type = BlockTypes.Type.COBBLESTONE

func _handle_voxel_breaking():
	if voxel_interaction:
		var target = voxel_interaction.get_target_voxel(self)
		if target.hit:
			# Add print statement for debugging
			print("Breaking voxel at: ", target.voxel_pos, " in chunk: ", target.chunk.chunk_position)
			voxel_interaction.break_voxel(target.chunk, target.voxel_pos)
			
func _handle_voxel_placing():
	if voxel_interaction:
		var target = voxel_interaction.get_target_voxel(self)
		if target.hit:
			# Check if the place position would intersect with the player
			var camera_pos = global_position
			
			# Convert Vector3i to Vector3 before adding
			var place_world_pos = Vector3(target.place_pos) + \
				Vector3(target.chunk.chunk_position) * float(VoxelData.CHUNK_SIZE)
			
			var distance = camera_pos.distance_to(place_world_pos)
			
			# Don't place if too close to the camera (prevents placing blocks inside player)
			if distance > 2.0:
				voxel_interaction.place_voxel(target.chunk, target.place_pos, selected_block_type)

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
