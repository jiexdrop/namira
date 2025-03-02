extends Node3D

@onready var chunk_manager = ChunkManager.new()
@onready var mesh_generator = MeshGenerator.new()

func _ready():
	add_child(chunk_manager)
	add_child(mesh_generator)
	
	# Create a basic material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	material.roughness = 0.8
	material.vertex_color_use_as_albedo = true
	
	# Set up the camera with controller
	var camera = CameraController.new()
	camera.position = Vector3(16, 32, 16)
	camera.rotation_degrees = Vector3(-45, 45, 0)
	add_child(camera)
	
	# Add a light
	var light = DirectionalLight3D.new()
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)
	
	# Generate initial chunks with some terrain
	chunk_manager.generate_chunks(Vector3i.ZERO)
	
	# Generate meshes for all chunks
	for chunk in chunk_manager.chunks.values():
		mesh_generator.generate_chunk_mesh(chunk)
		chunk.mesh_instance.material_override = material
