class_name MeshGenerator
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")
var block_types = BlockTypes.new()

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

# Standard UV coordinates for a face
var FACE_UVS = PackedVector2Array([
	Vector2(0, 1), # Bottom-left
	Vector2(0, 0), # Top-left
	Vector2(1, 0), # Top-right
	Vector2(1, 1)  # Bottom-right
])

const FACE_NAMES = ["right", "left", "top", "bottom", "front", "back"]

func generate_chunk_mesh(chunk: Chunk) -> void:
	var faces_by_texture = {}
	
	# Group faces by texture
	for x in range(VoxelData.CHUNK_SIZE):
		for y in range(VoxelData.CHUNK_SIZE):
			for z in range(VoxelData.CHUNK_SIZE):
				var pos = Vector3i(x, y, z)
				var voxel = chunk.get_voxel(pos)
				if voxel and voxel.type != BlockTypes.Type.AIR:
					_group_voxel_faces(faces_by_texture, pos, voxel, chunk)
	
	# Create mesh with multiple surfaces
	var mesh = ArrayMesh.new()
	var materials = []
	
	# First create all surfaces
	for texture_key in faces_by_texture:
		var face_data = faces_by_texture[texture_key]
		if face_data.vertices.size() > 0:
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = face_data.vertices
			arrays[Mesh.ARRAY_NORMAL] = face_data.normals
			arrays[Mesh.ARRAY_TEX_UV] = face_data.uvs
			arrays[Mesh.ARRAY_INDEX] = face_data.indices
			
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			
			# Create material for this surface
			var material = StandardMaterial3D.new()
			material.albedo_texture = block_types.get_texture_for_face(face_data.block_type, face_data.face_type)
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			material.roughness = 0.8
			
			if face_data.block_type == BlockTypes.Type.GRASS and face_data.face_type == "top":
				material.albedo_color = Color(0.4, 1.0, 0.3, 1.0)  # Green tint
			else:
				material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # White (no tint)
				
			material.vertex_color_use_as_albedo = true
			materials.append(material)
	
	# Set the mesh first
	chunk.mesh_instance.mesh = mesh
	
	# Then set all materials
	for i in range(materials.size()):
		chunk.mesh_instance.set_surface_override_material(i, materials[i])

func _group_voxel_faces(faces_by_texture: Dictionary, pos: Vector3i, voxel: VoxelData.Voxel, chunk: Chunk) -> void:
	var neighbors = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),  # Right, Left
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),  # Top, Bottom
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)   # Front, Back
	]
	
	for i in range(6):
		var neighbor_pos = pos + neighbors[i]
		var neighbor = chunk.get_voxel(neighbor_pos)
		
		if neighbor == null or neighbor.type == BlockTypes.Type.AIR:
			var face_name = FACE_NAMES[i]
			var texture_face = "side"
			
			if face_name == "top":
				texture_face = "top"
			elif face_name == "bottom":
				texture_face = "bottom"
			
			# Create a unique key for this combination of block type and face
			var texture_key = str(voxel.type) + "_" + texture_face
			
			if not faces_by_texture.has(texture_key):
				faces_by_texture[texture_key] = {
					"vertices": PackedVector3Array(),
					"uvs": PackedVector2Array(),
					"normals": PackedVector3Array(),
					"indices": PackedInt32Array(),
					"vertex_count": 0,
					"block_type": voxel.type,
					"face_type": texture_face
				}
			
			var face_data = faces_by_texture[texture_key]
			
			# Add vertices for this face
			for v in range(4):
				face_data.vertices.append(FACE_VERTICES[i][v] + Vector3(pos))
				face_data.normals.append(FACE_NORMALS[i])
				face_data.uvs.append(FACE_UVS[v])
			
			# Add indices for triangles
			var vertex_index = face_data.vertex_count
			face_data.indices.append(vertex_index)
			face_data.indices.append(vertex_index + 1)
			face_data.indices.append(vertex_index + 2)
			face_data.indices.append(vertex_index)
			face_data.indices.append(vertex_index + 2)
			face_data.indices.append(vertex_index + 3)
			
			face_data.vertex_count += 4
