extends RigidBody

# control variables
export var enginePower : float = 300.0
var rayElements = []
var drivePerRay = enginePower

func handleTankDrive(delta) -> void:
	# skid steering (with neutral steer) setup
	for ray in rayElements:
		if Input.is_action_pressed("ui_up"):
			ray.applyDriveForce(global_transform.basis.z * drivePerRay * delta)
		if Input.is_action_pressed("ui_down"):
			ray.applyDriveForce(global_transform.basis.z * -drivePerRay * delta)
		if Input.is_action_pressed("ui_left"):
			if ray.transform.origin.x > 0: # ray is on the left side
				ray.applyDriveForce(global_transform.basis.z * -drivePerRay * delta)
			else:
				ray.applyDriveForce(global_transform.basis.z * drivePerRay * delta)
		if Input.is_action_pressed("ui_right"):
			if ray.transform.origin.x > 0: # ray is on the left side
				ray.applyDriveForce(global_transform.basis.z * drivePerRay * delta)
			else:
				ray.applyDriveForce(global_transform.basis.z * -drivePerRay * delta)


func _ready() -> void:
	# setup array of drive elements and setup drive power
	for node in get_children():
		if node is RayCast:
			rayElements.append(node)
	drivePerRay = enginePower / rayElements.size()
	print("Added ", rayElements.size(), " raycasts to vehicle, providing ", drivePerRay, " power each.") 
	
	
func _physics_process(delta) -> void:
	handleTankDrive(delta)