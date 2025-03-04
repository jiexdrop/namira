class_name BlockTextures
extends Resource

const TEXTURE_SIZE = 16  # Size of each texture in pixels
const ATLAS_SIZE = 256   # Total atlas size in pixels
const TILES_PER_ROW = ATLAS_SIZE / TEXTURE_SIZE

# UV coordinates for each block type
var block_uvs = {}

func _init():
	# Initialize UV coordinates for different block types
	
	# Air block (should never be rendered, but included for completeness)
	block_uvs[BlockTypes.Type.AIR] = _create_all_faces(0, 0)
	
	# Grass Block (special case with different top/bottom/sides)
	block_uvs[BlockTypes.Type.GRASS] = {
		"right":  _get_texture_uv(0, 0),   # Side texture (grass_block_side)
		"left":   _get_texture_uv(0, 0),   # Side texture
		"top":    _get_texture_uv(1, 0),   # Top texture (grass_block_top)
		"bottom": _get_texture_uv(2, 0),   # Bottom texture (dirt)
		"front":  _get_texture_uv(0, 0),   # Side texture
		"back":   _get_texture_uv(0, 0)    # Side texture
	}
	
	# Dirt Block (same texture all sides)
	block_uvs[BlockTypes.Type.DIRT] = _create_all_faces(2, 0)
	
	# Stone Block (same texture all sides)
	block_uvs[BlockTypes.Type.STONE] = _create_all_faces(3, 0)
	
	# Oak Planks (same texture all sides)
	block_uvs[BlockTypes.Type.OAK_PLANKS] = _create_all_faces(4, 0)
	
	# Cobblestone (same texture all sides)
	block_uvs[BlockTypes.Type.COBBLESTONE] = _create_all_faces(5, 0)

func _create_all_faces(x: int, y: int) -> Dictionary:
	var uvs = _get_texture_uv(x, y)
	return {
		"right": uvs,
		"left": uvs,
		"top": uvs,
		"bottom": uvs,
		"front": uvs,
		"back": uvs
	}

func _get_texture_uv(x: int, y: int) -> Array:
	# Convert tile coordinates to UV coordinates (normalized 0-1)
	var tile_size = float(TEXTURE_SIZE) / float(ATLAS_SIZE)
	var u = x * tile_size
	var v = y * tile_size
	
	# Return UV coordinates for all 4 corners of the texture
	return [
		Vector2(u, v + tile_size),             # Bottom-left
		Vector2(u, v),                         # Top-left
		Vector2(u + tile_size, v),             # Top-right
		Vector2(u + tile_size, v + tile_size)  # Bottom-right
	]
