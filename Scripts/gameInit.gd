extends Node

var mouseHidden : bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if mouseHidden == true:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#			OS.window_fullscreen = false
			mouseHidden = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#			OS.window_fullscreen = true
			mouseHidden = true