class_name Club extends Node3D

@export_category("Swing")
@export var swing_duration: float = 0.2
@export var swing_degrees: float = 100.0
@export var flash_duration: float = 0.1

@onready var hit_box: HitBox = $HitBox
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _swinging := false
var _flash_left := 0.0
var _base_mat: Material
var _red := StandardMaterial3D.new()

func _ready() -> void:
	hit_box.monitoring = false
	_red.albedo_color = Color.RED
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 0.2, 0.35)
	hit_box.set_shape(box)
	_base_mat = mesh.get_active_material(0)

func swing() -> void:
	if _swinging:
		return
	_swinging = true
	hit_box.monitoring = true
	mesh.set_surface_override_material(0, _red)
	_flash_left = flash_duration
	var start_y := rotation_degrees.y
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:y", start_y + swing_degrees * 0.5, swing_duration * 0.45)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees:y", start_y - swing_degrees * 0.5, swing_duration * 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees:y", start_y, swing_duration * 0.2)
	tween.finished.connect(_finish_swing)

func _finish_swing() -> void:
	_swinging = false
	hit_box.monitoring = false

func _process(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left -= delta
	if _flash_left <= 0.0:
		mesh.set_surface_override_material(0, _base_mat)
