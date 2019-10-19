extends RayCast
# control variables
export var springForce : float = 60.0
export var damping : float = 10.0
export var Xtraction : float = 25.0
export var Ztraction : float = 4.2
# refernce to parent body so we can apply forces
var parentBody : RigidBody
var parentVelocity : Vector3
# variable to hold information for damping
var previousDistance : float = abs(cast_to.y)

func _ready() -> void:
	parentBody = get_parent()
	
func _physics_process(delta) -> void:
	if is_colliding():
		parentVelocity = parentBody.get_linear_velocity()
		#obtain axis velocity
		var ZVelocity = parentBody.global_transform.basis.xform_inv(parentVelocity).z
		var XVelocity = parentBody.global_transform.basis.xform_inv(parentVelocity).x
		# axis deceleration forces
		var sideWaysForce = parentBody.global_transform.basis.x * XVelocity * Xtraction * delta
		var decelerationForce = parentBody.global_transform.basis.z * ZVelocity * Ztraction * delta
		# apply spring force with damping
		var curDistance = (global_transform.origin - get_collision_point()).length()
		var suspensionForce = springForce * (abs(cast_to.y) - curDistance) + damping * (previousDistance - curDistance)/delta
		var impulseVector = parentBody.global_transform.basis.y * suspensionForce * delta
		previousDistance = curDistance
		# note that the point has to be xform()'ed to be at the correct location. Xform makes the pos global
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),impulseVector)
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),-sideWaysForce)
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),-decelerationForce)