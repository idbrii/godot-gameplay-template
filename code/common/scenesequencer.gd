extends Node

const seq : LevelSceneSequence = preload("res://levels/level_sequence.tres")
const music_scene = preload("res://scenes/common/music.tscn")


# TODO: Can I actually find the current scene so the next level is correct when
# debug loading in the middle of progression?
@onready var current_level = seq.levels[0]
var music


func _ready():
    # TODO: Is this connecting more than once?
    Broadcast.completed_level.connect(_on_completed_level)
    music = music_scene.instantiate()
    add_child(music)


var can_complete := true
func _on_completed_level():
    can_complete = false
    var current_index = seq.levels.find(current_level)
    var i = 0
    if current_index >= 0:
        i = current_index + 1
    var next_level = seq.levels[i] as PackedScene
    assert(next_level, "LevelSceneSequence contained invalid scene.")
    printt("SceneSequencer: transition", current_level, current_index, "->", next_level, i)

    current_level = next_level
    get_tree().change_scene_to_packed(next_level)
    call_deferred("_allow_complete")

func _allow_complete():
    # Delay a second before you can transition again to prevent double transitions.
    await get_tree().create_timer(1).timeout
    can_complete = true


