extends RigidBody

# control variables
export(bool) var neutralSteer : bool = true
export(float) var enginePower : float = 150
export(Curve) var torqueCurve : Curve
export(float) var acceleration : float = 1.0
export(float) var deceleration : float = 4.0
export(float) var maxSpeedKph : float = 65.0
export(float) var maxReverseSpeedKph : float = 20.0
export(float) var trackBrakeCoef : float = 0.1
export(float) var rollingResistance : float = 0.002

# currently, DriveElement expects this array to exist in the controller script
var rayElements : Array = []
var drivePerRay : float = enginePower

var currentDrivePower : float = 0.0
var currentSpeed : float = 0.0
	
func _handle_physics(delta) -> void:
	# get throttle and steering input
	var throttle : float = Input.get_axis("ui_down", "ui_up")
	var steering : float = Input.get_axis("ui_left", "ui_right")
	
	# calculate motor forces
	# forward
	if throttle > 0:
		var speedInterp : float = range_lerp(linear_velocity.length(), 0.0, maxSpeedKph / 3.6, 0.0, 1.0)
		currentDrivePower = lerp(currentDrivePower, torqueCurve.interpolate_baked(speedInterp) * drivePerRay, acceleration * delta)
	# reverse
	elif throttle < 0:
		var speedInterp : float = range_lerp(linear_velocity.length(), 0.0, maxReverseSpeedKph / 3.6, 0.0, 1.0)
		currentDrivePower = lerp(currentDrivePower, torqueCurve.interpolate_baked(speedInterp) * drivePerRay, acceleration * delta)
	# neutral steering (will use full power)
	elif steering != 0 && throttle == 0:
		currentDrivePower = lerp(currentDrivePower, drivePerRay, acceleration * delta)
	# deceleration
	else:
		currentDrivePower = lerp(currentDrivePower, 0.0, deceleration * delta)
	
	# set drive for each track element
	for ray in rayElements:
		# auto brake
		if throttle == 0 && steering == 0:
			ray.set_brake(trackBrakeCoef)
		else:
			ray.set_brake(rollingResistance)
		
		# apply throttle
		if throttle != 0:
			ray.apply_force(global_transform.basis.z * currentDrivePower * throttle)
		
		# apply drive or braking depending on setup
		if steering != 0:
			# currently driving, brake only
			if throttle != 0:
				ray.set_brake(trackBrakeCoef * steering * -sign(ray.transform.origin.x))
			else:
				# handle neutral steering
				if neutralSteer:
					ray.apply_force(global_transform.basis.z * currentDrivePower * steering * sign(ray.transform.origin.x))
				# handle clutch brake steering
				else:
					if sign(ray.transform.origin.x) == sign(steering):
						ray.apply_force(global_transform.basis.z * currentDrivePower * steering * sign(ray.transform.origin.x))
					else:
						ray.set_brake(trackBrakeCoef * steering * -sign(ray.transform.origin.x))
			
		

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
