extends Node

export(NodePath) var vehiclePath

var vehicle : RigidBody
var vehicleStartTransform : Transform

func _ready():
	vehicle = get_node(vehiclePath)
	vehicleStartTransform = vehicle.global_transform

func _physics_process(delta):
	if Input.is_action_pressed("reset_vehicle"):
		vehicle.linear_velocity = Vector3()
		vehicle.angular_velocity = Vector3()
		vehicle.global_transform = vehicleStartTransform
