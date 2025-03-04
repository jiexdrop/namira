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
	
	# Example for a grass block (different texture for top, sides, and bottom)
	block_uvs[VoxelData.VoxelType.SOLID] = {
		"right":  _get_texture_uv(0, 0),   # Side texture (index 0,0 in atlas)
		"left":   _get_texture_uv(0, 0),   # Side texture
		"top":    _get_texture_uv(1, 0),   # Top texture (index 1,0 in atlas)
		"bottom": _get_texture_uv(2, 0),   # Bottom texture (index 2,0 in atlas)
		"front":  _get_texture_uv(0, 0),   # Side texture
		"back":   _get_texture_uv(0, 0)    # Side texture
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
