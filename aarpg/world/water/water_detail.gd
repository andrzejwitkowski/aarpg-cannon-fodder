class_name WaterDetail extends RefCounted

static func bake(size: int = 512, octaves: int = 3, seed: int = 1234567) -> Image:
	var rand := PackedFloat32Array()
	rand.resize(size * size)
	var s := seed
	for i in size * size:
		s = (s * 1103515245 + 12345) & 0x7fffffff
		rand[i] = float(s) / 2147483647.0
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var u := float(x) / size
			var v := float(y) / size
			var h := _fbm(rand, size, u, v, octaves)
			var eps := 1.0 / size
			var hx := _fbm(rand, size, u + eps, v, octaves) - _fbm(rand, size, u - eps, v, octaves)
			var hy := _fbm(rand, size, u, v + eps, octaves) - _fbm(rand, size, u, v - eps, octaves)
			img.set_pixel(x, y, Color(
				clampf(-hx * 1.5 + 0.5, 0.0, 1.0),
				clampf(-hy * 1.5 + 0.5, 0.0, 1.0),
				clampf(h, 0.0, 1.0),
				clampf(_fbm(rand, size, u * 2.0, v * 2.0, octaves), 0.0, 1.0)
			))
	return img

static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

static func _octave(rand: PackedFloat32Array, size: int, u: float, v: float, f: int) -> float:
	var x := u * f
	var y := v * f
	var xi := int(floor(x))
	var yi := int(floor(y))
	var uu := _smooth(x - xi)
	var vv := _smooth(y - yi)
	var a := _sample(rand, size, f, xi, yi)
	var b := _sample(rand, size, f, xi + 1, yi)
	var c := _sample(rand, size, f, xi, yi + 1)
	var d := _sample(rand, size, f, xi + 1, yi + 1)
	return a * (1.0 - uu) * (1.0 - vv) + b * uu * (1.0 - vv) + c * (1.0 - uu) * vv + d * uu * vv

static func _sample(rand: PackedFloat32Array, size: int, f: int, x: int, y: int) -> float:
	var X := ((x % f) + f) % f
	var Y := ((y % f) + f) % f
	return rand[Y * size + X]

static func _fbm(rand: PackedFloat32Array, size: int, u: float, v: float, octaves: int) -> float:
	var s := 0.0
	var amp := 0.5
	var f := 4
	for _o in octaves:
		s += amp * _octave(rand, size, u, v, f)
		amp *= 0.5
		f *= 2
	return s
