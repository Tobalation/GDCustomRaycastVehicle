extends Node

# global vars
var mouseHidden : bool = true
var debugMode : bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		if mouseHidden == true:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#			OS.window_fullscreen = false
			mouseHidden = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#			OS.window_fullscreen = true
			mouseHidden = true
	if event.is_action_pressed("debug_key"):
		if debugMode == true:
			debugMode = false
		else:
			debugMode = true
