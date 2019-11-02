extends RigidBody
# control variables
export var enginePower : float = 300.0
export var turningPower : float = 450.0
export var applyOnPlane : bool = false
# 2D plane for projecting movment forces
var movementPlane : Plane = Plane.PLANE_XZ
var driveForcePoint = Vector3(0,-0.25,1)
var rayElements = []

func _ready() -> void:
	for node in get_children():
		if node is RayCast:
			rayElements.append(node)
	print("Added ", rayElements.size(), " raycasts to vehicle") 
	
func _physics_process(delta) -> void:
	# apply movtive forces
	if Input.is_action_pressed("ui_up"):
		if applyOnPlane:
			apply_impulse(global_transform.basis.xform(driveForcePoint),movementPlane.project(global_transform.basis.xform(Vector3(0,0,enginePower * delta))))
		else:
			apply_impulse(global_transform.basis.xform(driveForcePoint),global_transform.basis.xform(Vector3(0,0,enginePower * delta)))
	if Input.is_action_pressed("ui_down"):
		if applyOnPlane:
			apply_impulse(global_transform.basis.xform(driveForcePoint),movementPlane.project(global_transform.basis.xform(Vector3(0,0,-enginePower * delta))))
		else:
			apply_impulse(global_transform.basis.xform(driveForcePoint),global_transform.basis.xform(Vector3(0,0,-enginePower * delta)))
	if Input.is_action_pressed("ui_left"):
		apply_torque_impulse(global_transform.basis.xform(Vector3(0,turningPower * delta, 0)))
	if Input.is_action_pressed("ui_right"):
		apply_torque_impulse(global_transform.basis.xform(Vector3(0,-turningPower * delta, 0)))
	
	if GameState.debugMode:
		DrawLine3D.DrawRay(global_transform.origin,get_linear_velocity(),Color(255,0,255))
		
	# hand brake
	if Input.is_action_pressed("ui_accept"):
		apply_impulse(global_transform.basis.xform(driveForcePoint),-get_linear_velocity())