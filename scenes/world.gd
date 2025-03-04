extends Node3D

@onready var chunk_manager = ChunkManager.new()
@onready var mesh_generator = MeshGenerator.new()
@onready var voxel_interaction = VoxelInteraction.new(chunk_manager, mesh_generator)
@onready var block_types = BlockTypes.new()

func _ready():
	add_child(chunk_manager)
	add_child(mesh_generator)
	
	# Create materials for each block type
	var materials = {}
	for block_type in BlockTypes.Type.values():
		if block_type != BlockTypes.Type.AIR:
			var material = StandardMaterial3D.new()
			
			# Get the appropriate texture for this block type
			var texture = block_types.get_block_texture(block_type, "all")
			if texture:
				material.albedo_texture = texture
			else:
				# If no "all" texture, try side texture
				material.albedo_texture = block_types.get_block_texture(block_type, "side")
			
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			material.roughness = 0.8
			materials[block_type] = material
	
	# Set up the camera with controller
	var camera = CameraController.new()
	camera.position = Vector3(16, 32, 16)
	camera.rotation_degrees = Vector3(-45, 45, 0)
	camera.set_voxel_interaction(voxel_interaction)
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
		
		# Assign the appropriate material based on block type
		for block_type in materials:
			if chunk.has_block_type(block_type):
				chunk.mesh_instance.material_override = materials[block_type]
				break
