class_name StateMachine
extends Node


const label_scene = preload("res://scenes/common/ui_statemachine_label.tscn")


signal state_transition(new_state) # passes the state table


var states
var current_state


static func create(parent : Node, all_states) -> StateMachine:
    var sm = StateMachine.new()
    sm.create_states(all_states)
    parent.add_child(sm)
    return sm


func add_label(parent) -> Control:
    var label = label_scene.instantiate()
    var display = label.get_node("Label")
    display.target = self
    parent.add_child(label)
    return label


# Define states like this:
# var states := {
#     freestyle = {
#         enter = _enter_state_freestyle,
#         update = _update_state_freestyle,
#         exit = always_true,
#     },
#     climb = {
#         enter = _enter_state_climb,
#         update = _update_state_climb,
#         exit = always_true,
#     },
#     default_state = {
#         enter = always_true,
#         update = always_true,
#         exit = always_true,
#     },
# }
func create_states(all_states) -> void:
    states = all_states
    current_state = all_states.default_state


func current():
    return current_state


func transition_to(dest, data):
    current_state.exit.call(data)
    current_state = dest
    dest.enter.call(data)
    state_transition.emit(dest)


# Get a string name for the input state. Use sm.find_state_name(sm.current())
# to get the current state name.
func find_state_name(state) -> String:
    for key in states:
        if states[key] == state:
            return key
    return "<unknown>"

# call from _process or _physics_process.
func tick(dt):
    current_state.update.call(dt)


# funcs.gd {{{2
# TODO: I don't know how to reference these as variables.
static func always_true(_data):
    return true
static func always_false(_data):
    return false
# }}}

