extends Node
class_name MapGenerator

## GENTLE VERSION - Minimal edge penalty to avoid too much water

# Map configuration
var map_width: int = 50
var map_height: int = 20
var seed_value: int = 0

# Biome distribution settings
const WATER_THRESHOLD: float = -0.3  # Lower threshold
const LAKE_THRESHOLD: float = 0.62
const SNOW_THRESHOLD: float = 0.5
const MOUNTAIN_THRESHOLD: float = 0.3
const FOREST_THRESHOLD: float = -0.1

# Noise generators
var noise: FastNoiseLite
var continent_noise: FastNoiseLite
var lake_noise: FastNoiseLite

class HexTileData:
	var grid_position: Vector2i
	var world_position: Vector2
	var biome: TileProperties.BiomeType
	var properties: TileProperties
	var owner_id: int = -1
	
	func _init(pos: Vector2i):
		grid_position = pos

var tile_data_grid: Dictionary = {}

func generate_map(width: int = 50, height: int = 20, custom_seed: int = 0) -> Dictionary:
	map_width = width
	map_height = height
	seed_value = custom_seed
	
	_setup_noise()
	_generate_tile_data()
	_assign_tile_properties()
	
	print("Map generated: %dx%d = %d tiles" % [map_width, map_height, tile_data_grid.size()])
	_print_biome_distribution()
	
	return tile_data_grid

func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	continent_noise = FastNoiseLite.new()
	lake_noise = FastNoiseLite.new()
	
	if seed_value == 0:
		noise.seed = randi()
		continent_noise.seed = noise.seed + 1000
		lake_noise.seed = noise.seed + 2000
	else:
		noise.seed = seed_value
		continent_noise.seed = seed_value + 1000
		lake_noise.seed = seed_value + 2000
	
	# TERRAIN NOISE
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.12
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	
	# CONTINENT NOISE - for land/water variation
	continent_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	continent_noise.frequency = 0.04  # Lower for larger regions
	continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	continent_noise.fractal_octaves = 2
	
	# LAKE NOISE
	lake_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	lake_noise.frequency = 0.08
	lake_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	lake_noise.fractal_octaves = 2
	
	print("Noise generator initialized with seed: %d" % noise.seed)

func _generate_tile_data() -> void:
	tile_data_grid.clear()
	
	for y in range(map_height):
		for x in range(map_width):
			var grid_pos = Vector2i(x, y)
			var tile = HexTileData.new(grid_pos)
			
			var noise_value = noise.get_noise_2d(float(x), float(y))
			tile.biome = _determine_biome(noise_value, x, y)
			
			tile_data_grid[grid_pos] = tile

func _determine_biome(noise_value: float, x: int, y: int) -> TileProperties.BiomeType:
	# Get continent noise (-1 to 1)
	var continent_value = continent_noise.get_noise_2d(float(x), float(y))
	
	# Get edge fade (0 at edges, 1 at center)
	var edge_fade = _calculate_edge_fade(x, y)
	
	# MUCH GENTLER edge penalty - only apply at very edges
	var edge_penalty = (1.0 - edge_fade) * 0.4  # MUCH weaker (was 0.8)
	var modified = continent_value - edge_penalty
	
	# With penalty of 0.4 and threshold of -0.3:
	# At edges: -1 - 0.4 = -1.4 to 1 - 0.4 = 0.6
	#   Water if < -0.3, so roughly -1.4 to -0.3 range = some water
	# At center: -1 - 0 = -1 to 1 - 0 = 1
	#   Water if < -0.3, so roughly -1 to -0.3 range = some water
	
	if modified < WATER_THRESHOLD:
		return TileProperties.BiomeType.WATER
	
	# Inland lakes
	var lake_value = lake_noise.get_noise_2d(float(x), float(y))
	if lake_value > LAKE_THRESHOLD:
		return TileProperties.BiomeType.WATER
	
	# Land biomes
	if noise_value > SNOW_THRESHOLD:
		if randf() > 0.3:
			return TileProperties.BiomeType.SNOW
		else:
			return TileProperties.BiomeType.MOUNTAIN
	elif noise_value > MOUNTAIN_THRESHOLD:
		return TileProperties.BiomeType.MOUNTAIN
	elif noise_value > FOREST_THRESHOLD:
		return TileProperties.BiomeType.FOREST
	else:
		return TileProperties.BiomeType.PLAINS

