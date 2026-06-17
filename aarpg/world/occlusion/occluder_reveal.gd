class_name OccluderReveal extends Node

const GROUP := &"occluder_reveal"
const SHADER := preload("res://assets/shaders/occlusion_reveal.gdshader")

static var _white_tex_cache: Texture2D

@export_category("Reveal")
@export var hole_radius: float = 1.2:
	set(v):
		hole_radius = maxf(v, 0.1)
		_sync_shader_params()
@export var melt_width: float = 0.35:
	set(v):
		melt_width = maxf(v, 0.05)
		_sync_shader_params()
@export var fade_speed: float = 8.0:
	set(v):
		fade_speed = maxf(v, 0.1)
@export var fire_color_hot: Color = Color(1.0, 0.45, 0.05):
	set(v):
		fire_color_hot = v
		_sync_shader_params()
@export var fire_color_cool: Color = Color(0.85, 0.15, 0.02):
	set(v):
		fire_color_cool = v
		_sync_shader_params()

var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _reveal_strength: float = 0.0
var _reveal_target: float = 0.0

func _ready() -> void:
	add_to_group(GROUP)
	var parent := get_parent()
	_mesh = parent as MeshInstance3D if parent is MeshInstance3D else null
	if _mesh == null:
		push_error("OccluderReveal requires a parent MeshInstance3D")
		return
	_build_material()

func _process(delta: float) -> void:
	if _material == null:
		return
	_reveal_strength = lerpf(_reveal_strength, _reveal_target, clampf(fade_speed * delta, 0.0, 1.0))
	_material.set_shader_parameter("reveal_strength", _reveal_strength)

func set_reveal_target(target: float) -> void:
	_reveal_target = clampf(target, 0.0, 1.0)

func get_collider() -> CollisionObject3D:
	var node: Node = _mesh
	while node != null:
		if node is CollisionObject3D:
			return node as CollisionObject3D
		node = node.get_parent()
	return null

func _build_material() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	var source := _mesh.material_override
	if source == null and _mesh.mesh != null and _mesh.mesh.get_surface_count() > 0:
		source = _mesh.get_surface_override_material(0)
		if source == null:
			source = _mesh.mesh.surface_get_material(0)
	_sync_shader_params()
	_material.set_shader_parameter("albedo_tex", _white_texture())
	if source is StandardMaterial3D:
		var std := source as StandardMaterial3D
		if std.albedo_texture != null:
			_material.set_shader_parameter("albedo_tex", std.albedo_texture)
		_material.set_shader_parameter("albedo_tint", std.albedo_color)
	_mesh.material_override = _material

func _sync_shader_params() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("hole_radius", hole_radius)
	_material.set_shader_parameter("melt_width", melt_width)
	_material.set_shader_parameter("fire_color_hot", fire_color_hot)
	_material.set_shader_parameter("fire_color_cool", fire_color_cool)

static func _white_texture() -> Texture2D:
	if _white_tex_cache == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_white_tex_cache = ImageTexture.create_from_image(image)
	return _white_tex_cache
