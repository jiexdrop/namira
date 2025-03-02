extends Node

func _ready():
	if not InputMap.has_action("move_forward"):
		InputMap.add_action("move_forward")
		InputMap.action_add_event("move_forward", _create_key_event(KEY_W))
	
	if not InputMap.has_action("move_backward"):
		InputMap.add_action("move_backward")
		InputMap.action_add_event("move_backward", _create_key_event(KEY_S))
	
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		InputMap.action_add_event("move_left", _create_key_event(KEY_A))
	
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		InputMap.action_add_event("move_right", _create_key_event(KEY_D))
	
	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		InputMap.action_add_event("move_up", _create_key_event(KEY_SPACE))
	
	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		InputMap.action_add_event("move_down", _create_key_event(KEY_SHIFT))

func _create_key_event(keycode: int) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = keycode
	return event