func _calculate_edge_fade(x: int, y: int) -> float:
	# Normalize positions
	var norm_x = float(x) / float(map_width - 1)
	var norm_y = float(y) / float(map_height - 1)
	
	# Distance from center
	var dist_x = 0.5 - abs(norm_x - 0.5)
	var dist_y = 0.5 - abs(norm_y - 0.5)
	
	# Use minimum
	var edge_dist = min(dist_x, dist_y)
	
	# Scale to 0-1
	var fade = edge_dist * 2.0
	
	# Smoothstep
	fade = fade * fade * (3.0 - 2.0 * fade)
	
	return fade

func _assign_tile_properties() -> void:
	for grid_pos in tile_data_grid.keys():
		var tile: HexTileData = tile_data_grid[grid_pos]
		
		var props = TileProperties.new()
		props.tile_id = "tile_%d_%d" % [grid_pos.x, grid_pos.y]
		props.biome = tile.biome
		
		match tile.biome:
			TileProperties.BiomeType.PLAINS:
				props.base_population_growth = 8.0
				props.base_attack = 5.0
				props.base_defense = 5.0
			TileProperties.BiomeType.FOREST:
				props.base_population_growth = 6.0
				props.base_attack = 7.0
				props.base_defense = 8.0
			TileProperties.BiomeType.MOUNTAIN:
				props.base_population_growth = 3.0
				props.base_attack = 6.0
				props.base_defense = 12.0
			TileProperties.BiomeType.SNOW:
				props.base_population_growth = 2.0
				props.base_attack = 4.0
				props.base_defense = 10.0
			TileProperties.BiomeType.WATER:
				props.base_population_growth = 1.0
				props.base_attack = 2.0
				props.base_defense = 15.0
		
		tile.properties = props

func get_tile_data(grid_pos: Vector2i) -> HexTileData:
	return tile_data_grid.get(grid_pos)

func get_all_tile_data() -> Dictionary:
	return tile_data_grid

func get_spawn_positions(num_players: int) -> Array[Vector2i]:
	var spawn_positions: Array[Vector2i] = []
	
	# STEP 1: Find ALL land tiles (Plains and Forest only)
	var valid_biomes = [
		TileProperties.BiomeType.PLAINS,
		TileProperties.BiomeType.FOREST
	]
	
	var all_land_tiles: Array[Vector2i] = []
	for grid_pos in tile_data_grid.keys():
		var tile: HexTileData = tile_data_grid[grid_pos]
		if tile.biome in valid_biomes:
			all_land_tiles.append(grid_pos)
	
	print("Found %d valid land tiles for spawning" % all_land_tiles.size())
	
	if all_land_tiles.size() == 0:
		print("ERROR: No valid land tiles found!")
		return spawn_positions
	
	# STEP 2: Divide land tiles into quadrants
	var land_by_quadrant = _divide_land_into_quadrants(all_land_tiles, num_players)
	
	# STEP 3: Pick one random spawn from each quadrant
	for quadrant_index in range(num_players):
		if land_by_quadrant.has(quadrant_index) and land_by_quadrant[quadrant_index].size() > 0:
			var quadrant_tiles: Array = land_by_quadrant[quadrant_index]
			
			# Try to find a spawn that's not too close to existing spawns
			var spawn_pos = _pick_spawn_from_tiles(quadrant_tiles, spawn_positions)
			
			if spawn_pos != Vector2i(-1, -1):
				spawn_positions.append(spawn_pos)
				print("Player %d spawn: quadrant %d at %s" % [spawn_positions.size(), quadrant_index, spawn_pos])
			else:
				print("Warning: Could not find valid spawn in quadrant %d" % quadrant_index)
	
	print("Generated %d spawn positions" % spawn_positions.size())
	return spawn_positions

