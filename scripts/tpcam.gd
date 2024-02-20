extends Node3D
var mouse_sens = 0.4
@onready var pivot_v = $Pivot_v

func _input(event):
#	head = cameras[PlayerVariables.fpcam]
	#print(event)
	# Camera (mouse)
	if event is InputEventMouseMotion and !PlayerVariables.fpcam:
		if not PlayerVariables.underwater: rotate_y(-deg_to_rad(event.relative.x * mouse_sens))
		else: rotate_z(-deg_to_rad(event.relative.x * mouse_sens))
		pivot_v.rotate_x(-deg_to_rad(event.relative.y * mouse_sens))
		
		if not PlayerVariables.underwater:
			pass #pivot_v.rotation.x = clamp(rotation.x, deg_to_rad(-89), deg_to_rad(90))
		else:
			pass #pivot_v.rotation.x = clamp(rotation.x, deg_to_rad(0), deg_to_rad(170))
	# Camera Person set
	if (event is InputEventKey) and (Input.is_action_pressed("cam-chg")):
		PlayerVariables.fpcam = abs(PlayerVariables.fpcam - 1)
		print(PlayerVariables.fpcam)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass
