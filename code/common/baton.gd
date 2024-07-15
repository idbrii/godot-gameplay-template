extends Object

class_name Baton

# local baton = require 'baton'
#
# local input = baton.new {
#   controls = {
#     left = {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'},
#     right = {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'},
#     up = {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'},
#     down = {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'},
#     action = {'key:x', 'button:a'},
#   },
#   pairs = {
#     move = {'left', 'right', 'up', 'down'}
#   },
#   joystick = love.joystick.getJoysticks()[1],
# }
#
# function love.update(dt)
#   input:update()
#
#   local x, y = input:get 'move'
#   playerShip:move(x*100, y*100)
#   if input:pressed 'action' then
#     playerShip:shoot()
#   end
# end

var inputs


static func JoyAxis(axis, direction):
    return [axis, direction]


var controls := {
    "gamepad": {
        "controls": {
            "jump":       [JOY_BUTTON_A],
            "walk_left":  [JoyAxis(JOY_AXIS_LEFT_X, 1)],
            "walk_right": [JoyAxis(JOY_AXIS_LEFT_X, -1)],
            "walk_up":    [JoyAxis(JOY_AXIS_LEFT_Y, 1)],
            "walk_down":  [JoyAxis(JOY_AXIS_LEFT_Y, -1)],
        },
        "device": 0,
    },
    "keyboard": {
        "controls": {
            "jump":       [KEY_UP, KEY_W, KEY_SPACE],
            "walk_left":  [KEY_A, KEY_LEFT],
            "walk_right": [KEY_D, KEY_RIGHT],
            "walk_up":    [KEY_W, KEY_UP],
            "walk_down":  [KEY_S, KEY_DOWN],
        },
    },
    "pairs": {
        "walk":       ["walk_left", "walk_right", "walk_down", "walk_up"],
        "horizontal": ["walk_left", "walk_right"],
        "vertical":   ["walk_down", "walk_up"],
    },
    "quads": {
        "move": ["horizontal", "vertical"],
    },
    "deadzone": 0.5,
}


func kbm_key_to_inputevent(key) -> InputEventKey:
    var ev := InputEventKey.new()
    ev.keycode = key
    return ev

func gamepad_key_to_inputevent(data, device) -> InputEvent:
    if typeof(data) == TYPE_INT:
        var ev := InputEventJoypadButton.new()
        ev.button_index = data
        ev.button_pressed = true
        ev.device = device
        return ev

    elif typeof(data) == TYPE_PACKED_INT32_ARRAY:
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
    var device = input_map.gamepad.device
    for action in input_map.gamepad.controls:
        var device_action = str(action, device)
        device_actions[action] = device_action
        _ensure_action(device_action, input_map.deadzone)
        for key_list in input_map.gamepad.controls[action]:
            for key in key_list:
                var ev := gamepad_key_to_inputevent(key, device)
                InputMap.action_add_event(device_action, ev)

    for action in input_map.keyboard.controls:
        # Use the same key for keyboard so the same action works for both.
        var device_action = str(action, device)
        device_actions[action] = device_action
        _ensure_action(device_action, input_map.deadzone)
        for key_list in input_map.keyboard.controls[action]:
            for key in key_list:
                var ev := kbm_key_to_inputevent(key)
                InputMap.action_add_event(device_action, ev)

    for action in input_map.pairs:
        assert(action in device_actions, "pairs contained action not in controls: %s" % action)
        var q := []
        for input in input_map.pairs[action]:
            q.append(device_actions[input])
        assert(len(q) == 2, "Each pair should have two directions.")
        pairs[action] = q
    for action in input_map.quads:
        assert(action in device_actions, "quads contained action not in controls: %s" % action)
        var q := []
        for input in input_map.quads[action]:
            q.append(device_actions[input])
        assert(len(q) == 4, "Each quad should have four directions.")
        quads[action] = q

func get_action_strength(action: String, exact: bool = false):
    return Input.get_action_strength(device_actions[action], exact)

func get_axis(pair: String):
    var p = pairs[pair]
    return Input.get_axis(p[0], p[1])

func get_vector(quad: String, deadzone: float = -1.0):
    var q = quads[quad]
    return Input.get_vector(q[0], q[1], q[2], q[3], deadzone)

