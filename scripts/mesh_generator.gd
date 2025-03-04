class_name MeshGenerator
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")
var block_types = BlockTypes.new()
var block_textures = BlockTextures.new()

# Vertices for each face defined in counter-clockwise order when viewed from outside
var FACE_VERTICES = [
	# Right face (+X)
	PackedVector3Array([
		Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)
	]),
	# Left face (-X)
	PackedVector3Array([
		Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)
	]),
	# Top face (+Y)
	PackedVector3Array([
		Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1)
	]),
	# Bottom face (-Y)
	PackedVector3Array([
		Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0)
	]),
	# Front face (+Z)
	PackedVector3Array([
		Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)
	]),
	# Back face (-Z)
	PackedVector3Array([
		Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)
	])
]

const FACE_NORMALS = [
	Vector3(1, 0, 0),  # Right
	Vector3(-1, 0, 0), # Left
	Vector3(0, 1, 0),  # Top
	Vector3(0, -1, 0), # Bottom
	Vector3(0, 0, 1),  # Front
	Vector3(0, 0, -1)  # Back
]

const FACE_NAMES = ["right", "left", "top", "bottom", "front", "back"]

func generate_chunk_mesh(chunk: Chunk) -> void:
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var vertex_index = 0
	
	# Add vertex attributes
	for x in range(VoxelData.CHUNK_SIZE):
		for y in range(VoxelData.CHUNK_SIZE):
			for z in range(VoxelData.CHUNK_SIZE):
				var pos = Vector3i(x, y, z)
				var voxel = chunk.get_voxel(pos)
				if voxel and voxel.type != BlockTypes.Type.AIR:
					vertex_index = _add_voxel_faces(vertices, uvs, normals, indices, pos, voxel, chunk, vertex_index)
	
	if vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		chunk.mesh_instance.mesh = mesh

func _add_voxel_faces(vertices: PackedVector3Array, uvs: PackedVector2Array, normals: PackedVector3Array,
					 indices: PackedInt32Array, pos: Vector3i, voxel: VoxelData.Voxel, chunk: Chunk,
					 vertex_index: int) -> int:
	var neighbors = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),  # Right, Left
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),  # Top, Bottom
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)   # Front, Back
	]
	
	for i in range(6):
		var neighbor_pos = pos + neighbors[i]
		var neighbor = chunk.get_voxel(neighbor_pos)
		
		if neighbor == null or neighbor.type == BlockTypes.Type.AIR:
			# Get the correct UV coordinates for this face
			var face_name = FACE_NAMES[i]
			var face_type = "side"
			
			# Determine the correct texture type based on the face
			if face_name == "top":
				face_type = "top"
			elif face_name == "bottom":
				face_type = "bottom"
			
			# Get UV coordinates for this block type and face
			var face_uvs = block_textures.block_uvs[voxel.type][face_name]
			
			# Add vertices for this face
			for v in range(4):
				vertices.append(FACE_VERTICES[i][v] + Vector3(pos))
				normals.append(FACE_NORMALS[i])
				uvs.append(face_uvs[v])  # Use the correct UV coordinates for this face
			
			# Add indices for triangles (two triangles per face)
			indices.append(vertex_index)
			indices.append(vertex_index + 1)
			indices.append(vertex_index + 2)
			indices.append(vertex_index)
			indices.append(vertex_index + 2)
			indices.append(vertex_index + 3)
			
			vertex_index += 4
	
	return vertex_index
