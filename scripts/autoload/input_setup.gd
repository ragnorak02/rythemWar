extends Node
## InputSetup — programmatic InputMap configuration.
## Creates p1_ and p2_ prefixed actions for all game inputs.
## P1: ASDF keyboard cluster + first controller
## P2: JKLI keyboard cluster + second controller

func _ready() -> void:
	_setup_p1_inputs()
	_setup_p2_inputs()
	_setup_ui_inputs()

func _setup_p1_inputs() -> void:
	# Face buttons — P1 keyboard: D=face_a, F=face_b, S=face_x, A=face_y (left-hand cluster)
	_add_key_action("p1_face_a", KEY_D)
	_add_key_action("p1_face_b", KEY_F)
	_add_key_action("p1_face_x", KEY_S)
	_add_key_action("p1_face_y", KEY_A)

	# Direction keys — P1: arrow keys or WASD-adjacent
	_add_key_action("p1_up", KEY_W)
	_add_key_action("p1_down", KEY_X)
	_add_key_action("p1_left", KEY_Z)
	_add_key_action("p1_right", KEY_C)

	# Modifier — P1: left shift = RT equivalent
	_add_key_action("p1_modifier", KEY_SHIFT)

	# Controller — P1 (device 0)
	_add_joy_action("p1_face_a", JOY_BUTTON_A, 0)
	_add_joy_action("p1_face_b", JOY_BUTTON_B, 0)
	_add_joy_action("p1_face_x", JOY_BUTTON_X, 0)
	_add_joy_action("p1_face_y", JOY_BUTTON_Y, 0)
	_add_joy_action("p1_up", JOY_BUTTON_DPAD_UP, 0)
	_add_joy_action("p1_down", JOY_BUTTON_DPAD_DOWN, 0)
	_add_joy_action("p1_left", JOY_BUTTON_DPAD_LEFT, 0)
	_add_joy_action("p1_right", JOY_BUTTON_DPAD_RIGHT, 0)
	_add_joy_axis_action("p1_modifier", JOY_AXIS_TRIGGER_RIGHT, 0)

func _setup_p2_inputs() -> void:
	# Face buttons — P2 keyboard: K=face_a, L=face_b, J=face_x, I=face_y
	_add_key_action("p2_face_a", KEY_K)
	_add_key_action("p2_face_b", KEY_L)
	_add_key_action("p2_face_x", KEY_J)
	_add_key_action("p2_face_y", KEY_I)

	# Direction keys — P2
	_add_key_action("p2_up", KEY_UP)
	_add_key_action("p2_down", KEY_DOWN)
	_add_key_action("p2_left", KEY_LEFT)
	_add_key_action("p2_right", KEY_RIGHT)

	# Modifier — P2: right shift
	_add_key_action("p2_modifier", KEY_CTRL)

	# Controller — P2 (device 1)
	_add_joy_action("p2_face_a", JOY_BUTTON_A, 1)
	_add_joy_action("p2_face_b", JOY_BUTTON_B, 1)
	_add_joy_action("p2_face_x", JOY_BUTTON_X, 1)
	_add_joy_action("p2_face_y", JOY_BUTTON_Y, 1)
	_add_joy_action("p2_up", JOY_BUTTON_DPAD_UP, 1)
	_add_joy_action("p2_down", JOY_BUTTON_DPAD_DOWN, 1)
	_add_joy_action("p2_left", JOY_BUTTON_DPAD_LEFT, 1)
	_add_joy_action("p2_right", JOY_BUTTON_DPAD_RIGHT, 1)
	_add_joy_axis_action("p2_modifier", JOY_AXIS_TRIGGER_RIGHT, 1)

func _setup_ui_inputs() -> void:
	# Menu navigation (shared)
	_add_key_action("ui_menu_up", KEY_UP)
	_add_key_action("ui_menu_down", KEY_DOWN)
	_add_key_action("ui_menu_left", KEY_LEFT)
	_add_key_action("ui_menu_right", KEY_RIGHT)
	_add_key_action("ui_menu_confirm", KEY_ENTER)
	_add_key_action("ui_menu_back", KEY_ESCAPE)

func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.keycode = key
	InputMap.action_add_event(action_name, event)

func _add_joy_action(action_name: String, button: JoyButton, device: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = device
	InputMap.action_add_event(action_name, event)

func _add_joy_axis_action(action_name: String, axis: JoyAxis, device: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = 0.5
	event.device = device
	InputMap.action_add_event(action_name, event)
