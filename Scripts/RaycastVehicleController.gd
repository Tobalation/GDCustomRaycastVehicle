extends RigidBody
# control variables
export var enginePower : float = 250.0
export var turningPower : float = 50.0
export var applyOnPlane : bool = false
# 2D plane for projecting movment forces
var movementPlane : Plane = Plane.PLANE_XZ
	
func _physics_process(delta) -> void:
	# apply movtive forces
	if Input.is_action_pressed("ui_up"):
		if applyOnPlane:
			apply_impulse(global_transform.basis.xform(Vector3(0,-0.1,1)),movementPlane.project(global_transform.basis.xform(Vector3(0,0,enginePower * delta))))
		else:
			apply_impulse(global_transform.basis.xform(Vector3(0,-0.1,1)),global_transform.basis.xform(Vector3(0,0,enginePower * delta)))
	if Input.is_action_pressed("ui_down"):
		if applyOnPlane:
			apply_impulse(global_transform.basis.xform(Vector3(0,-0.1,-1)),movementPlane.project(global_transform.basis.xform(Vector3(0,0,-enginePower * delta))))
		else:
			apply_impulse(global_transform.basis.xform(Vector3(0,-0.1,-1)),global_transform.basis.xform(Vector3(0,0,-enginePower * delta)))
	if Input.is_action_pressed("ui_left"):
		apply_torque_impulse(Vector3(0,turningPower * delta, 0))
	if Input.is_action_pressed("ui_right"):
		apply_torque_impulse(Vector3(0,-turningPower * delta, 0))