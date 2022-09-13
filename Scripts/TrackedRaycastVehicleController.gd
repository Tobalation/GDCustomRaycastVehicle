extends RigidBody

# control variables
export(bool) var neutralSteer : bool = true
export(float) var enginePower : float = 150
export(Curve) var torqueCurve : Curve
export(float) var maxSpeedKph : float = 65.0
export(float) var maxReverseSpeedKph : float = 20.0
export(float) var trackBrakeCoef : float = 0.8
export(float) var trackBrakingSpeed : float = 0.4
export(float) var rollingResistance : float = 0.02
export(float) var autoStopSpeedMS : float = 1.0

# currently, DriveElement expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSteerBrakePower : float = 0.0
var currentParkingBrakePower : float = 0.0
var currentSpeed : float = 0.0

var lastSteerValue : float = 0.0
	
func _handle_physics(delta) -> void:
	# get throttle and steering input
	var throttle : float = Input.get_axis("ui_down", "ui_up")
	var steering : float = Input.get_axis("ui_left", "ui_right")
	
	# Invert steering when reversing
#	if throttle < 0:
#		steering *= -1
	
	# calculate speed interpolation
	var speedInterp : float
	# forward
	if throttle > 0 || steering != 0:
		speedInterp = range_lerp(linear_velocity.length(), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
	# reverse
	elif throttle < 0:
		speedInterp = range_lerp(linear_velocity.length(), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
	
	# get force from torque curve (based on current speed)
	currentDrivePower = torqueCurve.interpolate_baked(speedInterp) * drivePerRay
	
	# calculate track braking powers
	
	# reset steering if opposite input used
	if sign(steering) != sign(lastSteerValue):
		currentSteerBrakePower = 0
	# gradually apply steering and decay if no steering applied
	if steering != 0:
		currentSteerBrakePower = lerp(currentSteerBrakePower, trackBrakeCoef, trackBrakingSpeed * delta)
	else:
		currentSteerBrakePower = 0
	# set last steer value
	lastSteerValue = steering
	
	# set drive for each track element
	for ray in rayElements:
		var finalForce : Vector3 = Vector3.ZERO
		var finalBrake : float = rollingResistance
		var trackSide : int = sign(ray.transform.origin.x)
		
		# no drive inputs, apply parking brake if sitting still
		if throttle == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
			currentParkingBrakePower = lerp(currentParkingBrakePower, trackBrakeCoef, trackBrakingSpeed/2 * delta)
			finalBrake = currentParkingBrakePower
		
		# throttle only, no steering
		elif throttle != 0 && steering == 0:
			# handle auto braking and drive from throttle
			if sign(throttle) != sign(currentSpeed):
				currentParkingBrakePower = lerp(currentParkingBrakePower, trackBrakeCoef, trackBrakingSpeed * delta)
				finalBrake = currentParkingBrakePower
				if abs(currentSpeed) < autoStopSpeedMS:
					finalForce = global_transform.basis.z * currentDrivePower * throttle
			else:
				currentParkingBrakePower = lerp(currentParkingBrakePower, 0.0, trackBrakingSpeed * delta)
				finalForce = global_transform.basis.z * currentDrivePower * throttle
				finalBrake = 0
			
		# throttle and steering
		elif throttle != 0 && steering != 0:
			# apply drive
			finalForce = global_transform.basis.z * currentDrivePower * (throttle + steering * trackSide)
			# apply braking
			finalBrake = currentSteerBrakePower * steering * -trackSide
			
		# steering only
		elif throttle == 0 && steering != 0:
			if abs(currentSpeed) < autoStopSpeedMS:
				# handle neutral steering
				if neutralSteer:
					finalForce = global_transform.basis.z * currentDrivePower * steering * trackSide
				else:
					# handle clutch brake steering
					if sign(ray.transform.origin.x) == sign(steering):
						finalForce = global_transform.basis.z * currentDrivePower * steering * trackSide
					else:
						finalBrake = currentSteerBrakePower * steering * -trackSide
			else:
				finalBrake = currentSteerBrakePower * steering * -trackSide
		
		# apply brake and force
		ray.apply_force(finalForce)
		ray.apply_brake(finalBrake)
		

func _ready() -> void:
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found ", rayElements.size(), " DriveElements connected to tracked vehicle, setting to provide ", drivePerRay, " power each.") 
	
func _physics_process(delta) -> void:
	# calculate forward speed
	currentSpeed = global_transform.basis.xform_inv(linear_velocity).z
	_handle_physics(delta)
