extends Area3D
signal aair

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	if "Player" in str(get_overlapping_bodies()):
		AirSignal.air_signal.emit()
