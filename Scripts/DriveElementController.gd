extends Spatial
class_name DriveElement

# control variables
export var shape : Shape
export(int, LAYERS_3D_PHYSICS) var mask : int = 1
export var castTo : Vector3 = Vector3(0,-1,0)
export var springMaxForce : float = 300.0
export var springForce : float = 180.0
export var stifness : float = 0.85
export var damping : float = 0.05
export var Xtraction : float = 1.0
export var Ztraction : float = 0.15

# public variables
var instantLinearVelocity : Vector3

# private variables
var parentBody : RigidBody
var previousDistance : float = abs(castTo.y)
var previousHit : SphereCastResult = SphereCastResult.new()
var collisionPoint : Vector3 = castTo
var grounded : bool = false

# sphere cast result storage class
class SphereCastResult:
	var hit_distance: float
	var hit_position: Vector3
	var hit_normal: Vector3

# function to do sphere casting
func sphere_cast(origin: Vector3, offset: Vector3):
	var space: PhysicsDirectSpaceState = get_world().direct_space_state as PhysicsDirectSpaceState
	var params: = PhysicsShapeQueryParameters.new()
	params.collision_mask = mask
	params.set_shape(shape)
	params.transform = transform
	params.transform.origin = origin
	# exclude parent body!
	params.exclude = [parentBody]
	
	var castResult = space.cast_motion(params, offset)

	var result: = SphereCastResult.new()
	
	result.hit_distance = castResult[0] * offset.length()
	result.hit_position = origin + offset * castResult[0]
	
	params.transform.origin += offset * castResult[1]
	var collision = space.get_rest_info(params)
	
	result.hit_normal = collision.get("normal", Vector3.ZERO)
	
	return result

# getter for collision point
func get_collision_point() -> Vector3:
	return collisionPoint
	
# getter for collision check
func is_colliding() -> bool:
	return grounded

# function for applying drive force to parent body (if grounded)
func applyDriveForce(force : Vector3) -> void:
	if is_colliding():
		parentBody.add_force(force, get_collision_point() - parentBody.global_transform.origin)

func _ready() -> void:
	# setup references (only need to get once, should be more efficient?)
	parentBody = get_parent()
	
func _physics_process(delta) -> void:
	# perform sphere cast
	var castResult = sphere_cast(global_transform.origin, castTo)
	if GameState.debugMode:
		DrawLine3D.DrawCube(global_transform.origin,0.5,Color(255,0,255))
		DrawLine3D.DrawCube(global_transform.origin + castTo,0.5,Color(255,128,255))
	# [1, 1] means no hit (from docs)
	if castResult.hit_distance != abs(castTo.y):
		# if grounded, handle forces
		grounded = true
		collisionPoint = castResult.hit_position
		if GameState.debugMode:
			DrawLine3D.DrawCube(castResult.hit_position,0.04,Color(0,255,255))
			DrawLine3D.DrawRay(castResult.hit_position,castResult.hit_normal,Color(0,0,0))
		
		# obtain instantaneaous linear velocity
		instantLinearVelocity = (collisionPoint - previousHit.hit_position) / delta
		
		# apply spring force with damping force
		var curDistance = castResult.hit_distance
		var FSpring = stifness * (abs(castTo.y) - curDistance) 
		var FDamp = damping * (previousDistance - curDistance) / delta
		var suspensionForce = clamp((FSpring + FDamp) * springForce,0,springMaxForce)
		var suspensionForceVec= global_transform.basis.y * suspensionForce
		
		# obtain axis velocity
		var ZVelocity = global_transform.basis.xform_inv(instantLinearVelocity).z
		var XVelocity = global_transform.basis.xform_inv(instantLinearVelocity).x
		
		# axis deceleration forces
		var XForce = -global_transform.basis.x * XVelocity * (parentBody.weight * parentBody.gravity_scale)/parentBody.rayElements.size() * Xtraction
		var ZForce = -global_transform.basis.z * ZVelocity * (parentBody.weight * parentBody.gravity_scale)/parentBody.rayElements.size() * Ztraction
		
		# counter sliding by negating off axis suspension impulse
		XForce.x -= suspensionForceVec.x * parentBody.global_transform.basis.y.dot(Vector3.UP)
		ZForce.z -= suspensionForceVec.z * parentBody.global_transform.basis.y.dot(Vector3.UP)
		
		# final impulse force vector to be applied
		var finalForce = suspensionForceVec + XForce + ZForce
		# draw debug lines
		if GameState.debugMode:
			DrawLine3D.DrawRay(get_collision_point(),suspensionForceVec,Color(0,255,0))
			DrawLine3D.DrawRay(get_collision_point(),XForce,Color(255,0,0))
			DrawLine3D.DrawRay(get_collision_point(),ZForce,Color(0,0,255))
			
		# apply forces relative to parent body
		parentBody.add_force(finalForce, get_collision_point() - parentBody.global_transform.origin)
		
		# set the previous values at the very end, after they have been used
		previousDistance = curDistance
		previousHit = castResult
	else:
		# not grounded, set prev values to fully extended suspension
		grounded = false
		previousHit = SphereCastResult.new()
		previousHit.hit_position = global_transform.origin + castTo
		previousHit.hit_distance = abs(castTo.y)
		previousDistance = previousHit.hit_distance
		
