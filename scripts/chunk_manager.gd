class_name ChunkManager
extends Node3D

const VoxelData = preload("res://scripts/voxel_data.gd")
const Chunk = preload("res://scripts/chunk.gd")

var chunks: Dictionary = {}
var render_distance: int = 8

func _ready():
	generate_chunks(Vector3i.ZERO)

func generate_chunks(center_position: Vector3i) -> void:
	var chunk_position = center_position / VoxelData.CHUNK_SIZE
	
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var pos = Vector3i(
				chunk_position.x + x,
				chunk_position.y,
				chunk_position.z + z
			)
			if not chunks.has(pos):
				create_chunk(pos)

func create_chunk(position: Vector3i) -> void:
	var chunk = Chunk.new(position)
	chunks[position] = chunk
	add_child(chunk)
	chunk.position = Vector3(
		position.x * VoxelData.CHUNK_SIZE,
		position.y * VoxelData.CHUNK_SIZE,
		position.z * VoxelData.CHUNK_SIZE
	)

func get_chunk(position: Vector3i) -> Chunk:
	return chunks.get(position)
