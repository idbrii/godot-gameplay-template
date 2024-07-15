extends Node2D

@export var should_start_disabled := true


func _ready():
    if should_start_disabled:
        extinguish()


func illuminate():
    $visual.play("on")
    $PointLight2D.enabled = true


func extinguish():
    $visual.play("off")
    $PointLight2D.enabled = false
