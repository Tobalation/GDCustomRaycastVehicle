extends RayCast
# control variables
export var springForce : float = 80.0
export var stifness : float = 0.8
export var damping : float = 0.08
export var Xtraction : float = 20.0
export var Ztraction : float = 2.0
# private variables
var parentBody : RigidBody
var parentVelocity : Vector3
var previousDistance : float = abs(cast_to.y)
var previousHit : Vector3 = Vector3()

# function for applying drive force to parent body
func applyDriveForce(force : Vector3) -> void:
	parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),force)

func _ready() -> void:
	parentBody = get_parent()
	add_exception(parentBody)
	
func _physics_process(delta) -> void:
	if is_colliding():
		# obtain instantaneaous velocity
		var curHit = get_collision_point()
		var velocity = (curHit - previousHit) / delta
		# obtain axis velocity
		var ZVelocity = global_transform.basis.xform_inv(velocity).z
		var XVelocity = global_transform.basis.xform_inv(velocity).x
		# axis deceleration forces
		var XForce = -global_transform.basis.x * XVelocity * Xtraction * delta
		var ZForce = -global_transform.basis.z * ZVelocity * Ztraction * delta
		# apply spring force with damping
		var curDistance = (global_transform.origin - get_collision_point()).length()
		var suspensionForce = (stifness * (abs(cast_to.y) - curDistance) + damping * (previousDistance - curDistance)/delta) * springForce
		if suspensionForce < 0.0 : suspensionForce = 0.0
		var suspensionImpulse = global_transform.basis.y * suspensionForce * delta
		
		var finalForce = suspensionImpulse + XForce + ZForce
		
		# negate suspension forces to stop sliding
		# ref: https://github.com/shadowmage45/KSPWheel/blob/master/VSProject/KSPWheel/Component/KSPWheelCollider.cs
		var gravNormDot = get_collision_normal().dot(Vector3.DOWN)
		var uphillVec = (get_collision_normal().cross(Vector3.DOWN)).cross(get_collision_normal())
		var slopeLatDot = uphillVec.dot(global_transform.basis.x)
		var antiSlideForce = global_transform.basis.x * finalForce.y * gravNormDot * slopeLatDot
		finalForce += antiSlideForce
		
		if GameState.debugMode:
			DrawLine3D.DrawRay(get_collision_point(),suspensionImpulse,Color(0,255,0))
			DrawLine3D.DrawRay(get_collision_point(),XForce,Color(255,0,0))
			DrawLine3D.DrawRay(get_collision_point(),ZForce,Color(0,0,255))
			
			DrawLine3D.DrawRay(get_collision_point(),uphillVec,Color(0,0,0))
			DrawLine3D.DrawRay(get_collision_point(),antiSlideForce,Color(255,255,255))
		
		# note that the point has to be xform()'ed to be at the correct location. Xform makes the pos global
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),finalForce)
		previousDistance = curDistance
		previousHit = curHit
	else:
		previousDistance = -cast_to.y
		previousHit = global_transform.origin + cast_to