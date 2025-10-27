extends Node2D

## Main Game Scene
## Generates the tile grid, initializes game, and manages gameplay

# Preload the hex tile scene
const HEX_TILE_SCENE = preload("res://Scenes/hex_tile.tscn")

# Grid configuration
const GRID_WIDTH: int = 10
const GRID_HEIGHT: int = 10
const TILE_SPACING: float = 90.0  # Distance between tile centers (slightly less than 2*HEX_SIZE for overlap)

# References
@onready var game_manager: GameManager = $GameManager
@onready var tile_container: Node2D = $TileContainer
@onready var hud: Control = $HUD
@onready var camera: Camera2D = $Camera2D

# Store generated tiles
var tiles: Array[HexTile] = []

func _ready() -> void:
	# Initialize game with 4 players
	game_manager.initialize_game(4)
	
	# Generate the tile grid
	generate_tile_grid()
	
	# Assign starting tiles to players
	assign_starting_tiles()
	
	# Center camera on the map
	center_camera_on_map()
	
	# Update HUD to show initial stats
	if hud and hud.has_method("update_all_stats"):
		hud.update_all_stats()
	
	print("Game scene loaded with %d tiles" % tiles.size())

## Generate a grid of hex tiles
func generate_tile_grid() -> void:
	# Create a simple TileProperties for all tiles (all same biome for MVP)
	var default_tile_properties = TileProperties.new()
	default_tile_properties.biome = TileProperties.BiomeType.PLAINS
	default_tile_properties.base_population_growth = 5.0
	default_tile_properties.base_attack = 10.0
	default_tile_properties.base_defense = 10.0
	
	var tile_index = 0
	
	for row in range(GRID_HEIGHT):
		for col in range(GRID_WIDTH):
			# Instantiate hex tile
			var tile = HEX_TILE_SCENE.instantiate()
			
			# Calculate position
			# Hexagons in flat-top orientation
			# Offset every other row for hex grid look
			var x_offset = col * TILE_SPACING
			var y_offset = row * TILE_SPACING * 0.75  # 0.75 for proper hex vertical spacing
			
			# Offset odd rows to create hex grid pattern
			if row % 2 == 1:
				x_offset += TILE_SPACING * 0.5
			
			tile.position = Vector2(x_offset, y_offset)
			
			# Set tile properties
			tile.tile_properties = default_tile_properties
			tile.tile_properties.tile_id = "tile_%d" % tile_index
			
			# Set neutral color initially
			tile.set_player_color(0)
			
			# Add to scene and track
			tile_container.add_child(tile)
			tiles.append(tile)
			game_manager.register_tile(tile)
			
			tile_index += 1

## Assign one starting tile to each player
func assign_starting_tiles() -> void:
	# Give player 1-4 their starting tiles (first 4 tiles)
	for player_id in range(1, 5):
		if player_id - 1 < tiles.size():
			var starting_tile = tiles[player_id - 1]
			game_manager.assign_tile_to_player(starting_tile, player_id)

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
