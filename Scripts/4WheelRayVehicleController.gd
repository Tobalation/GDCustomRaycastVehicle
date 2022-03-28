extends RigidBody

# control variables
export(float) var enginePower : float = 280.0
export(float) var steeringAngle : float = 20.0
export(float) var steerSpeed : float = 1.0

# currently, raycast driver expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower
var frontRightWheel : Spatial
var frontLeftWheel : Spatial

var currentSteerAngle : float = 0.0

func handle4WheelDrive(delta) -> void:
	# 4WD with front wheel steering
	for ray in rayElements:
		var dir = 0
		if Input.is_action_pressed("ui_up"):
			dir += 1
		if Input.is_action_pressed("ui_down"):
			dir -= 1
		
		# steering, set wheels initially straight
		var steerAngle : float = 0.0

		# if input provided, steer
		if Input.is_action_pressed("ui_left"):
			steerAngle = steeringAngle
		if Input.is_action_pressed("ui_right"):
			steerAngle = -steeringAngle
		
		# lerp steering angle
		currentSteerAngle = lerp(currentSteerAngle, steerAngle, delta * steerSpeed)
			
		frontRightWheel.rotation_degrees.y = currentSteerAngle
		frontLeftWheel.rotation_degrees.y = currentSteerAngle
		
		ray.applyDriveForce(dir * global_transform.basis.z * drivePerRay * delta)

func _ready() -> void:
	# setup front right and front left wheels
	frontLeftWheel = get_node("FL_ray")
	frontRightWheel = get_node("FR_ray")
	
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found ", rayElements.size(), " raycasts connected to wheeled vehicle, setting to provide ", drivePerRay, " power each.") 
	
func _physics_process(delta) -> void:
	handle4WheelDrive(delta)
