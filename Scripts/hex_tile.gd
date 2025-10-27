extends Node2D
class_name HexTile

## Visual representation of a game tile
## Displays as a flat-top hexagon that can change colors

# Reference to the tile's data
@export var tile_properties: TileProperties

# Visual components - we'll assign these in the editor
@onready var hex_polygon: Polygon2D = $HexPolygon

# Hexagon dimensions
const HEX_SIZE: float = 50.0  # Distance from center to corner

# Color for the tile (can be changed based on owner/biome)
var current_color: Color = Color.SKY_BLUE:
	set(value):
		current_color = value
		if hex_polygon:
			hex_polygon.color = current_color

func _ready() -> void:
	# Initialize the hexagon shape if not already set
	if hex_polygon and hex_polygon.polygon.size() == 0:
		setup_hexagon()
	
	# Set initial color
	if hex_polygon:
		hex_polygon.color = current_color

# Creates the flat-top hexagon shape
func setup_hexagon() -> void:
	var points: PackedVector2Array = []
	
	# Flat-top hexagon has 6 points
	# Starting from top-left, going clockwise
	for i in range(6):
		var angle_deg: float = 60.0 * i - 30.0  # -30 offset for flat-top
		var angle_rad: float = deg_to_rad(angle_deg)
		var x: float = HEX_SIZE * cos(angle_rad)
		var y: float = HEX_SIZE * sin(angle_rad)
		points.append(Vector2(x, y))
	
	hex_polygon.polygon = points

# Helper function to set color based on player
func set_player_color(player_id: int) -> void:
	match player_id:
		0:
			current_color = Color.GRAY  # Neutral/unclaimed
		1:
			current_color = Color.BLUE  # Player 1
		2:
			current_color = Color.RED   # Player 2
		3:
			current_color = Color.GREEN # Player 3
		4:
			current_color = Color.YELLOW # Player 4
		_:
			current_color = Color.WHITE

# Helper function to set color based on biome
func set_biome_color() -> void:
	if not tile_properties:
		return
	
	match tile_properties.biome:
		TileProperties.BiomeType.FOREST:
			current_color = Color.DARK_GREEN
		TileProperties.BiomeType.MOUNTAIN:
			current_color = Color.DARK_GRAY
		TileProperties.BiomeType.SNOW:
			current_color = Color.WHITE
		TileProperties.BiomeType.WATER:
			current_color = Color.DARK_BLUE
		TileProperties.BiomeType.PLAINS:
			current_color = Color.YELLOW_GREEN

# Get the tile's properties
func get_tile_properties() -> TileProperties:
	return tile_properties

# Set new tile properties
func set_tile_properties(new_properties: TileProperties) -> void:
	tile_properties = new_properties
