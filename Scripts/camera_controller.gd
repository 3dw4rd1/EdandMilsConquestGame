extends Camera2D

## Camera controller with zoom and pan functionality
## Allows player to navigate the game map

# Pan settings
const PAN_SPEED: float = 500.0
var is_panning: bool = false
var pan_start_position: Vector2

# Zoom settings
const ZOOM_MIN: float = 0.3
const ZOOM_MAX: float = 2.0
const ZOOM_SPEED: float = 0.1

func _ready() -> void:
	# Set initial zoom
	zoom = Vector2(0.5, 0.5)

func _input(event: InputEvent) -> void:
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		
		# Handle panning with middle mouse button or right click
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				start_pan()
			else:
				stop_pan()
	
	# Handle mouse motion for panning
	elif event is InputEventMouseMotion and is_panning:
		pan_camera(event.relative)

func _process(delta: float) -> void:
	# Keyboard panning (WASD or Arrow keys)
	var pan_direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1
	
	if pan_direction.length() > 0:
		position += pan_direction.normalized() * PAN_SPEED * delta / zoom.x

func zoom_in() -> void:
	var new_zoom = zoom.x + ZOOM_SPEED
	new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(new_zoom, new_zoom)

func zoom_out() -> void:
	var new_zoom = zoom.x - ZOOM_SPEED
	new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(new_zoom, new_zoom)

func start_pan() -> void:
	is_panning = true
	pan_start_position = get_global_mouse_position()

func stop_pan() -> void:
	is_panning = false

func pan_camera(relative_motion: Vector2) -> void:
	# Invert the motion for natural dragging feel
	position -= relative_motion / zoom.x
