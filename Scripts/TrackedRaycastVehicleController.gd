extends RigidBody

# control variables
export var enginePower : float = 280.0
export var engineSpeedScaleFac : float = 60.0
# currently, DriveElement expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower
	
func handleTankDrive(delta) -> void:
	# skid steering (with neutral steer) setup
	for ray in rayElements:
		# get throttle and steering input
		var throttle : float = Input.get_axis("ui_down", "ui_up")
		var steering : float = Input.get_axis("ui_left", "ui_right")
		# apply drive to tracks based on what side they are on
		var trackDrive : float = throttle + (steering * sign(ray.transform.origin.x))
		
		# apply drive forces
		ray.applyDriveForce(trackDrive * global_transform.basis.z * drivePerRay)

func _ready() -> void:
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found ", rayElements.size(), " DriveElements connected to tracked vehicle, setting to provide ", drivePerRay, " power each.") 
	
func _physics_process(delta) -> void:
	handleTankDrive(delta)
