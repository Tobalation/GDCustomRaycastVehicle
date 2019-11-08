extends MeshInstance

export var wheelOffset : Vector3 = Vector3(0,0.62,0)
export var trackThickness : float = 0.05
export var boneName : String
export(NodePath) var raycastPath
export(NodePath) var trackSkeletonPath

var raycast : RayCast
var trackSkeleton : Skeleton
var trackBone
var trackOffset : Vector3 = Vector3(0,trackThickness,0)

func _ready():
	# setup references
	raycast = get_node(raycastPath)
	trackSkeleton = get_node(trackSkeletonPath)
	trackBone = trackSkeleton.find_bone(boneName)
	if boneName == null:
		boneName = self.name
	
func _physics_process(delta):
	# set the wheel position
	# TODO: interpolate when not colliding and proper positioning along ray axis
	if raycast.is_colliding():
		transform.origin.y = (raycast.to_local(raycast.get_collision_point()) + wheelOffset).y
	else:
		transform.origin.y = (raycast.cast_to + wheelOffset).y
	# deform the track
	var tbonePos = trackSkeleton.get_bone_global_pose(trackBone)
	tbonePos.origin = trackSkeleton.global_transform.xform_inv(global_transform.origin + trackOffset)
	trackSkeleton.set_bone_global_pose(trackBone, tbonePos)