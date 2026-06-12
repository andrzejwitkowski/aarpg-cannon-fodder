class_name WaterFft extends RefCounted

static func log2_int(n: int) -> int:
	var v := 0
	var t := n
	while t > 1:
		t >>= 1
		v += 1
	return v

static func fill_butterfly(n: int) -> PackedFloat32Array:
	var log_n := log2_int(n)
	var array := PackedFloat32Array()
	array.resize(log_n * n * 4)
	for step in log_n:
		var b: int = n >> (step + 1)
		for j in n / 2:
			var i: int = (2 * b * int(floor(j / float(b))) + (j % b)) % n
			var x: int = int(floor(j / float(b))) * b
			var tw_re: float = cos(TAU * x / n)
			var tw_im: float = -sin(TAU * x / n)
			_put_butterfly(array, step, n, j, tw_re, tw_im, i, i + b)
			_put_butterfly(array, step, n, j + n / 2, -tw_re, -tw_im, i, i + b)
	return array

static func _put_butterfly(array: PackedFloat32Array, step: int, n: int, col: int, re: float, im: float, ia: int, ib: int) -> void:
	var o := (step * n + col) * 4
	array[o] = re
	array[o + 1] = im
	array[o + 2] = float(ia)
	array[o + 3] = float(ib)

static func gaussian_noise(n: int, seed: int = 0) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else randi()
	var data := PackedFloat32Array()
	data.resize(n * n * 2)
	for i in n * n:
		var u1: float = maxf(rng.randf(), 1.0e-7)
		var u2: float = rng.randf()
		var r: float = sqrt(-2.0 * log(u1))
		data[i * 2] = r * cos(TAU * u2)
		data[i * 2 + 1] = r * sin(TAU * u2)
	return data
