extends Node3D
var mouse_sens = 0.4
var joycam_sens = 5
@onready var pivot_v = $Pivot_v
var cam_dir = Vector2.ZERO

func _input(event):
	# 3rd person Camera (mouse)
	if event is InputEventMouseMotion and !PlayerVariables.fpcam:
		if not PlayerVariables.underwater: rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		else: rotate_z(-deg_to_rad(event.relative.x * mouse_sens))
		pivot_v.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
		
		if not PlayerVariables.underwater:
			pivot_v.rotation.x = clamp(pivot_v.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			pivot_v.rotation.x = clamp(pivot_v.rotation.x, deg_to_rad(20), deg_to_rad(175)) # looping for some reason
			
	# Camera Person set
	if (event is InputEventKey) and (Input.is_action_pressed("cam-chg")):
		PlayerVariables.fpcam = abs(PlayerVariables.fpcam - 1)
		print(PlayerVariables.fpcam)
		
func _process(delta):		
	# 3rd person Camera (joystick)
	cam_dir = Input.get_vector("cam-l", "cam-r", "cam-u", "cam-d")
	if (cam_dir.length() > 0) and not PlayerVariables.fpcam:
		if not PlayerVariables.underwater: rotate_y(-deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
		else: rotate_z(deg_to_rad(cam_dir.x * mouse_sens*joycam_sens))
		pivot_v.rotate_x(deg_to_rad(cam_dir.y * mouse_sens*joycam_sens))
		
		if not PlayerVariables.underwater:
			pivot_v.rotation.x = clamp(pivot_v.rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			pivot_v.rotation.x = clamp(pivot_v.rotation.x, deg_to_rad(20), deg_to_rad(175))
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass
