extends Node2D

@export_range(1.0, 1000.0) var walk_speed := 1000.0
var block_input := false


func get_input() -> Dictionary:
    if block_input:
        return {
            "move": Vector2(0, 0),
        }
    var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return {
        "move": move,
    }


func _process(dt):
    var move = get_input().move
    global_position += move * walk_speed * dt
