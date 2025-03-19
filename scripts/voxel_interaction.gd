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
	
	var ray_start = camera.global_position
	var ray_dir = -camera.global_transform.basis.z.normalized()
	
	# Initialize the voxel and chunk positions at ray start
	var voxel_pos = Vector3i(floor(ray_start.x), floor(ray_start.y), floor(ray_start.z))
	var chunk_pos = Vector3i(
		floor(ray_start.x / VoxelData.CHUNK_SIZE),
		floor(ray_start.y / VoxelData.CHUNK_SIZE),
		floor(ray_start.z / VoxelData.CHUNK_SIZE)
	)
	
	# Calculate step direction
	var step = Vector3i(
		1 if ray_dir.x >= 0 else -1,
		1 if ray_dir.y >= 0 else -1,
		1 if ray_dir.z >= 0 else -1
	)
	
	# Calculate distance to next voxel boundary
	var delta_dist = Vector3(
		INF if ray_dir.x == 0 else abs(1.0 / ray_dir.x),
		INF if ray_dir.y == 0 else abs(1.0 / ray_dir.y),
		INF if ray_dir.z == 0 else abs(1.0 / ray_dir.z)
	)
	
	# Calculate initial side_dist values
	var side_dist = Vector3(
		((floor(ray_start.x) + 1.0 - ray_start.x) if step.x > 0 else (ray_start.x - floor(ray_start.x))) * delta_dist.x,
		((floor(ray_start.y) + 1.0 - ray_start.y) if step.y > 0 else (ray_start.y - floor(ray_start.y))) * delta_dist.y,
		((floor(ray_start.z) + 1.0 - ray_start.z) if step.z > 0 else (ray_start.z - floor(ray_start.z))) * delta_dist.z
	)
	
	var last_voxel_pos = voxel_pos
	var last_chunk = null
	var normal = Vector3i.ZERO
	
	# Ray march through the voxel grid
	for i in range(int(MAX_RAYCAST_DISTANCE * 2)):
		# Get local voxel position within the chunk
		var local_pos = Vector3i(
			posmod(voxel_pos.x, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.y, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.z, VoxelData.CHUNK_SIZE)
		)
		
		var current_chunk = chunk_manager.get_chunk(chunk_pos)
		
		if current_chunk:
			var voxel = current_chunk.get_voxel(local_pos)
			if voxel and voxel.type != BlockTypes.Type.AIR:
				result.chunk = current_chunk
				result.voxel_pos = local_pos
				result.hit = true
				result.normal = normal
				
				# Calculate the placement position
				if last_chunk:
					result.chunk = last_chunk
					result.place_pos = last_voxel_pos
				else:
					result.place_pos = local_pos + normal
				
				return result
			
			last_voxel_pos = local_pos
			last_chunk = current_chunk
		
		# Determine which direction to step
		var mask = Vector3i.ZERO
		if side_dist.x < side_dist.y:
			if side_dist.x < side_dist.z:
				side_dist.x += delta_dist.x
				voxel_pos.x += step.x
				mask.x = -step.x
			else:
				side_dist.z += delta_dist.z
				voxel_pos.z += step.z
				mask.z = -step.z
		else:
			if side_dist.y < side_dist.z:
				side_dist.y += delta_dist.y
				voxel_pos.y += step.y
				mask.y = -step.y
			else:
				side_dist.z += delta_dist.z
				voxel_pos.z += step.z
				mask.z = -step.z
		
		normal = mask
		
		# Update chunk position if we've crossed a chunk boundary
		var new_chunk_pos = Vector3i(
			floor(voxel_pos.x / float(VoxelData.CHUNK_SIZE)),
			floor(voxel_pos.y / float(VoxelData.CHUNK_SIZE)),
			floor(voxel_pos.z / float(VoxelData.CHUNK_SIZE))
		)
		
		if new_chunk_pos != chunk_pos:
			chunk_pos = new_chunk_pos
	
	return result

func break_voxel(chunk: Chunk, voxel_pos: Vector3i) -> void:
	# Check if the position is valid
	if not chunk._is_position_valid(voxel_pos):
		print("Invalid voxel position: ", voxel_pos)
		return
		
	var voxel = VoxelData.Voxel.new()
	voxel.type = BlockTypes.Type.AIR
	chunk.set_voxel(voxel_pos, voxel)
	
	# Debug print to confirm the voxel was set to AIR
	print("Set voxel to AIR at position: ", voxel_pos)
	
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
