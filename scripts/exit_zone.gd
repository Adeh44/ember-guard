# ============================================================
# exit_zone.gd — zone de sortie
# Change de niveau quand le joueur entre dedans.
# ============================================================
extends Area2D

@export var target_scene: String = "res://scenes/TestLevel.tscn"   # Scène de destination

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "player":
		print("Transition vers : ", target_scene)
		# call_deferred : on ne détruit pas la scène en plein calcul de
		# physique — Godot fera le changement à la fin de la frame.
		get_tree().call_deferred("change_scene_to_file", target_scene)
