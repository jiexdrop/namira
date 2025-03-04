class_name MeshGenerator
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")
const BlockTypes = preload("res://scripts/block_types.gd")

var block_types = BlockTypes.new()

# Vertices for each face defined in counter-clockwise order when viewed from outside
var FACE_VERTICES = [
	# Right face (+X) - when looking at the face from +X
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	
	# Left face (-X) - when looking at the face from -X
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	
	# Top face (+Y) - when looking at the face from +Y
	[Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1)],
	
	# Bottom face (-Y) - when looking at the face from -Y
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	
	# Front face (+Z) - when looking at the face from +Z
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	
	# Back face (-Z) - when looking at the face from -Z
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)]
]

# UV coordinates matching the vertex order
var FACE_UVS = [
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
]


# Face mappings for texture orientation
const FACE_NAMES = ["right", "left", "top", "bottom", "front", "back"]

func generate_chunk_mesh(chunk: Chunk) -> void:
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var vertex_index = 0
	
	for x in range(VoxelData.CHUNK_SIZE):
		for y in range(VoxelData.CHUNK_SIZE):
			for z in range(VoxelData.CHUNK_SIZE):
				var pos = Vector3i(x, y, z)
				var voxel = chunk.get_voxel(pos)
				if voxel.type != BlockTypes.Type.AIR:
					vertex_index = _add_voxel_faces(vertices, uvs, normals, indices, pos, voxel, chunk, vertex_index)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	if vertices.size() > 0:
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
	
	var face_normals = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1)
	]
	
	for i in range(6):
		var neighbor_pos = pos + neighbors[i]
		var neighbor = chunk.get_voxel(neighbor_pos)
		
		if neighbor == null or neighbor.type == BlockTypes.Type.AIR:
			var face_name = FACE_NAMES[i]
			
			# Add vertices
			for v in range(4):
				vertices.append(FACE_VERTICES[i][v] + Vector3(pos))
				uvs.append(Vector2(float(v == 1 or v == 2), float(v >= 2)))
				normals.append(face_normals[i])
			
			# Add indices for triangles
			indices.append(vertex_index)
			indices.append(vertex_index + 1)
			indices.append(vertex_index + 2)
			indices.append(vertex_index)
			indices.append(vertex_index + 2)
			indices.append(vertex_index + 3)
			
			vertex_index += 4
	
	return vertex_index
