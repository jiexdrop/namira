class_name VoxelData
extends Resource

const CHUNK_SIZE = 16
const MAX_LIGHT_LEVEL = 15

class Voxel:
	var type: int = BlockTypes.Type.AIR
	var light_r: int = MAX_LIGHT_LEVEL
	var light_g: int = MAX_LIGHT_LEVEL
	var light_b: int = MAX_LIGHT_LEVEL
	var ao: float = 0.0
	
	func _init(p_type: int = BlockTypes.Type.AIR):
		type = p_type
