extends RigidBody

# control variables
export var enginePower : float = 280.0
export var steeringAngle : float = 20.0
# currently, raycast driver expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower
var frontRightWheel : RayCast
var frontLeftWheel : RayCast
	
func handle4WheelDrive(delta) -> void:
	# 4WD with front wheel steering
	for ray in rayElements:
		var dir = 0
		if Input.is_action_pressed("ui_up"):
			dir += 1
		if Input.is_action_pressed("ui_down"):
			dir -= 1
		# steering, set wheels initially straight
		frontLeftWheel.rotation_degrees.y = 0.0
		frontRightWheel.rotation_degrees.y = 0.0
		# if input provided, steer
		if Input.is_action_pressed("ui_left"):
			frontLeftWheel.rotation_degrees.y = steeringAngle
			frontRightWheel.rotation_degrees.y = steeringAngle
		if Input.is_action_pressed("ui_right"):
			frontLeftWheel.rotation_degrees.y = -steeringAngle
			frontRightWheel.rotation_degrees.y = -steeringAngle
		
		ray.applyDriveForce(dir * global_transform.basis.z * drivePerRay * delta)

func _ready() -> void:
	# setup front right and front left wheels
	frontLeftWheel = get_node("FL_ray")
	frontRightWheel = get_node("FR_ray")
	
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is RayCast:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found ", rayElements.size(), " raycasts connected to wheeled vehicle, setting to provide ", drivePerRay, " power each.") 
	
func _physics_process(delta) -> void:
	handle4WheelDrive(delta)
