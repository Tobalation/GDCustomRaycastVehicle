extends RigidBody

# control mode enumerator
enum DriveMode {
	DOUBLE_DIFF,
	BRAKED_DIFF,
	DIRECT_FORCES,
}

# control variables
export(DriveMode) var driveTrainMode = DriveMode.DOUBLE_DIFF
export(bool) var invertSteerWhenReverse : bool = false

export(float) var enginePower : float = 150
export(Curve) var torqueCurve : Curve

export(float) var maxSpeedKph : float = 65.0
export(float) var maxReverseSpeedKph : float = 20.0

export(float) var trackBrakePercent : float = 0.1
export(float) var trackBrakingSpeed : float = 0.1
export(float) var rollingResistance : float = 0.02

export(float) var autoStopSpeedMS : float = 1.0

var leftDriveElements : Array = []
var rightDriveElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSteerBrakePower : float = 0.0
var currentSpeed : float = 0.0

var lastSteerValue : float = 0.0
	
func _handle_physics(delta) -> void:
	# get throttle and steering input
	var forwardDrive : float = Input.get_axis("reverse", "forward")
	var steering : float = Input.get_axis("steer_left", "steer_right")
	
	# Invert steering when reversing if enabled
	if forwardDrive < 0 && invertSteerWhenReverse:
		steering *= -1
	
	# calculate speed interpolation
	var speedInterp : float
	# forward, use forward max speed
	if forwardDrive > 0:
		speedInterp = range_lerp(abs(currentSpeed), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
	# reverse, use reverse max speed
	elif forwardDrive < 0:
		speedInterp = range_lerp(abs(currentSpeed), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
	# steering drive (always at start of curve)
	elif forwardDrive == 0 && steering != 0:
		speedInterp = 0
	
	# get force from torque curve (based on current speed)
	currentDrivePower = torqueCurve.interpolate_baked(speedInterp) * drivePerRay
	
	# handle drive and braking for tracks depending on mode
	if driveTrainMode == DriveMode.DOUBLE_DIFF:
		# double differential setup (steer with control of drive force)
		var leftForce : Vector3 = Vector3.ZERO
		var rightForce : Vector3 = Vector3.ZERO
		var braking : float = rollingResistance
		
		# calculate drive forces
		var LDriveFac : float = forwardDrive + steering
		var RDriveFac : float = forwardDrive + steering * -1
		leftForce = global_transform.basis.z * currentDrivePower * LDriveFac
		rightForce = global_transform.basis.z * currentDrivePower * RDriveFac
		
		# no brakes during normal driving
		if LDriveFac != 0 || RDriveFac != 0:
			braking = 0
		
		# slow down if input opposite drive direction
		if sign(currentSpeed) != sign(forwardDrive):
			braking = trackBrakePercent * abs(forwardDrive)
		
		# apply parking brake if sitting still
		if forwardDrive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
			braking = trackBrakePercent
		
		# finally apply all forces and braking
		for element in leftDriveElements:
			element.apply_force(leftForce)
			element.apply_brake(braking)
			
		for element in rightDriveElements:
			element.apply_force(rightForce)
			element.apply_brake(braking)
		
	elif driveTrainMode == DriveMode.BRAKED_DIFF:
		# braked differential setup (steer with braking)
		var driveForce : Vector3 = Vector3.ZERO
		var leftBraking : float = rollingResistance
		var rightBraking : float = rollingResistance
		
		# calculate drive force
		driveForce = global_transform.basis.z * currentDrivePower * forwardDrive
		
		# reset steering if opposite input used
		if sign(steering) != sign(lastSteerValue):
			currentSteerBrakePower = 0
		# gradually increase steering brake and decay if no steering applied
		if steering != 0:
			var desiredBrakePower : float = abs(steering) * trackBrakePercent
			currentSteerBrakePower = move_toward(currentSteerBrakePower, desiredBrakePower, trackBrakingSpeed * delta)
		else:
			currentSteerBrakePower = move_toward(currentSteerBrakePower, 0, trackBrakingSpeed * delta)
		# set last steer value
		lastSteerValue = steering
		
		# calculate steering brake
		if steering < 0:
			leftBraking = currentSteerBrakePower * abs(steering)
			rightBraking = 0
		else:
			leftBraking = 0
			rightBraking = currentSteerBrakePower * abs(steering)
		
		# slow down if input opposite drive direction
		if sign(currentSpeed) != sign(forwardDrive):
			leftBraking = trackBrakePercent * abs(forwardDrive)
			rightBraking = trackBrakePercent * abs(forwardDrive)
		
		# apply parking brake if sitting still
		if forwardDrive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
			leftBraking = trackBrakePercent
			rightBraking = trackBrakePercent
		
		# finally apply all forces and braking
		for element in leftDriveElements:
			element.apply_force(driveForce)
			element.apply_brake(leftBraking)
			
		for element in rightDriveElements:
			element.apply_force(driveForce)
			element.apply_brake(rightBraking)
		
	elif driveTrainMode == DriveMode.DIRECT_FORCES:
		# Drive and turn using direct forces on vehicle body
		# recalculate engine power
		if sign(currentSpeed) != sign(forwardDrive):
			speedInterp = 0
		currentDrivePower = torqueCurve.interpolate_baked(speedInterp) * enginePower/2
		
		# calculate track forces
		var leftDriveForce : Vector3 = global_transform.basis.z * currentDrivePower * (forwardDrive + steering)
		var rightDriveForce : Vector3 = global_transform.basis.z * currentDrivePower * (forwardDrive + steering * -1)
		
		# check grounded status
		var leftTrackGrounded : bool = false
		var rightTrackGrounded : bool = false
		for element in leftDriveElements:
			if element.grounded:
				leftTrackGrounded = true
		for element in rightDriveElements:
			if element.grounded:
				rightTrackGrounded = true
		
		# apply track forces
		if leftTrackGrounded:
			add_force(leftDriveForce, to_global(Vector3(1.5, -0.2, 0)) - global_transform.origin)
		if rightTrackGrounded:
			add_force(rightDriveForce, to_global(Vector3(-1.5, -0.2, 0)) - global_transform.origin)

func _ready() -> void:
	# setup arrays of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			if sign(node.transform.origin.x) > 0:
				leftDriveElements.append(node)
			else:
				rightDriveElements.append(node)
	drivePerRay = enginePower / (leftDriveElements.size()+rightDriveElements.size())
	print("Found %d track elements connected to vehicle. Each driveElement providing %.2f force each." % [leftDriveElements.size()+rightDriveElements.size(), drivePerRay])
	
func _physics_process(delta) -> void:
	# calculate forward speed
	currentSpeed = global_transform.basis.xform_inv(linear_velocity).z
	_handle_physics(delta)
