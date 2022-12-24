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
export var staticSlideThreshold : float = 0.005
export var massKG : float = 100.0

# public variables
var instantLinearVelocity : Vector3

# private variables
onready var parentBody : RigidBody = get_parent()

var previousDistance : float = abs(castTo.y)
var previousHit : ShapeCastResult = ShapeCastResult.new()
var collisionPoint : Vector3 = castTo
var grounded : bool = false

# shape cast result storage class
class ShapeCastResult:
	var hit_distance : float
	var hit_position : Vector3
	var hit_normal : Vector3
	var hit_point_velocity : Vector3
	var hit_body : PhysicsBody

# function to do sphere casting
func shape_cast(origin: Vector3, offset: Vector3):
	var space: PhysicsDirectSpaceState = get_world().direct_space_state as PhysicsDirectSpaceState
	var params: = PhysicsShapeQueryParameters.new()
	params.collision_mask = mask
	params.set_shape(shape)
	params.transform = transform
	params.transform.origin = origin
	# exclude parent body!
	params.exclude = [parentBody]
	
	# cast motion to get max motion possible with this cast
	var castResult = space.cast_motion(params, offset)

	var result : ShapeCastResult = ShapeCastResult.new()
	
	result.hit_distance = castResult[0] * offset.length()
	result.hit_position = origin + offset * castResult[0]
	
	# offset the params to the cast hit point and get rest info for more information
	params.transform.origin += offset * castResult[1]
	var collision = space.get_rest_info(params)
	
	result.hit_normal = collision.get("normal", Vector3.ZERO)
	result.hit_point_velocity = Vector3.ZERO
	result.hit_body = null
	
	# if a valid object has been hit
	if collision.get("rid"):
		# get the reference to the actual PhysicsBody that we are in contact with
		result.hit_body = instance_from_id(PhysicsServer.body_get_object_instance_id(collision.get("rid")))
		# get the velocity of the hit body at point of contact
		var hitBodyState := PhysicsServer.body_get_direct_state(collision.get("rid"))
		var hitBodyPoint : Vector3 = collision.get("point")
		result.hit_point_velocity = hitBodyState.get_velocity_at_local_position(hitBodyState.transform.xform_inv(hitBodyPoint))
		if GameState.debugMode:
			DrawLine3D.DrawRay(result.hit_position,result.hit_point_velocity,Color(0,0,0))
	
	return result

# getter for collision point
func get_collision_point() -> Vector3:
	return collisionPoint
	
# getter for collision check
func is_colliding() -> bool:
	return grounded

# set forward friction (braking)
func apply_brake(amount : float = 0.0) -> void:
	Ztraction = max(0.0, amount)

# function for applying drive force to parent body (if grounded)
func apply_force(force : Vector3) -> void:
	if is_colliding():
		parentBody.add_force(force, get_collision_point() - parentBody.global_transform.origin)

func _physics_process(delta) -> void:
	# perform sphere cast
	var castResult = shape_cast(global_transform.origin, castTo)
	collisionPoint = castResult.hit_position
	if GameState.debugMode:
		DrawLine3D.DrawCube(global_transform.origin,0.1,Color(255,0,255))
		DrawLine3D.DrawCube(global_transform.origin + castTo,0.1,Color(255,128,255))
	# [1, 1] means no hit (from docs)
	if castResult.hit_distance != abs(castTo.y):
		# if grounded, handle forces
		grounded = true
#		collisionPoint = castResult.hit_position
		if GameState.debugMode:
			DrawLine3D.DrawCube(castResult.hit_position,0.04,Color(0,255,255))
			DrawLine3D.DrawRay(castResult.hit_position,castResult.hit_normal,Color(255,255,255))
		
		# obtain instantaneaous linear velocity
		instantLinearVelocity = (collisionPoint - previousHit.hit_position) / delta
		
		# apply spring force with damping force
		var curDistance : float = castResult.hit_distance
		var FSpring : float = stifness * (abs(castTo.y) - curDistance) 
		var FDamp : float = damping * (previousDistance - curDistance) / delta
		var suspensionForce : float = clamp((FSpring + FDamp) * springForce,0,springMaxForce)
		var suspensionForceVec : Vector3 = castResult.hit_normal * suspensionForce
		
		# obtain axis velocity
		var localVelocity : Vector3 = global_transform.basis.xform_inv(instantLinearVelocity - castResult.hit_point_velocity) 
		
		# axis deceleration forces based on this drive elements mass and current acceleration
		var XAccel : float = (-localVelocity.x * Xtraction) / delta
		var ZAccel : float = (-localVelocity.z * Ztraction) / delta
		var XForce : Vector3 = global_transform.basis.x * XAccel * massKG
		var ZForce : Vector3 = global_transform.basis.z * ZAccel * massKG
		
		# counter sliding by negating off axis suspension impulse at very low speed
		var vLimit : float = instantLinearVelocity.length_squared() * delta
		if vLimit < staticSlideThreshold:
#			suspensionForceVec = Vector3.UP * suspensionForce
			XForce.x -= suspensionForceVec.x * parentBody.global_transform.basis.y.dot(Vector3.UP)
			ZForce.z -= suspensionForceVec.z * parentBody.global_transform.basis.y.dot(Vector3.UP)
		
		# final impulse force vector to be applied
		var finalForce = suspensionForceVec + XForce + ZForce
		
		# draw debug lines
		if GameState.debugMode:
			DrawLine3D.DrawRay(get_collision_point(),suspensionForceVec/GameState.debugRayScaleFac,Color(0,255,0))
			DrawLine3D.DrawRay(get_collision_point(),XForce/GameState.debugRayScaleFac,Color(255,0,0))
			DrawLine3D.DrawRay(get_collision_point(),ZForce/GameState.debugRayScaleFac,Color(0,0,255))
			
		# apply forces relative to parent body
		parentBody.add_force(finalForce, get_collision_point() - parentBody.global_transform.origin)
		
		# apply forces to body affected by this drive element (action = reaction)
		if castResult.hit_body && castResult.hit_body is RigidBody:
			castResult.hit_body.add_force(-finalForce, get_collision_point() - castResult.hit_body.global_transform.origin)
		
		# set the previous values at the very end, after they have been used
		previousDistance = curDistance
		previousHit = castResult
	else:
		# not grounded, set prev values to fully extended suspension
		grounded = false
		previousHit = ShapeCastResult.new()
		previousHit.hit_position = global_transform.origin + castTo
		previousHit.hit_distance = abs(castTo.y)
		previousDistance = previousHit.hit_distance
		instantLinearVelocity = Vector3.ZERO
