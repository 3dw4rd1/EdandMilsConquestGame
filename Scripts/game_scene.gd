extends Node2D

## Main Game Scene
## Generates the tile grid, initializes game, and manages gameplay

# Preload the hex tile scene
const HEX_TILE_SCENE = preload("res://Scenes/hex_tile.tscn")

# Grid configuration - NOW BIGGER MAP!
const GRID_WIDTH: int = 50  # Changed from 10 to 50
const GRID_HEIGHT: int = 20  # Changed from 10 to 20
const TILE_SPACING: float = 90.0  # Distance between tile centers (slightly less than 2*HEX_SIZE for overlap)

# References
@onready var game_manager: GameManager = $GameManager
@onready var tile_container: Node2D = $TileContainer
@onready var hud: Control = $HUD
@onready var camera: Camera2D = $Camera2D

# Map generator
var map_generator: MapGenerator

# Store generated tiles (visuals)
var tiles: Array[HexTile] = []

# Store tile data separately from visuals
var tile_data_grid: Dictionary = {}  # Vector2i -> MapGenerator.HexTileData

# Quick lookup: grid position to visual tile
var grid_to_tile: Dictionary = {}  # Vector2i -> HexTile

func _ready() -> void:
	# Create map generator
	map_generator = MapGenerator.new()
	
	# Initialize game with 4 players
	game_manager.initialize_game(4)
	
	# Generate the map data (separate from visuals)
	tile_data_grid = map_generator.generate_map(GRID_WIDTH, GRID_HEIGHT)
	
	# Generate the visual tile grid
	generate_tile_grid()
	
	# Assign starting tiles to players with smart spawning
	assign_starting_tiles()
	
	# Center camera on the map
	center_camera_on_map()
	
	# Update HUD to show initial stats
	if hud and hud.has_method("update_all_stats"):
		hud.update_all_stats()
	
	print("Game scene loaded with %d tiles" % tiles.size())

## Generate visual tiles from map data
func generate_tile_grid() -> void:
	print("Generating visual tiles for %dx%d grid..." % [GRID_WIDTH, GRID_HEIGHT])
	
	var tile_count = 0
	
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var grid_pos = Vector2i(x, y)
			
			# Get tile data from map generator
			var tile_data: MapGenerator.HexTileData = tile_data_grid.get(grid_pos)
			if not tile_data:
				push_error("Missing tile data at %s" % grid_pos)
				continue
			
			# Instantiate visual hex tile
			var tile = HEX_TILE_SCENE.instantiate()
			
			# Calculate world position (same hex grid logic as before)
			var x_offset = x * TILE_SPACING
			var y_offset = y * TILE_SPACING * 0.75  # 0.75 for proper hex vertical spacing
			
			# Offset odd rows to create hex grid pattern
			if y % 2 == 1:
				x_offset += TILE_SPACING * 0.5
			
			tile.position = Vector2(x_offset, y_offset)
			
			# Store world position in tile data for reference
			tile_data.world_position = tile.position
			
			# Set tile properties from generated data
			tile.tile_properties = tile_data.properties
			
			# Set visual based on biome
			tile.set_biome_color()
			
			# Optimization: Disable processing on neutral tiles (they don't need updates)
			tile.set_process(false)
			tile.set_physics_process(false)
			
			# Add to scene and track
			tile_container.add_child(tile)
			tiles.append(tile)
			game_manager.register_tile(tile)
			
			# Store in lookup dictionary
			grid_to_tile[grid_pos] = tile
			
			tile_count += 1
	
	print("Generated %d visual tiles" % tile_count)

## Assign starting tiles to players using smart spawning
func assign_starting_tiles() -> void:
	# Get spawn positions from map generator (smart placement in corners)
	var spawn_positions = map_generator.get_spawn_positions(4)
	
	print("Assigning starting tiles to players...")
	
	# Assign each player their starting tile
	for i in range(min(4, spawn_positions.size())):
		var player_id = i + 1
		var grid_pos = spawn_positions[i]
		
		# Get the visual tile at this position
		var starting_tile = grid_to_tile.get(grid_pos)
		
		if starting_tile:
			game_manager.assign_tile_to_player(starting_tile, player_id)
			print("Player %d spawned at %s (%s biome)" % [
				player_id, 
				grid_pos,
				starting_tile.tile_properties.get_biome_name()
			])
		else:
			push_error("Could not find tile at spawn position %s" % grid_pos)

## Center camera on the map
func center_camera_on_map() -> void:
	if tiles.is_empty():
		return
	
	# Calculate center of the tile grid
	var total_position = Vector2.ZERO
	for tile in tiles:
		total_position += tile.position
	
	var center = total_position / tiles.size()
	camera.position = center

## Called when advancing to next turn
func next_turn() -> void:
	game_manager.next_turn()
	
	# Update HUD
	if hud and hud.has_method("update_all_stats"):
		hud.update_all_stats()
	
	# Debug: print stats
	game_manager.print_all_player_stats()
