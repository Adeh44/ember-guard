# ============================================================
# ui_weight.gd — affichage du poids porté (Label à l'écran)
# ============================================================
extends Label

var player = null   # Référence au joueur, trouvée au lancement

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# %.1f = un chiffre après la virgule ; %.0f = aucun
	if player != null:
		text = "Poids: %.1f/%.0f kg" % [player.poids_total, player.poids_max]
