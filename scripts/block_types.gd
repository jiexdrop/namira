class_name BlockTypes
extends Resource

enum Type {
	AIR,
	GRASS,
	DIRT,
	STONE,
	OAK_PLANKS,
	COBBLESTONE
}

var block_textures = {}

func _init():
	# Load textures for each block type
	_load_block_textures()

func _load_block_textures():
	# Grass Block
	block_textures[Type.GRASS] = {
		"top": load("res://images/grass_block_top.png"),
		"side": load("res://images/grass_block_side.png"),
		"bottom": load("res://images/dirt.png")
	}
	
	# Dirt Block
	block_textures[Type.DIRT] = {
		"top": load("res://images/dirt.png"),
		"side": load("res://images/dirt.png"),
		"bottom": load("res://images/dirt.png")
	}
	
	# Stone Block
	block_textures[Type.STONE] = {
		"top": load("res://images/stone.png"),
		"side": load("res://images/stone.png"),
		"bottom": load("res://images/stone.png")
	}
	
	# Oak Planks
	block_textures[Type.OAK_PLANKS] = {
		"top": load("res://images/oak_planks_top.png"),
		"side": load("res://images/oak_planks.png"),
		"bottom": load("res://images/oak_planks_top.png")
	}
	
	# Cobblestone
	block_textures[Type.COBBLESTONE] = {
		"top": load("res://images/cobblestone.png"),
		"side": load("res://images/cobblestone.png"),
		"bottom": load("res://images/cobblestone.png")
	}

func get_texture_for_face(block_type: int, face: String) -> Texture2D:
	if not block_textures.has(block_type):
		return null
	
	var block = block_textures[block_type]
	return block.get(face, block.get("side"))
