extends RigidBody

# control variables
export(bool) var neutralSteer : bool = true
export(bool) var invertSteerWhenReverse : bool = false
export(float) var enginePower : float = 150
export(Curve) var torqueCurve : Curve
export(float) var maxSpeedKph : float = 65.0
export(float) var maxReverseSpeedKph : float = 20.0
export(float) var regularBrakePercent : float = 0.01
export(float) var steerBrakePercent : float = 0.1
export(float) var trackBrakingSpeed : float = 0.02
export(float) var rollingResistance : float = 0.001
export(float) var autoStopSpeedMS : float = 1.0

var driveElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSteerBrakePower : float = 0.0
var currentSpeed : float = 0.0

var lastSteerValue : float = 0.0
	
func _handle_physics(delta) -> void:
	# get throttle and steering input
	var forwardDrive : float = Input.get_axis("brake", "throttle")
	var steering : float = Input.get_axis("steer_left", "steer_right")
	
	# Invert steering when reversing if enabled
	if forwardDrive < 0 && invertSteerWhenReverse:
		steering *= -1
	
	# calculate speed interpolation
	var speedInterp : float
	# forward
	if forwardDrive > 0:
		speedInterp = range_lerp(abs(currentSpeed), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
	# reverse
	elif forwardDrive < 0:
		speedInterp = range_lerp(abs(currentSpeed), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
	# steering drive
	elif forwardDrive == 0 && steering != 0:
		speedInterp = 0
	
	# get force from torque curve (based on current speed)
	currentDrivePower = torqueCurve.interpolate_baked(speedInterp) * drivePerRay
	
	# reset steering if opposite input used
	if sign(steering) != sign(lastSteerValue):
		currentSteerBrakePower = 0
	# gradually apply steering and decay if no steering applied
	if steering != 0:
		var desiredBrakePower : float = abs(steering) * steerBrakePercent
		currentSteerBrakePower = move_toward(currentSteerBrakePower, desiredBrakePower, trackBrakingSpeed * delta)
	else:
		currentSteerBrakePower = move_toward(currentSteerBrakePower, 0, trackBrakingSpeed * delta)
	# set last steer value
	lastSteerValue = steering
	
	# set drive for each track driveElement
	for driveElement in driveElements:
		var finalForce : Vector3 = Vector3.ZERO
		var finalBrake : float = rollingResistance
		var trackSide : int = sign(driveElement.transform.origin.x)

		# no drive inputs, apply parking brake if sitting still
		if forwardDrive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
			finalBrake = regularBrakePercent
			
		# steering only
		elif forwardDrive == 0 && steering != 0:
			if abs(currentSpeed) < autoStopSpeedMS:
				# handle neutral steering
				if neutralSteer:
					finalForce = global_transform.basis.z * currentDrivePower * steering * trackSide
					finalBrake = rollingResistance
				else:
					# handle clutch brake steering
					if sign(driveElement.transform.origin.x) == sign(steering):
						finalForce = global_transform.basis.z * currentDrivePower * steering * trackSide
					else:
						finalBrake = currentSteerBrakePower * steering * -trackSide
			else:
				finalBrake = currentSteerBrakePower * steering * -trackSide
				
		else:
			# regular driving with steering
			finalForce = global_transform.basis.z * currentDrivePower * clamp(forwardDrive + (steering * trackSide), -1,1)
			# brake correct side of track
			if trackSide == sign(-steering * sign(forwardDrive)):
				finalBrake = currentSteerBrakePower * abs(steering)
			else:
				finalBrake = 0
			# slow down if input opposite drive direction
			if sign(currentSpeed) != sign(forwardDrive):
				finalBrake = regularBrakePercent * abs(forwardDrive)

		# apply brake and force
		driveElement.apply_force(finalForce)
		driveElement.apply_brake(finalBrake)
		

func _ready() -> void:
	# setup arrays of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			driveElements.append(node)
	drivePerRay = enginePower / driveElements.size()
	print("Found %d track elements connected to vehicle. Each driveElement providing %.2f force each." % [driveElements.size(), drivePerRay])
	
func _physics_process(delta) -> void:
	# calculate forward speed
	currentSpeed = global_transform.basis.xform_inv(linear_velocity).z
	_handle_physics(delta)
