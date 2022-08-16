extends RigidBody

# control variables
export(float) var enginePower : float = 150.0
export(Curve) var torqueCurve : Curve
export(float) var acceleration : float = 5.0
export(float) var deceleration : float = 10.0
export(float) var maxSpeedKph : float = 100.0
export(float) var maxReverseSpeedKph : float = 20.0
export(float) var maxBrakingCoef : float = 0.05
export(float) var rollingResistance : float = 0.0001

export(float) var steeringAngle : float = 30.0
export(float) var steerSpeed : float = 15.0
export(float) var wheelReturnSpeed : float = 30.0

onready var fl_ray: Spatial = $FL_ray
onready var fr_ray: Spatial = $FR_ray

# currently, DriveElement expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSteerAngle : float = 0.0

var currentSpeed : float = 0.0

func _handle_physics(delta) -> void:
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
				if currentSteerAngle > 0.0:
					currentSteerAngle -= wheelReturnSpeed * delta
				else:
					currentSteerAngle += wheelReturnSpeed * delta
			else:
				currentSteerAngle = 0.0
		
		# limit and apply steering
		currentSteerAngle = clamp(currentSteerAngle, -steeringAngle, steeringAngle)
		fr_ray.rotation_degrees.y = currentSteerAngle
		fl_ray.rotation_degrees.y = currentSteerAngle

		# brake if movement opposite indended direction
		if sign(currentSpeed) != sign(throttle) && !is_zero_approx(currentSpeed) && throttle != 0:
			ray.set_brake(maxBrakingCoef)
		else:
			ray.set_brake(rollingResistance)
		
		# calculate motor forces
		if throttle > 0:
			var speedInterp : float = range_lerp(linear_velocity.length(), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
			currentDrivePower = lerp(currentDrivePower, torqueCurve.interpolate_baked(speedInterp) * drivePerRay * throttle, acceleration * delta)
		elif throttle < 0:
			var speedInterp : float = range_lerp(linear_velocity.length(), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
			currentDrivePower = lerp(currentDrivePower, torqueCurve.interpolate_baked(speedInterp) * drivePerRay * throttle, acceleration * delta)
		else:
			currentDrivePower = lerp(currentDrivePower, 0.0, deceleration * delta)
		
		# apply drive force
		ray.apply_force(global_transform.basis.z * currentDrivePower)

func _ready() -> void:
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is DriveElement:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Found ", rayElements.size(), " raycasts connected to wheeled vehicle, setting to provide ", drivePerRay, " power each.") 
	
func _physics_process(delta) -> void:
	# calculate forward speed
	currentSpeed = global_transform.basis.xform_inv(linear_velocity).z
	_handle_physics(delta)
