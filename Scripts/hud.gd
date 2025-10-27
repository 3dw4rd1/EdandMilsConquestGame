extends Control

## HUD - Heads Up Display
## Shows player stats and game information

@onready var player_stats_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/PlayerStatsContainer
@onready var turn_label: Label = $Panel/MarginContainer/VBoxContainer/TurnLabel
@onready var next_turn_button: Button = $Panel/MarginContainer/VBoxContainer/NextTurnButton

# Reference to game manager (set by parent)
var game_manager: GameManager

func _ready() -> void:
	# Get game manager from parent scene
	game_manager = get_parent().get_node("GameManager")
	
	# Connect button
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	
	# Initial update
	update_all_stats()

## Update all player stats displayed on HUD
func update_all_stats() -> void:
	if not game_manager:
		return
	
	# Update turn counter
	if turn_label:
		turn_label.text = "Turn: %d" % game_manager.current_turn
	
	# Clear existing stat labels
	if player_stats_container:
		for child in player_stats_container.get_children():
			child.queue_free()
		
		# Create stat labels for each player
		for player_id in range(1, game_manager.number_of_players + 1):
			var stats = game_manager.get_player_summary(player_id)
			var label = create_player_stat_label(stats)
			player_stats_container.add_child(label)

## Create a label showing one player's stats
func create_player_stat_label(stats: Dictionary) -> Label:
	var label = Label.new()
	
	# Get player color for visual identification
	var color_name = get_player_color_name(stats.player_id)
	
	# Format the stats text
	var text = "[%s] Player %d\n" % [color_name, stats.player_id]
	text += "  Pop: %.0f (%.2f%% growth)\n" % [stats.population, stats.growth_rate]
	text += "  Army: %d\n" % stats.army_size
	text += "  Tiles: %d\n" % stats.tiles_owned
	text += "  Attack: %.0f | Defense: %.0f" % [stats.attack_modifier, stats.defense_modifier]
	
	label.text = text
	
	# Optional: Color the text based on player
	label.add_theme_color_override("font_color", get_player_display_color(stats.player_id))
	
	return label

## Get player color name as string
func get_player_color_name(player_id: int) -> String:
	match player_id:
		1: return "BLUE"
		2: return "RED"
		3: return "GREEN"
		4: return "YELLOW"
		_: return "GRAY"

## Get player color for UI display
func get_player_display_color(player_id: int) -> Color:
	match player_id:
		1: return Color.DODGER_BLUE
		2: return Color.CRIMSON
		3: return Color.LIME_GREEN
		4: return Color.GOLD
		_: return Color.GRAY

## Called when next turn button is pressed
func _on_next_turn_pressed() -> void:
	var game_scene = get_parent()
	if game_scene.has_method("next_turn"):
		game_scene.next_turn()
