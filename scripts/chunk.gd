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
	
	# Enable transparency for the mesh instance
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _initialize_voxels():
	voxels.resize(VoxelData.CHUNK_SIZE * VoxelData.CHUNK_SIZE * VoxelData.CHUNK_SIZE)
	
	# Generate terrain
	for x in range(VoxelData.CHUNK_SIZE):
		for z in range(VoxelData.CHUNK_SIZE):
			var wx = x + chunk_position.x * VoxelData.CHUNK_SIZE
			var wz = z + chunk_position.z * VoxelData.CHUNK_SIZE
			
			# Simple height generation
			var height = 8 + sin(wx * 0.2) * 2 + cos(wz * 0.2) * 2
			
			for y in range(VoxelData.CHUNK_SIZE):
				var wy = y + chunk_position.y * VoxelData.CHUNK_SIZE
				var voxel = VoxelData.Voxel.new()
				
				if wy < height - 4:
					voxel.type = BlockTypes.Type.STONE
				elif wy < height - 1:
					voxel.type = BlockTypes.Type.DIRT
				elif wy < height:
					voxel.type = BlockTypes.Type.GRASS
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
