class_name VoxelInteraction
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")
const MAX_RAYCAST_DISTANCE = 5.0
const RAYCAST_STEPS = 50

var chunk_manager: ChunkManager
var mesh_generator: MeshGenerator

func _init(p_chunk_manager: ChunkManager, p_mesh_generator: MeshGenerator):
	chunk_manager = p_chunk_manager
	mesh_generator = p_mesh_generator

func get_target_voxel(camera: Camera3D) -> Dictionary:
	var result = {
		"chunk": null,
		"voxel_pos": Vector3i.ZERO,
		"hit": false,
		"normal": Vector3i.ZERO,  # Added to store the face normal
		"place_pos": Vector3i.ZERO  # Added to store the position where a new block can be placed
	}
	
	var from = camera.global_position
	var direction = -camera.global_transform.basis.z
	var step_size = MAX_RAYCAST_DISTANCE / RAYCAST_STEPS
	var last_pos = Vector3i.ZERO
	
	for i in range(RAYCAST_STEPS):
		var check_pos = from + direction * (step_size * i)
		var chunk_pos = Vector3i(
			floor(check_pos.x / VoxelData.CHUNK_SIZE),
			floor(check_pos.y / VoxelData.CHUNK_SIZE),
			floor(check_pos.z / VoxelData.CHUNK_SIZE)
		)
		
		var chunk = chunk_manager.get_chunk(chunk_pos)
		if chunk:
			var local_pos = Vector3i(
				posmod(int(check_pos.x), VoxelData.CHUNK_SIZE),
				posmod(int(check_pos.y), VoxelData.CHUNK_SIZE),
				posmod(int(check_pos.z), VoxelData.CHUNK_SIZE)
			)
			
			var voxel = chunk.get_voxel(local_pos)
			if voxel and voxel.type == BlockTypes.Type.STONE:
				result.chunk = chunk
				result.voxel_pos = local_pos
				result.hit = true
				
				# Calculate the normal from the last air position to the hit position
				if i > 0:
					result.normal = (last_pos - local_pos).sign()
					result.place_pos = local_pos + result.normal
				
				break
			
			last_pos = local_pos
	
	return result

func break_voxel(chunk: Chunk, voxel_pos: Vector3i) -> void:
	var voxel = VoxelData.Voxel.new()
	voxel.type = BlockTypes.Type.AIR
	chunk.set_voxel(voxel_pos, voxel)
	mesh_generator.generate_chunk_mesh(chunk)

func place_voxel(chunk: Chunk, voxel_pos: Vector3i) -> void:
	# Make sure the position is valid
	if not chunk._is_position_valid(voxel_pos):
		var new_chunk_pos = Vector3i(
			chunk.chunk_position.x + int(voxel_pos.x < 0 or voxel_pos.x >= VoxelData.CHUNK_SIZE),
			chunk.chunk_position.y + int(voxel_pos.y < 0 or voxel_pos.y >= VoxelData.CHUNK_SIZE),
			chunk.chunk_position.z + int(voxel_pos.z < 0 or voxel_pos.z >= VoxelData.CHUNK_SIZE)
		)
		
		var new_pos = Vector3i(
			posmod(voxel_pos.x, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.y, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.z, VoxelData.CHUNK_SIZE)
		)
		
		chunk = chunk_manager.get_chunk(new_chunk_pos)
		if chunk:
			voxel_pos = new_pos
	
	if chunk:
		var voxel = VoxelData.Voxel.new()
		voxel.type = BlockTypes.Type.OAK_PLANKS
		# Set default colors for the new block
		voxel.light_r = 10
		voxel.light_g = 8
		voxel.light_b = 5
		chunk.set_voxel(voxel_pos, voxel)
		mesh_generator.generate_chunk_mesh(chunk)
