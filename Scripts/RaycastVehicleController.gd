extends RigidBody;
# control variables
export var enginePower : float = 250.0;
export var decelerationPower : float = 10.0;
export var turningPower : float = 50.0;
export var XTraction : float = 20.0;
# 2D plane for projecting movment forces
var movementPlane : Plane = Plane(Vector3.UP,0.0);
	
func _physics_process(delta) -> void:
	# obtain axis velocity
	var ZVelocity = get_linear_velocity().dot(global_transform.basis.z);
	var XVelocity = get_linear_velocity().dot(global_transform.basis.x);
	
	# axis deceleration forces
	var sideWaysForce = Vector3(XVelocity * XTraction * delta,0,0);
	var decelerationForce = Vector3(0,0,ZVelocity * decelerationPower * delta);
	apply_impulse(Vector3(),global_transform.basis.xform(-sideWaysForce));
	apply_impulse(Vector3(),global_transform.basis.xform(-decelerationForce));
	
	# apply movtive forces
	if Input.is_action_pressed("ui_up"):
		apply_impulse(Vector3(),movementPlane.project(global_transform.basis.xform(Vector3(0,0,enginePower * delta))));
	if Input.is_action_pressed("ui_down"):
		apply_impulse(Vector3(),movementPlane.project(global_transform.basis.xform(Vector3(0,0,-enginePower * delta))));
	if Input.is_action_pressed("ui_left"):
		apply_torque_impulse(Vector3(0,turningPower * delta, 0));
	if Input.is_action_pressed("ui_right"):
		apply_torque_impulse(Vector3(0,-turningPower * delta, 0));