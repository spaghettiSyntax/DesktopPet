extends Node2D

var move_speed = 2
var direction = Vector2(1, 0) # Moving Right
var is_chilling = false

func _input(event):
	# Check for Left Mouse Button Press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_chilling:
			start_chilling()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get access to the actual OS Window (not just the game node)
	var window = get_window()
	
	# 1. TRANSPARENCY SETUP
	# We enable transparency for bot the Godot Viewport and the OS Window
	get_viewport().transparent_bg = true
	window.transparent = true
	
	# 2. WINDOW SHAPE
	# We remove the borders so it looks like the character is floating
	window.borderless = true
	
	# Keep the sprite above your web browser/other apps
	window.always_on_top = true
	
	# Force Windows to relax and let us be borderless
	window.unresizable = false
	
	# Find the floor
	# 1. Get the safe area of the screen (minus taskbars)
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	# 2. Calculate the floor position
	# end.y is pixel coordinate where the taskbar starts.
	# We subtract the window height so the robot stands ON the line, not UNDER it.
	var target_y = usable_rect.end.y - window.size.y
	
	# 3. Snap the sprite there
	# X = 0 (Left edge), Y = target_y (The Floor)
	window.position = Vector2i(0, target_y)
	
	# Run once at start
	_update_mouse_mask()
	
	# Connect signal: Update mask every time animation frame changes
	$AnimatedSprite2D.frame_changed.connect(_update_mouse_mask)
	
	$AnimatedSprite2D.play("roll")
	
	# OPTIMIZATION: CAP FRAMERATE
	Engine.max_fps = 30
	
func _process(_delta):
	# The Red Light!
	# If we are chilling, we hit 'return' and stop reading code.
	# The movement logic below never happens
	if is_chilling: return
	
	var window = get_window()
	
	# Vector2 vs Vector2i
	# Your monitor is a grid of physical pixels. You can't be at Pixel 10.5
	# We use Vector2i (Integer) to tell Windows to move to an exact pixel coordinate.
	
	# Calculate the move
	var move_vector = Vector2i(direction * move_speed)
	
	# Apply it to the OS Window
	window.position += move_vector
	
	# The Safe Zone
	# screen_get_usable_rect() returns the screen area MINUS the taskbars/docks
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	# CHECK RIGHT EDGE
	# If the Right side of our window > The Right side of the screen
	if window.position.x + window.size.x > usable_rect.end.x:
		direction.x = -1 # Reverse Math
		$AnimatedSprite2D.flip_h = true # Flip visual
		
	# CHECK LEFT EDGE
	# If the Left side of our window < The Left side of the screen
	elif window.position.x < usable_rect.position.x:
		direction.x = 1
		$AnimatedSprite2D.flip_h = false
		
func _update_mouse_mask():
	var anim = $AnimatedSprite2D
	
	# 1. Get the raw image data of the CURRENT frame
	var texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	var image = texture.get_image()
	
	# If the sprite is visually flipped, the raw image data ISN'T.
	# We have to manually flip the data to match what the user sees.
	if anim.flip_h:
		image.flip_x()
		
	# 2. Create the Bitmap (The Map of Solid Pixels)
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# 3. Create the Polygons (The Shape)
	# 0.1 means we ignore fully transparent pixels
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()), 0.1)
	
	# 4. Apply it to the OS Window
	DisplayServer.window_set_mouse_passthrough(polygons)
	
func start_chilling():
	is_chilling = true
	$AnimatedSprite2D.play("idle")
	
	# We COULD add a Timer node, connect signals, etc...
	# OR w can use 'await'. It creates a timer, waits for it, and destroys it.
	await get_tree().create_timer(3.0).timeout
	
	# Time's up!
	is_chilling = false
	$AnimatedSprite2D.play("roll")
