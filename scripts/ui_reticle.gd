extends CanvasLayer

# Référence au conteneur central
@onready var center_container = $center_container

# Référence au joueur (pour récupérer aim_time)
var player = null

func _ready():
	# Cacher le curseur système
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Trouver le joueur dans la scène
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# Faire suivre le réticule à la souris
	center_container.position = get_viewport().get_mouse_position()
	
	# Calculer le scale basé sur la visée
	if player != null:
		var aim_ratio = player.aim_time / player.max_aim_time  # 0.0 à 1.0
		# Formule : commence à 0.7, descend jusqu'à 0.35
		var target_scale = 0.7 - (aim_ratio * 0.35)
		center_container.scale = Vector2(target_scale, target_scale)
