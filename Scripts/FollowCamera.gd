extends Spatial

# Variable to control behavior
export var maxPitch : float = 70
export var minPitch : float = -45
export var maxZoom : float = 20
export var minZoom : float = 4
export var zoomStep : float = 2
export var verticalSensitivity : float = 0.002
export var horizontalSensitivity : float = 0.002
export var camLerpSpeed : float = 16
export var camYOffset : float = 7
export var camGroundOffset : float = 3
export(NodePath) var target

# Node references
var camTarget : Spatial = null
var cam : Camera
var curZoom : float = 0.0

func _ready() -> void:
	# Setup node references
	camTarget = get_node(target)
	cam = get_node("Camera")
	curZoom = cam.transform.origin.distance_to(camTarget.global_transform.origin)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		# Rotate and elevate the camera around the rig
		rotate_y(-event.relative.x * horizontalSensitivity)
		rotation.x = clamp(rotation.x - event.relative.y * verticalSensitivity, deg2rad(minPitch), deg2rad(maxPitch))
		orthonormalize()
		
	if event is InputEventMouseButton:
		# Change zoom level on mouse wheel rotation
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP and curZoom > minZoom:
				curZoom -= zoomStep
				camYOffset -= 0.25
			if event.button_index == BUTTON_WHEEL_DOWN and curZoom < maxZoom:
				curZoom += zoomStep
				camYOffset += 0.25

func _physics_process(delta) -> void:
	# Find the closest point that is blocking the camera
	var obstacle = get_world().direct_space_state.intersect_ray(camTarget.global_transform.origin+Vector3(0,camYOffset,0), cam.global_transform.origin+Vector3(0,-camGroundOffset,0),[camTarget])
	var offset : float = 0.0
	
	if not obstacle.empty():
		# Get distance to blocking point
		offset = camTarget.global_transform.origin.distance_to(obstacle.position)
		if offset < curZoom:
			cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,offset),delta * camLerpSpeed))
		else:
			cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,curZoom),delta * camLerpSpeed))
	else:
		cam.set_translation(cam.translation.linear_interpolate(Vector3(0,camYOffset,curZoom),delta * camLerpSpeed))
		
	set_translation(camTarget.global_transform.origin)
