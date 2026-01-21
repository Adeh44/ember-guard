extends Area2D

# Variable reçue du joueur (chance de coup critique)
var crit_chance = 0.05  # Par défaut 5% si non défini
var damage = 10  # Dégâts de base

func _ready():
	body_entered.connect(_on_body_entered)

# Fonction appelée quand la hitbox touche quelque chose
func _on_body_entered(body):
	print("Quelque chose touché : ", body.name)
	
	# Vérifier si c'est un ennemi (a la méthode take_damage)
	if body.has_method("take_damage"):
		# Test aléatoire : randf() retourne un nombre entre 0 et 1
		var is_crit = randf() < crit_chance
		
		if is_crit:
			body.take_damage(damage * 4, true)
		else:
			body.take_damage(damage, false)
