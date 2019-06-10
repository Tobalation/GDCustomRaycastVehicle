extends RayCast;
# control variables
export var springForce : float = 60.0;
export var damping : float = 10.0;
# refernce to parent body so we can apply forces
var parentBody : RigidBody;
# variable to hold information for damping
var previousDistance : float = abs(cast_to.y);

func _ready() -> void:
	parentBody = get_parent();

func _physics_process(delta) -> void:
	if is_colliding():
		# apply spring force with damping
		var curDistance = (global_transform.origin - get_collision_point()).length();
		var suspensionForce = springForce * (abs(cast_to.y) - curDistance) + damping * (previousDistance - curDistance)/delta;
		var impulseVector = parentBody.global_transform.basis.y * suspensionForce;
		previousDistance = curDistance;
		# note that the point has to be xform()'ed to be at the correct location
		parentBody.apply_impulse(parentBody.global_transform.basis.xform(parentBody.to_local(get_collision_point())),impulseVector * delta);