extends MeshInstance

# public variables
export var wheelOffset : Vector3 = Vector3(0,0.5,0)
export var wheelSpeedScaling : float = 1.0
export var returnSpeed : float = 8.0

# private variables
var wheelRay : RayCast
var lastPos : Vector3 = Vector3()

func _ready() -> void:
	# setup references
	wheelRay = get_parent()
	
func _physics_process(delta) -> void:
	# obtain velocity of the wheel
	var instantV = (global_transform.origin - lastPos) / delta
	var ZVel = wheelRay.global_transform.basis.xform_inv(instantV).z
	lastPos = global_transform.origin
	
	# rotate the wheel according to speed
	rotate_x(ZVel * wheelSpeedScaling * delta)
	
	# set the wheel position
	if wheelRay.is_colliding():
		transform.origin.y = (wheelRay.to_local(wheelRay.get_collision_point()) + wheelOffset).y
	else:
		transform.origin.y = lerp(transform.origin.y, (wheelRay.cast_to + wheelOffset).y, returnSpeed * delta)
