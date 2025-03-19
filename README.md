# Namira Voxel Game 
A simple voxel-based game created using Godot Engine.

# Features

First-person camera controls
Terrain generation with different block types
Block placing and breaking
Multiple block types (Stone, Dirt, Grass, Oak Planks, Cobblestone)
Block selection via number keys (1-5) or mouse scroll wheel

# Controls

-WASD: Move around
-Space: Move up
-Shift: Move down
-Mouse: Look around
-Left Click: Break blocks
-Right Click: Place blocks
-Mouse Wheel: Cycle through block types
-Number Keys (1-5): Select specific block types
-Esc: Toggle mouse capture

# Technical Details
The game uses a chunked voxel system with the following components:

ChunkManager: Handles chunk creation and management
Chunk: Represents a section of the world (16x16x16 blocks)
MeshGenerator: Creates the visual meshes for chunks
VoxelInteraction: Handles block placement and breaking
CameraController: Player movement and control

# Getting Started

Open the project in Godot Engine
Run the world.tscn scene
Start building and exploring!

Future Improvements

Add more block types
Implement better terrain generation
Add inventory system
Add crafting mechanics
Implement multiplayer support
