extends CharacterBody3D
@onready var head = $Head

# How fast the player moves in meters per second.
@export var current_speed = 7
@export var walking_speed = 7
@export var sprint_speed = 14
@export var crouching_speed = 2
# The downward acceleration when in the air, in meters per second squared.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*10
@export var jump_impulse = 40
@export var crouching_depth = -0.5

#var lerp_speed = 100 - kinda buggy
@export var mouse_sens = 0.4

var target_velocity = Vector3.ZERO
var direction = Vector3.ZERO

@onready var parea = $Area3D 

var sprinting = false

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		head.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	#Movement
	if Input.is_action_pressed("move_down"): # todo: water movement
		current_speed = crouching_speed
	else:
		if Input.is_action_pressed("sprint"):
			sprinting = true
			current_speed = sprint_speed
		else:
			if sprinting and Input.is_action_pressed("move_forward"):
				sprinting = true
			else:
				sprinting = false
				current_speed = walking_speed
		
	# We create a local variable to store the input direction.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	#direction = lerp(direction, ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()), delta*lerp_speed)
	direction = ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized())
	# We check for each move input and update the direction accordingly.
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)	
	#if direction != Vector3.ZERO:
	#	direction = direction.normalized()
	#	$Pivot.look_at(position + direction, Vector3.UP)
	# Ground Velocity
	target_velocity.x = direction.x * current_speed
	target_velocity.z = direction.z * current_speed
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y -= (gravity * delta)
	# Jump
	if is_on_floor() and Input.is_action_pressed("move_up"):
		target_velocity.y = jump_impulse
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	# Is she underwater?
	if position.y <= 0:
		PlayerVariables.underwater = not ("AirArea" in str(parea.get_overlapping_areas()))
	else:
		PlayerVariables.underwater = ("WaterArea" in str(parea.get_overlapping_areas()))
		

	# testing
	print('underwater ' + str(PlayerVariables.underwater))
	print(str(parea.get_overlapping_areas())) # This detects the areas!!
	print(current_speed)

