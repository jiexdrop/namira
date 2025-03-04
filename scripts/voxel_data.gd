class_name VoxelData
extends Resource

const CHUNK_SIZE = 16
const MAX_LIGHT_LEVEL = 15

# Voxel data structure
class Voxel:
	var type: int = BlockTypes.Type.AIR
	var light_r: int = 0
	var light_g: int = 0
	var light_b: int = 0
	var ao: float = 0.0
	
	func _init(p_type: int = BlockTypes.Type.AIR):
		type = p_type
