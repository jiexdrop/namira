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
	block_textures[Type.GRASS] = {
		"top": preload("res://images/grass_block_top.png"),
		"side": preload("res://images/grass_block_side.png"),
		"bottom": preload("res://images/dirt.png")
	}
	
	block_textures[Type.DIRT] = {
		"all": preload("res://images/dirt.png")
	}
	
	block_textures[Type.STONE] = {
		"all": preload("res://images/stone.png")
	}
	
	block_textures[Type.OAK_PLANKS] = {
		"top": preload("res://images/oak_planks_top.png"),
		"side": preload("res://images/oak_planks.png")
	}
	
	block_textures[Type.COBBLESTONE] = {
		"all": preload("res://images/cobblestone.png")
	}

func get_block_texture(block_type: int, face: String) -> Texture2D:
	if not block_textures.has(block_type):
		return null
		
	var block = block_textures[block_type]
	
	# If the block has an "all" texture, use it for all faces
	if block.has("all"):
		return block["all"]
		
	# Otherwise, use specific face textures
	match face:
		"top":
			return block.get("top", block.get("side"))
		"bottom":
			return block.get("bottom", block.get("side"))
		_:  # sides
			return block.get("side")
