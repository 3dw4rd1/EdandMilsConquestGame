extends Node
class_name GameManager

## Manages the current game session
## Tracks all players, their stats, and tile ownership

# Signal emitted when a player's stats change
signal player_stats_changed(player_id: int)
signal tile_ownership_changed(tile: HexTile, old_owner: int, new_owner: int)

# Game configuration
var number_of_players: int = 2
var current_turn: int = 0

# Player data structure
class PlayerData:
	var player_id: int
	var current_population: float
	var population_growth_rate: float
	var current_army_size: int
	var tiles_owned: Array[HexTile] = []
	
	func _init(id: int, starting_population: float = 10000.0, starting_growth_rate: float = 0.8):
		player_id = id
		current_population = starting_population
		population_growth_rate = starting_growth_rate
		current_army_size = 0

# Dictionary to store player data by player_id
var players: Dictionary = {}  # player_id: int -> PlayerData

# All tiles in the game (for quick reference)
var all_tiles: Array[HexTile] = []

## Initialize the game with the specified number of players
func initialize_game(num_players: int, starting_population: float = 10000.0) -> void:
	number_of_players = num_players
	current_turn = 0
	players.clear()
	all_tiles.clear()
	
	# Create player data for each player
	for i in range(num_players):
		var player_id = i + 1  # Players are 1-indexed (1, 2, 3, etc.)
		players[player_id] = PlayerData.new(player_id, starting_population)
	
	print("Game initialized with %d players" % num_players)

## Register a tile in the game
func register_tile(tile: HexTile) -> void:
	if tile not in all_tiles:
		all_tiles.append(tile)

## Assign a tile to a player (conquest/claiming)
func assign_tile_to_player(tile: HexTile, player_id: int) -> void:
	if not players.has(player_id):
		push_error("Invalid player_id: %d" % player_id)
		return
	
	# Check if tile was owned by another player
	var old_owner: int = 0
	for pid in players.keys():
		var player: PlayerData = players[pid]
		if tile in player.tiles_owned:
			old_owner = pid
			player.tiles_owned.erase(tile)
			break
	
	# Assign to new owner
	players[player_id].tiles_owned.append(tile)
	tile.set_player_color(player_id)
	
	tile_ownership_changed.emit(tile, old_owner, player_id)
	player_stats_changed.emit(player_id)
	if old_owner > 0:
		player_stats_changed.emit(old_owner)

## Get total number of tiles owned by a player
func get_player_tile_count(player_id: int) -> int:
	if not players.has(player_id):
		return 0
	return players[player_id].tiles_owned.size()

## Get all tiles owned by a player
func get_player_tiles(player_id: int) -> Array[HexTile]:
	if not players.has(player_id):
		return []
	return players[player_id].tiles_owned

## Calculate total population growth rate modifier from tiles
func calculate_population_growth_modifier(player_id: int) -> float:
	if not players.has(player_id):
		return 0.0
	
	var total_modifier: float = 0.0
	var player_tiles = players[player_id].tiles_owned
	
	for tile in player_tiles:
		if tile.tile_properties:
			# Add the tile's base population growth bonus
			total_modifier += tile.tile_properties.base_population_growth
	
	return total_modifier

## Calculate total attack modifier from tiles
func calculate_total_attack_modifier(player_id: int) -> float:
	if not players.has(player_id):
		return 0.0
	
	var total_attack: float = 0.0
	var player_tiles = players[player_id].tiles_owned
	
	for tile in player_tiles:
		if tile.tile_properties:
			total_attack += tile.tile_properties.base_attack
	
	return total_attack

## Calculate total defense modifier from tiles
func calculate_total_defense_modifier(player_id: int) -> float:
	if not players.has(player_id):
		return 0.0
	
	var total_defense: float = 0.0
	var player_tiles = players[player_id].tiles_owned
	
	for tile in player_tiles:
		if tile.tile_properties:
			total_defense += tile.tile_properties.base_defense
	
	return total_defense

## Get current population for a player
func get_player_population(player_id: int) -> float:
	if not players.has(player_id):
		return 0.0
	return players[player_id].current_population

## Get current army size for a player
func get_player_army_size(player_id: int) -> int:
	if not players.has(player_id):
		return 0
	return players[player_id].current_army_size

## Set army size for a player (when they allocate population to military)
func set_player_army_size(player_id: int, army_size: int) -> void:
	if not players.has(player_id):
		return
	
	players[player_id].current_army_size = army_size
	player_stats_changed.emit(player_id)

## Update population growth for a single player (call this each turn)
func update_player_population(player_id: int) -> void:
	if not players.has(player_id):
		return
	
	var player: PlayerData = players[player_id]
	
	# Calculate growth: base rate + tile modifiers
	var growth_modifier = calculate_population_growth_modifier(player_id)
	var effective_growth_rate = player.population_growth_rate + (growth_modifier / 100.0)
	
	# Apply growth to population
	var growth_amount = player.current_population * (effective_growth_rate / 100.0)
	player.current_population += growth_amount
	
	player_stats_changed.emit(player_id)

## Update all players' population (call at end of turn)
func update_all_populations() -> void:
	for player_id in players.keys():
		update_player_population(player_id)

## Advance to next turn
func next_turn() -> void:
	current_turn += 1
	update_all_populations()
	print("Turn %d" % current_turn)

## Get summary of player stats (useful for UI display)
func get_player_summary(player_id: int) -> Dictionary:
	if not players.has(player_id):
		# Return default empty stats instead of empty dictionary
		return {
			"player_id": player_id,
			"population": 0.0,
			"army_size": 0,
			"tiles_owned": 0,
			"growth_rate": 0.0,
			"growth_modifier": 0.0,
			"attack_modifier": 0.0,
			"defense_modifier": 0.0
		}
	
	var player: PlayerData = players[player_id]
	return {
		"player_id": player_id,
		"population": player.current_population,
		"army_size": player.current_army_size,
		"tiles_owned": player.tiles_owned.size(),
		"growth_rate": player.population_growth_rate,
		"growth_modifier": calculate_population_growth_modifier(player_id),
		"attack_modifier": calculate_total_attack_modifier(player_id),
		"defense_modifier": calculate_total_defense_modifier(player_id)
	}

## Debug: Print all player stats
func print_all_player_stats() -> void:
	print("\n=== GAME STATS - Turn %d ===" % current_turn)
	for player_id in players.keys():
		var stats = get_player_summary(player_id)
		print("Player %d:" % player_id)
		print("  Population: %.0f" % stats.population)
		print("  Army: %d" % stats.army_size)
		print("  Tiles: %d" % stats.tiles_owned)
		print("  Growth Rate: %.2f%% (base) + %.2f (tiles)" % [stats.growth_rate, stats.growth_modifier])
	print("========================\n")
