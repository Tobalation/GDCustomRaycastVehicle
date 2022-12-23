extends RigidBody

# control variables
export(float) var enginePower : float = 150.0
export(Curve) var torqueCurve : Curve
export(float) var maxSpeedKph : float = 100.0
export(float) var maxReverseSpeedKph : float = 20.0
export(float) var maxBrakingCoef : float = 0.05
export(float) var rollingResistance : float = 0.0001

export(float) var steeringAngle : float = 30.0
export(float) var steerSpeed : float = 15.0
export(float) var maxSteerLimitRatio : float = 0.95
export(float) var steerReturnSpeed : float = 30.0
export(float) var autoStopSpeedMS : float = 1.0

onready var fl_ray: Spatial = $FL_ray
onready var fr_ray: Spatial = $FR_ray

var rayElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSteerAngle : float = 0.0
var maxSteerAngle : float = steeringAngle

var currentSpeed : float = 0.0

func _handle_physics(delta) -> void:
	# 4WD with front wheel steering
	for ray in rayElements:
		# get throttle axis
		var forwardDrive : float = Input.get_axis("brake", "throttle")
		# get steering axis
		var steering : float = Input.get_axis("steer_left", "steer_right")
		
		# steer wheels gradualy based on steering input
		if steering != 0:
			var desiredAngle : float = steering * steeringAngle
			currentSteerAngle = move_toward(currentSteerAngle, -desiredAngle, steerSpeed * delta)
		else:
			# return wheels to center with wheel return speed
			if !is_equal_approx(currentSteerAngle, 0.0):
				if currentSteerAngle > 0.0:
					currentSteerAngle -= steerReturnSpeed * delta
				else:
					currentSteerAngle += steerReturnSpeed * delta
			else:
				currentSteerAngle = 0.0
		
		# limit steering based on speed and apply steering
		var maxSteerRatio : float = range_lerp(currentSpeed * 3.6, 0, maxSpeedKph, 0, maxSteerLimitRatio)
		maxSteerAngle = (1 - maxSteerRatio) * steeringAngle
		currentSteerAngle = clamp(currentSteerAngle, -maxSteerAngle, maxSteerAngle)
		fr_ray.rotation_degrees.y = currentSteerAngle
		fl_ray.rotation_degrees.y = currentSteerAngle

		# brake if movement opposite indended direction
		if sign(currentSpeed) != sign(forwardDrive) && !is_zero_approx(currentSpeed) && forwardDrive != 0:
			ray.apply_brake(maxBrakingCoef * abs(forwardDrive))
		# apply gradual slowdown if no throttle applied
		elif forwardDrive == 0:
			ray.apply_brake(rollingResistance)
			
		# no drive inputs, apply parking brake if sitting still
		if forwardDrive == 0 && steering == 0 && abs(currentSpeed) < autoStopSpeedMS:
			ray.apply_brake(maxBrakingCoef)
		
		# calculate motor forces
		var speedInterp : float
		if forwardDrive > 0:
			speedInterp = range_lerp(linear_velocity.length(), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
		elif forwardDrive < 0:
			speedInterp = range_lerp(linear_velocity.length(), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
		currentDrivePower = torqueCurve.interpolate_baked(speedInterp) * drivePerRay * forwardDrive
		
		# apply drive force
		ray.apply_force(global_transform.basis.z * currentDrivePower)

func _ready() -> void:
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found %d drive elements connected to wheeled vehicle, setting to provide %.2f force each." % [rayElements.size(), drivePerRay]) 
	
func _physics_process(delta) -> void:
	# calculate forward speed
	currentSpeed = global_transform.basis.xform_inv(linear_velocity).z
	_handle_physics(delta)
