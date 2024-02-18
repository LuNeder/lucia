extends CharacterBody3D
@onready var parea = $Area3D
@onready var head = $Head
@onready var standing_collision_shape = $standing_CollisionShape3D
@onready var crouching_collision_shape = $crouching_CollisionShape3D
@onready var ray_cast_3d = $RayCast3D

var sprinting = false
var previous_uw = true

var rotAngle = 0
var charTf = 0
var rotTf = 0
var pVec = Vector3.ZERO
var pVec1 = Vector3.ZERO
var pVec2 = Vector3.ZERO


# Speeds in meters per second.
@export var current_speed = 7
@export var walking_speed = 7
@export var sprint_speed = 14
@export var crouching_speed = 2
# jumping and crouching
@export var jump_impulse = 40
@export var crouching_depth = -0.5
@export var heigh = 1.64/2
# The downward acceleration when in the air, in meters per second squared. (gravity)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*10

var target_velocity = Vector3.ZERO
var direction = Vector3.ZERO
@export var mouse_sens = 0.4
@export var lerp_speed = 10 


func _input(event):
	if event is InputEventMouseMotion:
		
		rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		if not PlayerVariables.underwater:
			#rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
			head.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			rotAngle = (-deg_to_rad(event.relative.y * mouse_sens))
			pVec1 = (-transform.basis.y.normalized()).cross(Vector3.UP).normalized()
			pVec2 = (-transform.basis.z.normalized()).cross(Vector3.UP).normalized()
			pVec = pVec1+pVec2
			rotTf = Transform3D().rotated(pVec, rotAngle)
			charTf = transform.rotated(pVec, rotAngle)
			
			rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
			
			#rotate_x(deg_to_rad(event.relative.y * mouse_sens) * pVec1.z)
			#rotate_z(deg_to_rad(event.relative.y * mouse_sens) * pVec1.x)
			#rotate_object_local(pVec,rotAngle)
			#head.rotation.x = clamp(head.rotation.x, deg_to_rad(0), deg_to_rad(170))
			#rotation.z = clamp(rotation.z, deg_to_rad(-91), deg_to_rad(-1))

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	#Movement # todo: water movement
	if Input.is_action_pressed("move_down") and not PlayerVariables.underwater: # Crouching
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, heigh + crouching_depth, delta*lerp_speed)
		crouching_collision_shape.disabled = false
		standing_collision_shape.disabled = true
	elif not ray_cast_3d.is_colliding(): # Can she stand up?
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, heigh, delta*lerp_speed)
		if Input.is_action_pressed("sprint"): # Sprint
			sprinting = true
			current_speed = sprint_speed
		elif not(sprinting and Input.is_action_pressed("move_forward")): # Sticky
			sprinting = false
			current_speed = walking_speed
		
	# We create a local variable to store the input direction.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if PlayerVariables.underwater:
		pass #input_dir = input_dir.rotated(Vector3(1, 0, 0), 0.5)
	direction = lerp(direction, ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()), delta*lerp_speed) #- kinda buggy
	#direction = ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized())

	# We check for each move input and update the direction accordingly.
	if direction:
		target_velocity.x = direction.x * current_speed
		target_velocity.z = direction.z * current_speed
		if PlayerVariables.underwater:
			target_velocity.y = direction.y * current_speed
	else:
		target_velocity.x = move_toward(velocity.x, 0, current_speed)
		target_velocity.z = move_toward(velocity.z, 0, current_speed)	

	if (not is_on_floor()) and (not PlayerVariables.underwater): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y -= (gravity * delta)
	
	if is_on_floor() and Input.is_action_pressed("move_up"): # Jump
		target_velocity.y = jump_impulse

	# water movement up-down
	if PlayerVariables.underwater and Input.is_action_pressed("move_up"):
		target_velocity.y = current_speed
	if PlayerVariables.underwater and Input.is_action_pressed("move_down"):
		target_velocity.y = - current_speed
		
	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	previous_uw = PlayerVariables.underwater
	# Is she underwater?
	if position.y <= 0:
		PlayerVariables.underwater =  not ("AirArea" in str(parea.get_overlapping_areas()))
	else:
		PlayerVariables.underwater =  ("WaterArea" in str(parea.get_overlapping_areas()))
		
	if PlayerVariables.underwater and not previous_uw:
		rotation.x = (-deg_to_rad(90))
	elif previous_uw and not PlayerVariables.underwater: 
		rotation.x = 0
		rotation.z = 0

	# testing
	print('underwater ' + str(PlayerVariables.underwater))
	print(str(parea.get_overlapping_areas())) # This detects the areas!!
	print(current_speed)
	print(input_dir)
	print(-(global_transform.basis.y.normalized()).cross(Vector3.UP))
