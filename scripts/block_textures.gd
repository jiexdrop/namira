class_name BlockTextures
extends Resource

const TEXTURE_SIZE = 16  # Size of each texture in pixels
const ATLAS_SIZE = 256   # Total atlas size in pixels
const TILES_PER_ROW = ATLAS_SIZE / TEXTURE_SIZE

# UV coordinates for each block type
var block_uvs = {}

func _init():
	# Initialize UV coordinates for different block types
	# Each entry contains UV coordinates for all 6 faces (right, left, top, bottom, front, back)
	# UV coordinates are normalized (0-1)
	
	# Grass Block
	block_uvs[BlockTypes.Type.GRASS] = {
		"right":  _get_texture_uv(0, 0),   # Side texture (grass_block_side)
		"left":   _get_texture_uv(0, 0),   # Side texture
		"top":    _get_texture_uv(1, 0),   # Top texture (grass_block_top)
		"bottom": _get_texture_uv(2, 0),   # Bottom texture (dirt)
		"front":  _get_texture_uv(0, 0),   # Side texture
		"back":   _get_texture_uv(0, 0)    # Side texture
	}
	
	# Dirt Block
	block_uvs[BlockTypes.Type.DIRT] = {
		"right":  _get_texture_uv(2, 0),   # Dirt texture
		"left":   _get_texture_uv(2, 0),
		"top":    _get_texture_uv(2, 0),
		"bottom": _get_texture_uv(2, 0),
		"front":  _get_texture_uv(2, 0),
		"back":   _get_texture_uv(2, 0)
	}
	
	# Stone Block
	block_uvs[BlockTypes.Type.STONE] = {
		"right":  _get_texture_uv(3, 0),   # Stone texture
		"left":   _get_texture_uv(3, 0),
		"top":    _get_texture_uv(3, 0),
		"bottom": _get_texture_uv(3, 0),
		"front":  _get_texture_uv(3, 0),
		"back":   _get_texture_uv(3, 0)
	}
	
	# Oak Planks
	block_uvs[BlockTypes.Type.OAK_PLANKS] = {
		"right":  _get_texture_uv(4, 0),   # Oak planks texture
		"left":   _get_texture_uv(4, 0),
		"top":    _get_texture_uv(4, 0),
		"bottom": _get_texture_uv(4, 0),
		"front":  _get_texture_uv(4, 0),
		"back":   _get_texture_uv(4, 0)
	}
	
	# Cobblestone
	block_uvs[BlockTypes.Type.COBBLESTONE] = {
		"right":  _get_texture_uv(5, 0),   # Cobblestone texture
		"left":   _get_texture_uv(5, 0),
		"top":    _get_texture_uv(5, 0),
		"bottom": _get_texture_uv(5, 0),
		"front":  _get_texture_uv(5, 0),
		"back":   _get_texture_uv(5, 0)
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
