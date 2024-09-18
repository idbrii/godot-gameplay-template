extends Object

class_name Baton

# Example usage:
#   var INPUT_MAP := {
#       "gamepad": {
#           "controls": {
#               "jump":       [JOY_BUTTON_A],
#               "dash":       [JOY_BUTTON_X],
#               "walk_left":  [Baton.JoyAxis(JOY_AXIS_LEFT_X, -1)],
#               "walk_right": [Baton.JoyAxis(JOY_AXIS_LEFT_X, 1)],
#               "walk_up":    [Baton.JoyAxis(JOY_AXIS_LEFT_Y, -1)],
#               "walk_down":  [Baton.JoyAxis(JOY_AXIS_LEFT_Y, 1)],
#           },
#           "device": 0,
#       },
#       "keyboard": {
#           "controls": {
#               "jump":       [KEY_UP, KEY_W, KEY_SPACE],
#               "dash":       [KEY_J],
#               "walk_left":  [KEY_A, KEY_LEFT],
#               "walk_right": [KEY_D, KEY_RIGHT],
#               "walk_up":    [KEY_W, KEY_UP],
#               "walk_down":  [KEY_S, KEY_DOWN],
#           },
#       },
#       "pairs": {
#           "horizontal": ["walk_left", "walk_right"],
#           "vertical":   ["walk_down", "walk_up"],
#       },
#       "quads": {
#           "move": ["walk_left", "walk_right", "walk_down", "walk_up"],
#       },
#       "deadzone": 0.5,
#   }
#
#   ## Setup a global input handler for a player spawn input, instantiate your
#   player, and call this on them before add_child.
#   func setup_input(event: InputEvent):
#       _input = Baton.new(Baton.filter_for_input_device(INPUT_MAP, event))
#
#   func _ready() -> void:
#       if not _input:
#           printt("[Player] Creating fallback Baton for player that consumes all inputs.", self)
#           _input = Baton.new(INPUT_MAP)
#
#   func _process(dt):
#       var move = _input.get_vector("move")
#       velocity += move * walk_speed * dt
#       var just_jump = _input.is_action_just_pressed("jump")
#       if just_jump:
#           velocity.y = -jump_force




var inputs


# gdlint:ignore = function-name
static func JoyAxis(axis, direction):
    return [axis, direction]


static func is_keyboardmouse_input(event: InputEvent):
    return event is InputEventKey or event is InputEventMouseButton


static func is_gamepad_input(event: InputEvent):
    return event is InputEventJoypadButton


static func get_gamepad_device(event: InputEvent):
    assert(event is InputEventJoypadButton, "Not a gamepad input.")
    return event.device


static func filter_for_input_device(input_map_template, event: InputEvent):
    var input_map = input_map_template.duplicate(true)
    if is_keyboardmouse_input(event):
        input_map.erase("gamepad")
    elif is_gamepad_input(event):
        input_map.erase("keyboard")
        input_map.gamepad.device = get_gamepad_device(event)
    else:
        # To avoid this error, setup your global input to look like this:
        #   func _input(event: InputEvent):
        #       if event.is_action_pressed("spawn_player"):
        #           var p = _spawn_player()
        #           p.setup_input(Baton.new(Baton.filter_for_input_device(event)))
        #           _spawnpoint.add_child(p)
        push_error("Why did we try to create Baton with this event: %s" % event)
    return input_map





func kbm_key_to_inputevent(key) -> InputEventKey:
    var ev := InputEventKey.new()
    ev.keycode = key
    return ev

func gamepad_key_to_inputevent(data, device) -> InputEvent:
    var input_type := typeof(data)

    if input_type == TYPE_INT:
        var ev := InputEventJoypadButton.new()
        ev.button_index = data
        ev.pressed = true
        ev.device = device
        return ev

    elif input_type == TYPE_ARRAY or input_type == TYPE_PACKED_INT32_ARRAY:
        var idx = data[0]
        var direction = data[1]
        var ev := InputEventJoypadMotion.new()
        ev.axis = idx
        ev.axis_value = direction
        ev.device = device
        return ev

    assert(false, "Invalid type for gamepad input.")
    return null

func _ensure_action(action, deadzone):
    if not InputMap.has_action(action):
        InputMap.add_action(action, deadzone)


var device_actions := {}
var pairs := {}
var quads := {}

func _init(input_map):
    # The input map is never the same for all players. Usually they're similar:
    # gamepads are probably the same except for the device id. But a
    # keyboard-only player won't include a gamepad section and vice versa.
    input_map.get_or_add("gamepad", {})
    var gamepad_device = input_map.gamepad.get_or_add("device", -1)
    for action in input_map.gamepad.get_or_add("controls", {}):
        var device_action = str(action, gamepad_device)
        device_actions[action] = device_action
        _ensure_action(device_action, input_map.deadzone)
        for key in input_map.gamepad.controls[action]:
            var ev := gamepad_key_to_inputevent(key, gamepad_device)
            InputMap.action_add_event(device_action, ev)

    input_map.get_or_add("keyboard", {})
    for action in input_map.keyboard.get_or_add("controls", {}):
        # Use identical key for keyboard so you can use a mix of both to
        # control this character. Clients should remove the keyboard from
        # input_map to exclude keyboard player.
        var device_action = str(action, gamepad_device)
        device_actions[action] = device_action
        _ensure_action(device_action, input_map.deadzone)
        for key in input_map.keyboard.controls[action]:
            var ev := kbm_key_to_inputevent(key)
            InputMap.action_add_event(device_action, ev)

    for action in input_map.pairs:
        var pair = input_map.pairs[action]
        pairs[action] = pair
        var q := []
        assert(len(pair) == 2, "Each pair should have two directions: {label}".format({label=action}))
        for input in pair:
            # Remap the axis input to this device's action names. (walk_left -> walk_left0)
            q.append(device_actions[input])
            assert(input in device_actions, "pair '{label}' contained action not in controls: {input_action}".format({label=action, input_action=input}))
        pairs[action] = q
    for action in input_map.quads:
        var quad = input_map.quads[action]
        assert(len(quad) == 4, "Each quad should have four directions: {label}".format({label=action}))
        var q := []
        for input in quad:
            assert(input in device_actions, "quad '{label}' contained action not in controls: {input_action}".format({label=action, input_action=input}))
            q.append(device_actions[input])
        quads[action] = q


func get_action_strength(action: String, exact: bool = false):
    return Input.get_action_strength(device_actions[action], exact)


func is_action_just_pressed(action: String, exact: bool = false):
    return Input.is_action_just_pressed(device_actions[action], exact)


func is_action_pressed(action: String, exact: bool = false):
    return Input.is_action_pressed(device_actions[action], exact)


func is_action_just_released(action: String, exact: bool = false):
    return Input.is_action_just_released(device_actions[action], exact)


func get_axis(pair: String):
    var p = pairs[pair]
    return Input.get_axis(p[0], p[1])


func get_vector(quad: String, deadzone: float = -1.0):
    var q = quads[quad]
    return Input.get_vector(q[0], q[1], q[2], q[3], deadzone)
