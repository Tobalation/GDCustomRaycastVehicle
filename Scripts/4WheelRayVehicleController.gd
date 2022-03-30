extends RigidBody

# control variables
export(float) var enginePower : float = 280.0
export(float) var steeringAngle : float = 30.0
export(float) var steerSpeed : float = 10.0
export(float) var wheelReturnSpeed : float = 30.0
export(float) var acceleration : float = 0.25

# currently, DriveElement expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower
var frontRightWheel : Spatial
var frontLeftWheel : Spatial

var currentDrivePower : float = 0.0
var currentSteerAngle : float = 0.0

func handle4WheelDrive(delta) -> void:
	# 4WD with front wheel steering
	for ray in rayElements:
		# get throttle axis
		var throttle : float = Input.get_axis("ui_down", "ui_up")
		# get steering axis
		var steering : float = Input.get_axis("ui_left", "ui_right")
		
		# steer wheels gradualy based on steering input
		if steering != 0:
			currentSteerAngle -= steering * steerSpeed * delta
		else:
			# return wheels to center
			if !is_equal_approx(currentSteerAngle, 0.0):
				if currentSteerAngle > 0:
					currentSteerAngle -= wheelReturnSpeed * delta
				else:
					currentSteerAngle += wheelReturnSpeed * delta
		currentSteerAngle = clamp(currentSteerAngle, -steeringAngle, steeringAngle)
		frontRightWheel.rotation_degrees.y = currentSteerAngle
		frontLeftWheel.rotation_degrees.y = currentSteerAngle
		
		# apply drive force
		if throttle != 0:
			currentDrivePower = lerp(currentDrivePower, throttle * drivePerRay, delta * acceleration)
		else:
			currentDrivePower = lerp(currentDrivePower, 0.0 , delta * acceleration * 1.5)
		ray.applyDriveForce(global_transform.basis.z * currentDrivePower)

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
