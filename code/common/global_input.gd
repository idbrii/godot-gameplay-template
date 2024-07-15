extends Node

var CHEATS_ENABLED := true

func _input(event: InputEvent):
    if Input.is_action_just_pressed("toggle_full_screen"):
        _swap_fullscreen_mode()
    elif Input.is_action_just_pressed("quit_game"):
        get_tree().quit()
    elif CHEATS_ENABLED:
        _cheat_input(event)


func _cheat_input(_event: InputEvent):
    if Input.is_action_just_pressed("cheat_slomo"):
        if Engine.time_scale < 1:
            Engine.time_scale = 1
        else:
            Engine.time_scale = 0.1
    elif Input.is_action_just_pressed("cheat_teleport"):
        var player = get_tree().get_nodes_in_group("Player")[0]
        player.global_position = player.get_global_mouse_position()


func _swap_fullscreen_mode():
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
