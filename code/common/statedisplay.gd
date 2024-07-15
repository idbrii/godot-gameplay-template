extends Label

@export var target : StateMachine

func _ready():
    target.state_transition.connect(_on_state_transition)

func _on_state_transition(new_state):
    var state_label = target.find_state_name(new_state)
    set_text(state_label)

