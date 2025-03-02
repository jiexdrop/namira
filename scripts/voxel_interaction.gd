class_name VoxelInteraction
extends Node

const VoxelData = preload("res://scripts/voxel_data.gd")
const MAX_RAYCAST_DISTANCE = 5.0
const RAYCAST_STEPS = 50

var chunk_manager: ChunkManager
var mesh_generator: MeshGenerator

func _init(p_chunk_manager: ChunkManager, p_mesh_generator: MeshGenerator):
    chunk_manager = p_chunk_manager
    mesh_generator = p_mesh_generator

func get_target_voxel(camera: Camera3D) -> Dictionary:
    var result = {
        "chunk": null,
        "voxel_pos": Vector3i.ZERO,
        "hit": false
    }
    
    var from = camera.global_position
    var direction = -camera.global_transform.basis.z
    var step_size = MAX_RAYCAST_DISTANCE / RAYCAST_STEPS
    
    for i in range(RAYCAST_STEPS):
        var check_pos = from + direction * (step_size * i)
        var chunk_pos = Vector3i(
            floor(check_pos.x / VoxelData.CHUNK_SIZE),
            floor(check_pos.y / VoxelData.CHUNK_SIZE),
            floor(check_pos.z / VoxelData.CHUNK_SIZE)
        )
        
        var chunk = chunk_manager.get_chunk(chunk_pos)
        if chunk:
            var local_pos = Vector3i(
                posmod(int(check_pos.x), VoxelData.CHUNK_SIZE),
                posmod(int(check_pos.y), VoxelData.CHUNK_SIZE),
                posmod(int(check_pos.z), VoxelData.CHUNK_SIZE)
            )
            
            var voxel = chunk.get_voxel(local_pos)
            if voxel and voxel.type == VoxelData.VoxelType.SOLID:
                result.chunk = chunk
                result.voxel_pos = local_pos
                result.hit = true
                break
    
    return result

func break_voxel(chunk: Chunk, voxel_pos: Vector3i) -> void:
    var voxel = VoxelData.Voxel.new()
    voxel.type = VoxelData.VoxelType.AIR
    chunk.set_voxel(voxel_pos, voxel)
    mesh_generator.generate_chunk_mesh(chunk)