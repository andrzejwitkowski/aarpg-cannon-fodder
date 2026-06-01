extends Node

func _ready() -> void:
	var runner := GdUnitTestCIRunner.new()
	runner._debug_cmd_args = PackedStringArray(["GdUnitCmdTool.gd", "-a", "res://tests", "--ignoreHeadlessMode"])
	add_child(runner)
