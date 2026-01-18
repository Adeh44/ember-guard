extends Area2D


func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Vérifier si c'est un ennemi
	# Infliger des dégâts
