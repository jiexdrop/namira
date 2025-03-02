class_name MeshGenerator
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")

# Vertices for each face (right, left, top, bottom, front, back)
var FACE_VERTICES = [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],  # Right
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],  # Left
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],  # Top
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],  # Bottom
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],  # Front
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)]   # Back
]

func generate_chunk_mesh(chunk: Chunk) -> void:
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	var vertex_index = 0
	
	for x in range(VoxelData.CHUNK_SIZE):
		for y in range(VoxelData.CHUNK_SIZE):
			for z in range(VoxelData.CHUNK_SIZE):
				var pos = Vector3i(x, y, z)
				var voxel = chunk.get_voxel(pos)
				if voxel.type == VoxelData.VoxelType.SOLID:
					vertex_index = _add_voxel_faces(vertices, uvs, normals, colors, indices, pos, voxel, chunk, vertex_index)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	if vertices.size() > 0:
		# Create the mesh with explicit settings
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		# Force the surface to use the correct face culling
		var mesh_instance = chunk.mesh_instance
		mesh_instance.mesh = mesh
		mesh_instance.set_surface_override_material(0, StandardMaterial3D.new())
		mesh_instance.get_surface_override_material(0).cull_mode = StandardMaterial3D.CULL_BACK

func _add_voxel_faces(vertices: PackedVector3Array, uvs: PackedVector2Array, normals: PackedVector3Array, 
					 colors: PackedColorArray, indices: PackedInt32Array, pos: Vector3i, 
					 voxel: VoxelData.Voxel, chunk: Chunk, vertex_index: int) -> int:
	var neighbors = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),  # Right, Left
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),  # Top, Bottom
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)   # Front, Back
	]
	
	var face_normals = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),    # Right, Left
		Vector3(0, 1, 0), Vector3(0, -1, 0),    # Top, Bottom
		Vector3(0, 0, 1), Vector3(0, 0, -1)     # Front, Back
	]
	
	for i in range(6):
		var neighbor_pos = pos + neighbors[i]
		var neighbor = chunk.get_voxel(neighbor_pos)
		
		if neighbor == null or neighbor.type == VoxelData.VoxelType.AIR:
			var base_color = Color(1.0, 1.0, 1.0)
			var ao_color = Color(1.0 - voxel.ao * 0.3, 1.0 - voxel.ao * 0.3, 1.0 - voxel.ao * 0.3)
			var light_color = Color(
				float(voxel.light_r) / VoxelData.MAX_LIGHT_LEVEL,
				float(voxel.light_g) / VoxelData.MAX_LIGHT_LEVEL,
				float(voxel.light_b) / VoxelData.MAX_LIGHT_LEVEL
			)
			var final_color = base_color * ao_color * light_color
			
			# Add vertices in counter-clockwise order for front face visibility
			for v in range(4):
				vertices.append(FACE_VERTICES[i][v] + Vector3(pos))
				uvs.append(Vector2(float(v == 1 || v == 2), float(v >= 2)))  # Simple UV mapping
				normals.append(face_normals[i])
				colors.append(final_color)
			
			# Add indices in counter-clockwise order
			indices.append(vertex_index)
			indices.append(vertex_index + 1)
			indices.append(vertex_index + 2)
			indices.append(vertex_index)
			indices.append(vertex_index + 2)
			indices.append(vertex_index + 3)
			
			vertex_index += 4
	
	return vertex_index
