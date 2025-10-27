extends Resource
class_name TileProperties

## Defines the data for a single tile in the game
## This is a Resource, which means it can be saved and reused

# Enum for biome types - this creates a predefined list
enum BiomeType {
	FOREST,
	MOUNTAIN,
	SNOW,
	WATER,
	PLAINS  # Added plains as a common tile type
}

# Exported variables can be edited in the Godot Inspector
@export var tile_id: String = ""  # Unique identifier for this tile
@export var biome: BiomeType = BiomeType.PLAINS  # What type of terrain this is
@export_range(1.0, 100.0) var base_population_growth: float = 1.0  # Population growth rate
@export_range(1.0, 100.0) var base_attack: float = 1.0  # Attack rating
@export_range(1.0, 100.0) var base_defense: float = 1.0  # Defense rating

# Optional: Helper function to get biome name as a string
func get_biome_name() -> String:
	match biome:
		BiomeType.FOREST:
			return "Forest"
		BiomeType.MOUNTAIN:
			return "Mountain"
		BiomeType.SNOW:
			return "Snow"
		BiomeType.WATER:
			return "Water"
		BiomeType.PLAINS:
			return "Plains"
		_:
			return "Unknown"
