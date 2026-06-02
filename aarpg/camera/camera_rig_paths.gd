class_name CameraRigPaths extends RefCounted

const RIG_SCENE := "res://camera/camera_rig.tscn"
const RIG_ROOT_NAME := "CameraPivot"
const CAMERA_RELATIVE := "SpringArm3D/Camera3D"
const CAMERA_GROUP := &"camera"

static func camera_path_from_world() -> String:
	return "%s/%s" % [RIG_ROOT_NAME, CAMERA_RELATIVE]
