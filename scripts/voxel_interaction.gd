class_name VoxelInteraction
extends Node

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
		"normal": Vector3i.ZERO,
		"place_pos": Vector3i.ZERO
	}
	
	var from = camera.global_position
	var direction = -camera.global_transform.basis.z
	var step_size = MAX_RAYCAST_DISTANCE / RAYCAST_STEPS
	var last_pos = Vector3i.ZERO
	var last_chunk = null
	
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
			if voxel and voxel.type != BlockTypes.Type.AIR:
				result.chunk = chunk
				result.voxel_pos = local_pos
				result.hit = true
				
				# Calculate the normal and placement position
				if i > 0:
					result.normal = (last_pos - local_pos).sign()
					if last_chunk:
						result.chunk = last_chunk
						result.place_pos = last_pos
					else:
						result.place_pos = local_pos + result.normal
				
				break
			
			last_pos = local_pos
			last_chunk = chunk
	
	return result

func break_voxel(chunk: Chunk, voxel_pos: Vector3i) -> void:
	# Check if the position is valid
	if not chunk._is_position_valid(voxel_pos):
		return
		
	var voxel = VoxelData.Voxel.new()
	voxel.type = BlockTypes.Type.AIR
	chunk.set_voxel(voxel_pos, voxel)
	
	# Update the chunk mesh
	mesh_generator.generate_chunk_mesh(chunk)
	
	# Update adjacent chunks if the broken block was on a border
	_update_adjacent_chunks(chunk, voxel_pos)

func place_voxel(chunk: Chunk, voxel_pos: Vector3i, block_type: int = BlockTypes.Type.STONE) -> void:
	var target_chunk = chunk
	var target_pos = voxel_pos
	
	# Handle block placement across chunk boundaries
	if not chunk._is_position_valid(voxel_pos):
		var new_chunk_pos = Vector3i(
			chunk.chunk_position.x + int(voxel_pos.x < 0) - int(voxel_pos.x >= VoxelData.CHUNK_SIZE),
			chunk.chunk_position.y + int(voxel_pos.y < 0) - int(voxel_pos.y >= VoxelData.CHUNK_SIZE),
			chunk.chunk_position.z + int(voxel_pos.z < 0) - int(voxel_pos.z >= VoxelData.CHUNK_SIZE)
		)
		
		target_pos = Vector3i(
			posmod(voxel_pos.x, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.y, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.z, VoxelData.CHUNK_SIZE)
		)
		
		target_chunk = chunk_manager.get_chunk(new_chunk_pos)
	
	if target_chunk and _can_place_block(target_chunk, target_pos):
		var voxel = VoxelData.Voxel.new()
		voxel.type = block_type
		
		# Set default lighting values
		voxel.light_r = 12
		voxel.light_g = 12
		voxel.light_b = 12
		
		target_chunk.set_voxel(target_pos, voxel)
		mesh_generator.generate_chunk_mesh(target_chunk)
		
		# Update adjacent chunks if the placed block was on a border
		_update_adjacent_chunks(target_chunk, target_pos)

func _can_place_block(chunk: Chunk, pos: Vector3i) -> bool:
	# Check if the target position is already occupied
	var existing_voxel = chunk.get_voxel(pos)
	if existing_voxel and existing_voxel.type != BlockTypes.Type.AIR:
		return false
	
	return true

func _update_adjacent_chunks(chunk: Chunk, pos: Vector3i) -> void:
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for dir in directions:
		if (pos + dir).x < 0 or (pos + dir).x >= VoxelData.CHUNK_SIZE or \
		   (pos + dir).y < 0 or (pos + dir).y >= VoxelData.CHUNK_SIZE or \
		   (pos + dir).z < 0 or (pos + dir).z >= VoxelData.CHUNK_SIZE:
			var adjacent_chunk_pos = chunk.chunk_position + dir
			var adjacent_chunk = chunk_manager.get_chunk(adjacent_chunk_pos)
			if adjacent_chunk:
				mesh_generator.generate_chunk_mesh(adjacent_chunk)
