class_name World
extends Node3D

const VoxelData = preload("res://scripts/voxel_data.gd")

var mesh_generator = MeshGenerator.new()
var chunk_manager: ChunkManager
var current_chunk: Chunk

func _ready():
	chunk_manager = ChunkManager.new()
	add_child(chunk_manager)
	
	# Initialize the mesh generator
	add_child(mesh_generator)
	
	# Generate initial chunks
	generate_initial_chunks()
	
	# Set up camera controller if it exists
	var camera = get_node_or_null("Camera3D")
	if camera and camera is CameraController:
		var voxel_interaction = VoxelInteraction.new(chunk_manager, mesh_generator)
		add_child(voxel_interaction)
		camera.set_voxel_interaction(voxel_interaction)

func generate_initial_chunks():
	# Generate a 3x3x3 chunk area around the origin
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var chunk_pos = Vector3i(x, y, z)
				var chunk = Chunk.new(chunk_pos)
				chunk_manager.add_chunk(chunk)
				add_child(chunk)
				
				# Position the chunk in world space
				chunk.position = Vector3(
					chunk_pos.x * VoxelData.CHUNK_SIZE,
					chunk_pos.y * VoxelData.CHUNK_SIZE,
					chunk_pos.z * VoxelData.CHUNK_SIZE
				)
				
				# Generate the mesh for this chunk
				mesh_generator.generate_chunk_mesh(chunk)
