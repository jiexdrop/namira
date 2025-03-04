class_name Chunk
extends Node3D

const VoxelData = preload("res://scripts/voxel_data.gd")

var chunk_position: Vector3i
var voxels: Array = []
var mesh_instance: MeshInstance3D

func _init(position: Vector3i):
	chunk_position = position
	_initialize_voxels()
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

func _initialize_voxels():
	voxels.resize(VoxelData.CHUNK_SIZE * VoxelData.CHUNK_SIZE * VoxelData.CHUNK_SIZE)
	
	# Generate simple terrain
	for x in range(VoxelData.CHUNK_SIZE):
		for z in range(VoxelData.CHUNK_SIZE):
			var height = 8 + sin(float(x + chunk_position.x * VoxelData.CHUNK_SIZE) * 0.2) * 2 + cos(float(z + chunk_position.z * VoxelData.CHUNK_SIZE) * 0.2) * 2
			
			for y in range(VoxelData.CHUNK_SIZE):
				var world_y = y + chunk_position.y * VoxelData.CHUNK_SIZE
				var voxel = VoxelData.Voxel.new()
				
				if world_y < height:
					voxel.type = BlockTypes.Type.STONE
					# Add some color variation based on height
					voxel.light_r = 10 + (world_y / height) * 5
					voxel.light_g = 8 + (world_y / height) * 7
					voxel.light_b = 5 + (world_y / height) * 10
				else:
					voxel.type = BlockTypes.Type.AIR
				
				set_voxel(Vector3i(x, y, z), voxel)

func get_voxel(position: Vector3i) -> VoxelData.Voxel:
	var index = _get_voxel_index(position)
	if index == -1:
		return null
	return voxels[index]

func set_voxel(position: Vector3i, voxel: VoxelData.Voxel) -> void:
	var index = _get_voxel_index(position)
	if index != -1:
		voxels[index] = voxel

func _get_voxel_index(position: Vector3i) -> int:
	if not _is_position_valid(position):
		return -1
	return position.x + position.y * VoxelData.CHUNK_SIZE + position.z * VoxelData.CHUNK_SIZE * VoxelData.CHUNK_SIZE

func _is_position_valid(position: Vector3i) -> bool:
	return position.x >= 0 and position.x < VoxelData.CHUNK_SIZE \
		and position.y >= 0 and position.y < VoxelData.CHUNK_SIZE \
		and position.z >= 0 and position.z < VoxelData.CHUNK_SIZE


func has_block_type(block_type: int) -> bool:
	for voxel in voxels:
		if voxel is VoxelData.Voxel and voxel.type == block_type:
			return true
	return false