## Divide land tiles into quadrants based on position
func _divide_land_into_quadrants(land_tiles: Array[Vector2i], num_players: int) -> Dictionary:
	var quadrants = {}
	
	for tile_pos in land_tiles:
		var quadrant_index = _get_quadrant_index(tile_pos, num_players)
		
		if not quadrants.has(quadrant_index):
			quadrants[quadrant_index] = []
		
		quadrants[quadrant_index].append(tile_pos)
	
	# Print distribution
	for i in range(num_players):
		if quadrants.has(i):
			print("Quadrant %d: %d land tiles" % [i, quadrants[i].size()])
		else:
			print("Quadrant %d: 0 land tiles (WARNING!)" % i)
	
	return quadrants

## Determine which quadrant a position belongs to
func _get_quadrant_index(pos: Vector2i, num_players: int) -> int:
	# Normalize position (0 to 1)
	var norm_x = float(pos.x) / float(map_width - 1)
	var norm_y = float(pos.y) / float(map_height - 1)
	
	match num_players:
		2:
			# Left vs Right
			if norm_x < 0.5:
				return 0  # Left
			else:
				return 1  # Right
		
		3:
			# Left, Center, Right
			if norm_x < 0.33:
				return 0  # Left
			elif norm_x < 0.67:
				return 1  # Center
			else:
				return 2  # Right
		
		4, _:
			# Four corners: Top-Left, Top-Right, Bottom-Left, Bottom-Right
			var is_left = norm_x < 0.5
			var is_top = norm_y < 0.5
			
			if is_top and is_left:
				return 0  # Top-Left
			elif is_top and not is_left:
				return 1  # Top-Right
			elif not is_top and is_left:
				return 2  # Bottom-Left
			else:
				return 3  # Bottom-Right
	
	return 0

## Pick a spawn position from available tiles, avoiding existing spawns
func _pick_spawn_from_tiles(available_tiles: Array, existing_spawns: Array[Vector2i]) -> Vector2i:
	const MIN_DISTANCE = 8
	const MAX_ATTEMPTS = 50
	
	# Shuffle tiles for randomness
	var shuffled = available_tiles.duplicate()
	shuffled.shuffle()
	
	# Try to find a tile that's far enough from existing spawns
	for attempt in range(min(MAX_ATTEMPTS, shuffled.size())):
		var candidate: Vector2i = shuffled[attempt]
		
		# Check distance from all existing spawns
		var too_close = false
		for existing_pos in existing_spawns:
			if candidate.distance_to(existing_pos) < MIN_DISTANCE:
				too_close = true
				break
		
		if not too_close:
			return candidate
	
	# If we couldn't find one far enough, just return the first available
	if shuffled.size() > 0:
		print("Warning: Could not maintain minimum distance, using close spawn")
		return shuffled[0]
	
	return Vector2i(-1, -1)

func _print_biome_distribution() -> void:
	var biome_counts = {
		TileProperties.BiomeType.PLAINS: 0,
		TileProperties.BiomeType.FOREST: 0,
		TileProperties.BiomeType.MOUNTAIN: 0,
		TileProperties.BiomeType.SNOW: 0,
		TileProperties.BiomeType.WATER: 0
	}
	
	for tile_data in tile_data_grid.values():
		biome_counts[tile_data.biome] += 1
	
	var total = tile_data_grid.size()
	print("Biome Distribution:")
	print("  Plains: %d (%.1f%%)" % [biome_counts[TileProperties.BiomeType.PLAINS], 100.0 * biome_counts[TileProperties.BiomeType.PLAINS] / total])
	print("  Forest: %d (%.1f%%)" % [biome_counts[TileProperties.BiomeType.FOREST], 100.0 * biome_counts[TileProperties.BiomeType.FOREST] / total])
	print("  Mountain: %d (%.1f%%)" % [biome_counts[TileProperties.BiomeType.MOUNTAIN], 100.0 * biome_counts[TileProperties.BiomeType.MOUNTAIN] / total])
	print("  Snow: %d (%.1f%%)" % [biome_counts[TileProperties.BiomeType.SNOW], 100.0 * biome_counts[TileProperties.BiomeType.SNOW] / total])
	print("  Water: %d (%.1f%%)" % [biome_counts[TileProperties.BiomeType.WATER], 100.0 * biome_counts[TileProperties.BiomeType.WATER] / total])
