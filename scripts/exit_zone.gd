extends Area2D

# Nom de la scène de destination
@export var target_scene: String = "res://scenes/TestLevel.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "player":
		print("Transition vers : ", target_scene)
		get_tree().call_deferred("change_scene_to_file", target_scene)
