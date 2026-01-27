extends Area2D

var crit_chance = 0.05  # Sera écrasé par player
var damage = 10

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Quelque chose touché : ", body.name)
	print("Crit chance hitbox : ", crit_chance * 100, "%")  # AJOUTE CETTE LIGNE DEBUG
	
	# EXCLURE JOUEUR
	if body.name == "player":
		return
	
	if body.has_method("take_damage"):
		var is_crit = randf() < crit_chance
		
		if is_crit:
			body.take_damage(damage * 4, true)
		else:
			body.take_damage(damage, false)
