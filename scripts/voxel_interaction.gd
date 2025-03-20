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
	
	# Maximum distance to check
	var max_distance = MAX_RAYCAST_DISTANCE
	
	# For more precise raycasting, use more iterations
	var step_size = max_distance / RAYCAST_STEPS
	var last_pos = Vector3i(-1, -1, -1)  # Invalid position to start
	var last_chunk = null
	
	# Step along the ray
	for i in range(RAYCAST_STEPS):
		var current_pos = ray_start + ray_dir * (i * step_size)
		var voxel_pos = Vector3i(floor(current_pos.x), floor(current_pos.y), floor(current_pos.z))
		
		# Skip if we're checking the same voxel
		if voxel_pos == last_pos:
			continue
			
		last_pos = voxel_pos
		
		# Calculate chunk position and local position
		var chunk_pos = Vector3i(
			floor(voxel_pos.x / float(VoxelData.CHUNK_SIZE)),
			floor(voxel_pos.y / float(VoxelData.CHUNK_SIZE)),
			floor(voxel_pos.z / float(VoxelData.CHUNK_SIZE))
		)
		
		var local_pos = Vector3i(
			posmod(voxel_pos.x, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.y, VoxelData.CHUNK_SIZE),
			posmod(voxel_pos.z, VoxelData.CHUNK_SIZE)
		)
		
		var current_chunk = chunk_manager.get_chunk(chunk_pos)
		
		if current_chunk:
			var voxel = current_chunk.get_voxel(local_pos)
			
			if voxel and voxel.type != BlockTypes.Type.AIR:
				# We hit a solid block
				result.chunk = current_chunk
				result.voxel_pos = local_pos
				result.hit = true
				
				# Calculate the normal (points from the block toward the camera)
				var hit_point = current_pos
				var block_center = Vector3(voxel_pos) + Vector3(0.5, 0.5, 0.5)
				var diff = hit_point - block_center
				
				# Find the axis with the largest component
				var max_axis = 0
				var max_value = abs(diff.x)
				
				if abs(diff.y) > max_value:
					max_axis = 1
					max_value = abs(diff.y)
				
				if abs(diff.z) > max_value:
					max_axis = 2
				
				# Set the normal based on the axis with the largest component
				result.normal = Vector3i.ZERO
				result.normal[max_axis] = -1 if diff[max_axis] > 0 else 1
				
				# Calculate the placement position
				result.place_pos = local_pos - result.normal
				
				# For debugging
				print("Hit block at local pos:", local_pos, " in chunk:", current_chunk.chunk_position)
				print("Normal:", result.normal, " Place pos:", result.place_pos)
				
				return result
			
			last_chunk = current_chunk
	
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
	
	# Debug info at start
	print("Attempting to place block at position:", voxel_pos, " in chunk:", chunk.chunk_position)
	
	# Check if the target position is inside the current chunk
	if not chunk._is_position_valid(voxel_pos):
		print("Position outside chunk boundaries, recalculating...")
		
		# Calculate the actual chunk position for this global position
		var world_pos = Vector3(voxel_pos) + Vector3(chunk.chunk_position) * VoxelData.CHUNK_SIZE
		var new_chunk_pos = Vector3i(
			floor(world_pos.x / VoxelData.CHUNK_SIZE),
			floor(world_pos.y / VoxelData.CHUNK_SIZE),
			floor(world_pos.z / VoxelData.CHUNK_SIZE)
		)
		
		# Calculate local position in the new chunk
		target_pos = Vector3i(
			int(posmod(world_pos.x, VoxelData.CHUNK_SIZE)),
			int(posmod(world_pos.y, VoxelData.CHUNK_SIZE)),
			int(posmod(world_pos.z, VoxelData.CHUNK_SIZE))
		)
		
		target_chunk = chunk_manager.get_chunk(new_chunk_pos)
		
		print("Redirecting to chunk:", new_chunk_pos, " at local position:", target_pos)
		
		# Create the chunk if it doesn't exist (optional)
		if not target_chunk:
			print("Target chunk doesn't exist, creating it...")
			target_chunk = Chunk.new(new_chunk_pos)
			chunk_manager.add_chunk(target_chunk)
			chunk_manager.get_parent().add_child(target_chunk)
			target_chunk.position = Vector3(new_chunk_pos) * VoxelData.CHUNK_SIZE

	
	# Check if we have a valid target
	if not target_chunk:
		print("Failed to place block: No valid target chunk")
		return
	
	# Verify position is valid in the target chunk
	if not target_chunk._is_position_valid(target_pos):
		print("Error: Target position", target_pos, "is invalid in chunk", target_chunk.chunk_position)
		return
	
	# Check if we can place a block here
	if not _can_place_block(target_chunk, target_pos):
		print("Cannot place block: Position already occupied")
		return
	
	# All checks passed, create and place the voxel
	var voxel = VoxelData.Voxel.new()
	voxel.type = block_type
	
	# Set default lighting values
	voxel.light_r = 12
	voxel.light_g = 12
	voxel.light_b = 12
	
	# Place the block
	target_chunk.set_voxel(target_pos, voxel)
	print("Successfully placed block of type:", BlockTypes.Type.keys()[block_type], 
		  " at position:", target_pos, " in chunk:", target_chunk.chunk_position)
	
	# Update the mesh of the target chunk
	mesh_generator.generate_chunk_mesh(target_chunk)
	
	# Update adjacent chunks if the placed block was on a border
	_update_adjacent_chunks(target_chunk, target_pos)
	
func _can_place_block(chunk: Chunk, pos: Vector3i) -> bool:
	# First make sure the position is valid
	if not chunk._is_position_valid(pos):
		print("Position", pos, "is outside chunk boundaries")
		return false
	
	# Check if the target position is already occupied
	var existing_voxel = chunk.get_voxel(pos)
	if not existing_voxel:
		print("No voxel data at position", pos)
		return false
		
	if existing_voxel.type != BlockTypes.Type.AIR:
		print("Position", pos, "is already occupied with block type:", BlockTypes.Type.keys()[existing_voxel.type])
		return false
	
	return true


func _update_adjacent_chunks(chunk: Chunk, pos: Vector3i) -> void:
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for dir in directions:
		var check_pos = pos + dir
		
		# If the position is outside this chunk's bounds
		if check_pos.x < 0 or check_pos.x >= VoxelData.CHUNK_SIZE or \
		   check_pos.y < 0 or check_pos.y >= VoxelData.CHUNK_SIZE or \
		   check_pos.z < 0 or check_pos.z >= VoxelData.CHUNK_SIZE:
			
			# Calculate which adjacent chunk to update
			var offset = Vector3i(
				1 if check_pos.x >= VoxelData.CHUNK_SIZE else (-1 if check_pos.x < 0 else 0),
				1 if check_pos.y >= VoxelData.CHUNK_SIZE else (-1 if check_pos.y < 0 else 0),
				1 if check_pos.z >= VoxelData.CHUNK_SIZE else (-1 if check_pos.z < 0 else 0)
			)
			
			var adjacent_chunk_pos = chunk.chunk_position + offset
			var adjacent_chunk = chunk_manager.get_chunk(adjacent_chunk_pos)
			
			if adjacent_chunk:
				print("Updating adjacent chunk at:", adjacent_chunk_pos)
				mesh_generator.generate_chunk_mesh(adjacent_chunk)
