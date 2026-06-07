class_name Club extends Node3D

@export_category("Swing")
@export var swing_duration: float = 0.2
@export var swing_degrees: float = 100.0
@export var flash_duration: float = 0.1
@export var hit_shape_size: Vector3 = Vector3(0.2, 0.2, 0.35)

@onready var hit_box: HitBox = $HitBox
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _swinging := false
var _flash_left := 0.0
var _base_mat: Material
var _red: StandardMaterial3D

func _ready() -> void:
	_red = StandardMaterial3D.new()
	_red.albedo_color = Color.RED
	var box := BoxShape3D.new()
	box.size = hit_shape_size
	hit_box.set_shape(box)
	_base_mat = mesh.get_active_material(0)
	hit_box.area_entered.connect(_on_hit_area)

func swing() -> void:
	if _swinging:
		return
	_swinging = true
	hit_box.set_active(true)
	mesh.set_surface_override_material(0, _red)
	_flash_left = flash_duration
	var y0 := rotation_degrees.y
	var half := swing_degrees * 0.5
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:y", y0 + half, swing_duration * 0.45)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees:y", y0 - half, swing_duration * 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees:y", y0, swing_duration * 0.2)
	tween.finished.connect(_finish_swing, CONNECT_ONE_SHOT)

func _on_hit_area(area: Area3D) -> void:
	if area is HurtBox:
		print('Trafiono!')

func _finish_swing() -> void:
	_swinging = false
	hit_box.set_active(false)

func _process(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left -= delta
	if _flash_left <= 0.0:
		mesh.set_surface_override_material(0, _base_mat)
