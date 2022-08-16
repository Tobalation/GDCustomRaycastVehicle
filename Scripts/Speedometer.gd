extends Label

export(NodePath) onready var vehicle = get_node(vehicle) as RigidBody

func _physics_process(delta: float) -> void:
	var speed : float = vehicle.global_transform.basis.xform_inv(vehicle.linear_velocity).z
	text = "%d KM/H" % [speed * 3.6]
