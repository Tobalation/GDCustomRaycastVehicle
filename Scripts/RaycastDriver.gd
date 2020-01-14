extends RayCast

# control variables
export var maxForce : float = 300.0
export var springForce : float = 180.0
export var stifness : float = 0.85
export var damping : float = 0.05
export var Xtraction : float = 1.0
export var Ztraction : float = 0.15

# public variables
var instantLinearVelocity : Vector3

# private variables
var parentBody : RigidBody
var previousDistance : float = abs(cast_to.y)
var previousHit : Vector3 = Vector3()

# function for applying drive force to parent body (if grounded)
func applyDriveForce(force : Vector3) -> void:
	if is_colliding():
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),force)

func _ready() -> void:
	# setup references (only need to get once, should be more efficient?)
	parentBody = get_parent()
	add_exception(parentBody)
	
func _physics_process(delta) -> void:
	# if grounded, handle forces
	if is_colliding():
		# obtain instantaneaous linear velocity
		var curHit = get_collision_point()
		instantLinearVelocity = (curHit - previousHit) / delta
		
		# apply spring force with damping force
		var curDistance = (global_transform.origin - get_collision_point()).length()
		var FSpring = stifness * (abs(cast_to.y) - curDistance) 
		var FDamp = damping * (previousDistance - curDistance) / delta
		var suspensionForce = clamp((FSpring + FDamp) * springForce,0,maxForce)
		var suspensionImpulse = global_transform.basis.y * suspensionForce * delta
		
		# obtain axis velocity
		var ZVelocity = global_transform.basis.xform_inv(instantLinearVelocity).z
		var XVelocity = global_transform.basis.xform_inv(instantLinearVelocity).x
		
		# axis deceleration forces
		var XForce = -global_transform.basis.x * XVelocity * (parentBody.weight * parentBody.gravity_scale)/parentBody.rayElements.size() * Xtraction * delta
		var ZForce = -global_transform.basis.z * ZVelocity * (parentBody.weight * parentBody.gravity_scale)/parentBody.rayElements.size() * Ztraction * delta
		
		# counter sliding by negating off axis suspension impulse
		XForce.x -= suspensionImpulse.x * parentBody.global_transform.basis.y.dot(Vector3.UP)
		ZForce.z -= suspensionImpulse.z * parentBody.global_transform.basis.y.dot(Vector3.UP)
		
		# final impulse force vector to be applied
		var finalForce = suspensionImpulse + XForce + ZForce
		# draw debug lines using the awesome DrawLine3D library
		if GameState.debugMode:
			DrawLine3D.DrawRay(get_collision_point(),suspensionImpulse,Color(0,255,0))
			DrawLine3D.DrawRay(get_collision_point(),XForce,Color(255,0,0))
			DrawLine3D.DrawRay(get_collision_point(),ZForce,Color(0,0,255))
			
		# note that the point has to be xform()'ed to be at the correct location. Xform makes the pos global
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),finalForce)
		previousDistance = curDistance
		previousHit = curHit
	else:
		# not grounded, set prev values to fully extended suspension
		previousDistance = -cast_to.y
		previousHit = to_global(cast_to)
