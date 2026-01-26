extends Node2D

# Stats de l'arme
var weapon_name = "pistol"
var damage = 10  # Dégâts de base
var weight = 1.5  # Poids en kg
var noise_level = 80  # Niveau de bruit (0-100, plus élevé = plus bruyant)
var fire_rate = 0.3  # Temps entre tirs (secondes)

func _ready():
	print("Arme créée : ", weapon_name)
	print("Dégâts : ", damage, " | Poids : ", weight, "kg | Bruit : ", noise_level)
func _process(_delta):
	# Faire tourner l'arme vers la position de la souris
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).angle()
	rotation = direction
	
	# Flip vertical si vise à gauche (éviter pistolet à l'envers)
	if abs(direction) > PI / 2:
		scale.y = -0.6  # Négatif pour flip
	else:
		scale.y = 0.6  # Positif normal
