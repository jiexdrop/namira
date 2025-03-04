extends Node3D

@onready var chunk_manager = ChunkManager.new()
@onready var mesh_generator = MeshGenerator.new()
@onready var voxel_interaction = VoxelInteraction.new(chunk_manager, mesh_generator)
@onready var block_types = BlockTypes.new()

func _ready():
	add_child(chunk_manager)
	add_child(mesh_generator)
	
	# Create the base material
	var material = StandardMaterial3D.new()
	material.albedo_texture = load("res://images/grass_block_side.png")  # Default texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.8
	material.vertex_color_use_as_albedo = true
	
	# Set up the camera
	var camera = CameraController.new()
	camera.position = Vector3(16, 32, 16)
	camera.rotation_degrees = Vector3(-45, 45, 0)
	camera.set_voxel_interaction(voxel_interaction)
	add_child(camera)
	
	# Add lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.5
	add_child(light)
	
	# Generate initial chunks
	chunk_manager.generate_chunks(Vector3i.ZERO)
	
	# Generate meshes for all chunks
	for chunk in chunk_manager.chunks.values():
		mesh_generator.generate_chunk_mesh(chunk)
		chunk.mesh_instance.material_override = material

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
