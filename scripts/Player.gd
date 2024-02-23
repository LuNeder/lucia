extends CharacterBody3D
@onready var parea = $Area3D
@onready var fpcamarea = $skin/Head/Camera3D/fpcamArea3D
@onready var tpcamarea = $Pivot/Pivot_v/spring/tpcCamera3D/tpcamArea3D
@onready var head = $skin/Head
@onready var standing_collision_shape = $standing_CollisionShape3D
@onready var crouching_collision_shape = $crouching_CollisionShape3D
@onready var ray_cast_3d = $RayCast3D
@onready var water_ray_cast = $"water-RayCast"
@onready var ocean = $"/root/Node3D//Ocean"
@onready var tpcspring = $Pivot/Pivot_v/spring
@onready var fpcam = $skin/Head/Camera3D
@onready var tpcam = $Pivot/Pivot_v/spring/tpcCamera3D
@onready var cpivot_v = $Pivot/Pivot_v
@onready var cpivot_h = $Pivot
@onready var skin = $skin
const underwater_env = preload("res://scenes/Environments/underwater-env.tres")
const land_env = preload("res://scenes/Environments/land-env.tres")

var sprinting: bool = false
var dashing: bool = false
var previous_uw: bool = true

var rotAngle: float = 0
var charTf: float = 0
var rotTf: float = 0
var pVec: Vector3 = Vector3.ZERO
var pVec1: Vector3 = Vector3.ZERO
var pVec2: Vector3 = Vector3.ZERO
var heads: Array = []
var heady = head 

# Speeds in meters per second.
@export var current_max_speed: float = 7
@export var walking_speed: float = 7
@export var sprint_speed: float = 14
@export var swimming_speed: float = 14
@export var uw_sprint_speed: float = 28.5
@export var dashing_speed: float = 2400
@export var crouching_speed: float = 2
# jumping and crouching
@export var jump_impulse: float = 40
@export var crouching_depth: float = -0.5
@export var heigh: float = 0.68#1.64/2
# The downward acceleration when in the air, in meters per second squared. (gravity) *10
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") *10
# Accelerations:
@export var uw_deccel: float = 4.0 
@export var air_deccel: float = 0.5 
@export var ground_deccel: float = 12.0 
@export var player_accel: float = 6.0 
@export var current_accel: float = 0.0 

var target_velocity: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var cam_dir: Vector2 = Vector2.ZERO
var camdir_prev: Vector2 = Vector2.ZERO
@export var mouse_sens: float = 0.4
@export var joycam_sens: float = 5
@export var lerp_speed: float = 10 


