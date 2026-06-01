#!/usr/bin/env -S godot -s
extends SceneTree

const GdUnitTestCIRunner = preload("res://addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd")

var _runner

func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	_runner = GdUnitTestCIRunner.new()
	_runner._debug_cmd_args = PackedStringArray(["GdUnitCmdTool.gd", "-a", "res://tests", "--ignoreHeadlessMode"])
	root.add_child(_runner)

func _finalize() -> void:
	queue_delete(_runner)
