## Force the global rotation to stay at 0 (never rotate).
class_name NilRotation
extends Node2D


func _process(_dt):
    global_rotation = 0