func _input(event):
	# Camera (mouse)
	if event is InputEventMouseMotion and PlayerVariables.fpcam:
		rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		head.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
		if not PlayerVariables.underwater:
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(0), deg_to_rad(170))
	
	# 3rd person Camera (mouse)
	if event is InputEventMouseMotion and !PlayerVariables.fpcam:
		rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		if PlayerVariables.underwater:
			skin.rotate_z(deg_to_rad(event.relative.x * mouse_sens))
		else:
			skin.rotate_y(deg_to_rad(event.relative.x * mouse_sens))
		
		cpivot_v.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
		
		if not PlayerVariables.underwater:
			cpivot_v.rotation.x = clamp(cpivot_v.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			cpivot_v.rotation.x = clamp(cpivot_v.rotation.x, deg_to_rad(20), deg_to_rad(175)) # TODO: looping for some reason
			
	# Camera Person set
	if ((event is InputEventKey) or (event is InputEventJoypadButton) ) and (Input.is_action_just_pressed("cam-chg")):
		PlayerVariables.fpcam = abs(PlayerVariables.fpcam - 1)
		print(PlayerVariables.fpcam)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	tpcam.current = !PlayerVariables.fpcam #disables/enables 3rd person camera	
	# Camera (joystick)
	camdir_prev = cam_dir
	cam_dir = Input.get_vector("cam-l", "cam-r", "cam-u", "cam-d")
	if (cam_dir.length() > 0) and PlayerVariables.fpcam:
		rotate_y(-deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
		head.rotate_x(-deg_to_rad(cam_dir.y * mouse_sens*joycam_sens))
		if not PlayerVariables.underwater:
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(0), deg_to_rad(170))

	# 3rd Person Camera (joystick)
	elif cam_dir.length() > 0:
		rotate_y(-deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
		if PlayerVariables.underwater:
			skin.rotate_z(deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
		else:
			skin.rotate_y(deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
			
		cpivot_v.rotate_x(deg_to_rad(cam_dir.y * mouse_sens*joycam_sens))
		
		if not PlayerVariables.underwater:
			cpivot_v.rotation.x = clamp(cpivot_v.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			cpivot_v.rotation.x = clamp(cpivot_v.rotation.x, deg_to_rad(20), deg_to_rad(175)) # TODO: looping for some reason
	
	standing_collision_shape.rotation = skin.rotation
	crouching_collision_shape.rotation = skin.rotation
	

func _physics_process(delta):
	# Dashing, Crouching and Sprinting
	if Input.is_action_just_pressed("dash"): #dashing
		pass #dashing = true
	elif Input.is_action_pressed("move_down") and not PlayerVariables.underwater: # Crouching
		current_max_speed = crouching_speed
		head.position.y = lerp(head.position.y, heigh + crouching_depth, delta*lerp_speed)
		crouching_collision_shape.disabled = false
		standing_collision_shape.disabled = true
	elif not ray_cast_3d.is_colliding(): # Can she stand up?
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, heigh, delta*lerp_speed)
		if Input.is_action_pressed("sprint"): # Sprint
			sprinting = true
			if not PlayerVariables.underwater: current_max_speed = sprint_speed
			else: current_max_speed = uw_sprint_speed
		elif not(sprinting and Input.is_action_pressed("move_forward")): # Sticky
			sprinting = false
			if (not dashing) and (not PlayerVariables.underwater): current_max_speed = walking_speed
			elif PlayerVariables.underwater and not dashing: current_max_speed = swimming_speed
	
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back") # We create a local variable to store the input direction.
	# Land movement
	if not PlayerVariables.underwater:
		if input_dir != Vector2.ZERO: current_accel = player_accel
		else: current_accel = ground_deccel
		
		direction = ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()) #lerp(direction, ((transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()), delta*lerp_speed)

		if (not is_on_floor()): # If in the air, fall towards the floor. Literally gravity
			current_accel = air_deccel
			target_velocity.y = velocity.y - (gravity * delta)
	
		if is_on_floor() and Input.is_action_pressed("move_up"): # Jump
			target_velocity.y = jump_impulse

	# Water movement
	if PlayerVariables.underwater:
		current_accel = player_accel
		if input_dir == Vector2.ZERO and (not Input.is_action_pressed("move_up")) and (not Input.is_action_pressed("move_down")):
			current_accel = uw_deccel
			direction = Vector3.ZERO
			target_velocity.y = move_toward(velocity.y, 0, current_accel*delta)
		# uw-up-down
		if Input.is_action_pressed("move_up"):
			target_velocity.y = current_max_speed
		if Input.is_action_pressed("move_down"):
			target_velocity.y = - current_max_speed
		
		# uw-wasd
		heads = [cpivot_v, head]
		heady = heads[PlayerVariables.fpcam] # 0 for 3rd person, 1 for 1st person
		if Input.is_action_pressed("move_forward"):
			direction = lerp(direction, ((- heady.global_transform.basis.z.normalized()).normalized()), delta*lerp_speed)
		if Input.is_action_pressed("move_back"):
			direction  = lerp(direction, ((heady.global_transform.basis.z.normalized()).normalized()), delta*lerp_speed)
		if Input.is_action_pressed("move_left"):
			direction = lerp(direction, ((- heady.global_transform.basis.x.normalized()).normalized()), delta*lerp_speed)
		if Input.is_action_pressed("move_right"):
			direction = lerp(direction, ((heady.global_transform.basis.x.normalized()).normalized()), delta*lerp_speed)
		
		
	# We check for each move input and update the direction accordingly.
	if direction:
		current_accel = current_accel
		target_velocity.x = move_toward(velocity.x, current_max_speed  * direction.x * input_dir.length(), current_accel*delta)
		target_velocity.z = move_toward(velocity.z, current_max_speed * direction.z * input_dir.length(), current_accel*delta) 
		
		# This rotates... when it works.
		#if PlayerVariables.underwater and direction and velocity: # target_velocity = target_velocity.rotated(Vector3.UP, direction.angle_to(target_velocity))
			#target_velocity = Vector3(arget_velocity * direction
		if (not PlayerVariables.underwater) and (not PlayerVariables.fpcam):
			skin.look_at(position + direction) #lerp(position, position + direction, lerp_speed/10)
		elif (not PlayerVariables.fpcam) and input_dir:
			skin.rotation = cpivot_v.rotation - Vector3(-80, 0, 0) # TODO: this looks weird
			
		if PlayerVariables.underwater and (not Input.is_action_pressed("move_up")) and (not Input.is_action_pressed("move_down")):
			target_velocity.y = move_toward(velocity.y, current_max_speed * direction.y * input_dir.length(), current_accel*delta)
	else:
		target_velocity.x = move_toward(velocity.x, 0, current_accel*delta)
		target_velocity.z = move_toward(velocity.z, 0, current_accel*delta)
		
	print(current_accel, current_max_speed)
	
	#target_velocity.x = clamp(velocity.x + (current_accel * delta), - current_max_speed, current_max_speed)* direction.x#* input_dir.length()
	# #target_velocity.z = direction.z * current_max_speed #* input_dir.length()
	#target_velocity.z = clamp(velocity.z + (current_accel * delta), - current_max_speed, current_max_speed)* direction.z #* input_dir.length()
	
		
	# Moving the Character
	velocity = target_velocity # TODO: acceleration instead of speed
	print(velocity)
	move_and_slide()
	
	previous_uw = PlayerVariables.underwater
	# Is she underwater?
	var areacheckers: Array = [parea, tpcamarea, fpcamarea]
	var cameras: Array = [self, tpcam, fpcam]
	var areas: Array = [PlayerVariables.underwater, PlayerVariables.tpcam_uw, PlayerVariables.fpcam_uw]
	for i in 3:
		if cameras[i].global_position.y <= 0:
			areas[i] =  not ("AirArea" in str(areacheckers[i].get_overlapping_areas()))
		else:
			areas[i] =  ("WaterArea" in str(areacheckers[i].get_overlapping_areas()))
	PlayerVariables.tpcam_uw = areas[1]
	PlayerVariables.fpcam_uw = areas[2]
	# Avoids player standing up if gets out of water in place with not enough height
	if (PlayerVariables.underwater and not water_ray_cast.is_colliding()) or (not PlayerVariables.underwater):
		PlayerVariables.underwater = areas[0]

	
	if PlayerVariables.fpcam_uw:
		fpcam.environment = underwater_env
	else:
		fpcam.environment = land_env
	if PlayerVariables.tpcam_uw:
		tpcam.environment = underwater_env
	else:
		tpcam.environment = land_env
	
	# Set transition between water and land # TODO: after acceleration is done, do diving and stuff (in visuals only?)	
	if PlayerVariables.underwater and not previous_uw:
		rotation.x = (-deg_to_rad(90))
		tpcspring.spring_length += 1
		if PlayerVariables.fpcam:
			head.rotation.x = head.rotation.x+deg_to_rad(90)
		else:
			cpivot_v.rotation.x = cpivot_v.rotation.x+deg_to_rad(90)
			cpivot_h.rotation.z = cpivot_h.rotation.y
			cpivot_h.rotation.y = 0
	elif previous_uw and not PlayerVariables.underwater: 
		fpcam.environment = land_env
		tpcam.environment = land_env
		tpcspring.spring_length = 2.24
		rotation.x = 0
		rotation.z = 0
		if PlayerVariables.fpcam:
			head.rotation.x = head.rotation.x - deg_to_rad(90)
		else:
			cpivot_v.rotation.x = cpivot_v.rotation.x - deg_to_rad(90)
			cpivot_h.rotation.y = cpivot_h.rotation.z
			cpivot_h.rotation.z = 0
		if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_forward"):
			target_velocity.y = jump_impulse
	
	# Ocean follows the player in order to look infinite
	ocean.position.x = self.position.x;
	ocean.position.z = self.position.z;

	# testing
	#print('underwater ' + str(PlayerVariables.underwater))
	# print(str(parea.get_overlapping_areas())) # This detects the areas!!
	#print(current_max_speed)
	#print(input_dir)
	#print(input_dir.length())
	

