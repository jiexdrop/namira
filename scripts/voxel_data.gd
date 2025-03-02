class_name VoxelData
extends Resource

const CHUNK_SIZE = 16  # Chunk size in blocks
const MAX_LIGHT_LEVEL = 15

# Voxel type enumeration
enum VoxelType {
	AIR = 0,
	SOLID = 1,
	TRANSPARENT = 2
}

# Voxel data structure
class Voxel:
	var type: int = VoxelType.AIR
	var light_r: int = 0
	var light_g: int = 0
	var light_b: int = 0
	var ao: float = 0.0  # Ambient occlusion value
	
	func _init(p_type: int = VoxelType.AIR):
		type = p_type
