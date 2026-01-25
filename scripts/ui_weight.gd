extends Label

# Référence au joueur
var player = null

func _ready():
	# Trouver le joueur dans la scène
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# Mettre à jour l'affichage du poids
	if player != null:
		text = "Poids: %.1f/%.0f kg" % [player.poids_total, player.poids_max]
