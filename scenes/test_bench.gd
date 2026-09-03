# ============================================================
# test_bench.gd — pilote du banc d'essai (outil de dev)
# Téléporte le joueur d'un poste de test au suivant avec la
# touche T, pour enchaîner les mesures sans relancer le jeu.
# Ne fait partie d'aucun niveau réel : à retirer avant la v1.0
# si le banc n'est pas conservé.
# ============================================================
extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var spots_group = $test_spots

var spots = []             # Position de chaque poste, dans l'ordre de l'arborescence
var current_spot_index = 0 # Poste où se trouve le joueur en ce moment

func _ready():
	# On relève la position de chaque Marker2D enfant de "test_spots"
	for child in spots_group.get_children():
		spots.append(child.global_position)
	print("Banc d'essai : ", spots.size(), " postes. Touche T = poste suivant.")
	if spots.size() > 0:
		_go_to_spot(0)

func _unhandled_key_input(event):
	# event.echo est vrai quand la touche reste enfoncée et se répète :
	# sans ce filtre, garder T appuyé ferait défiler tous les postes.
	if event.pressed and not event.echo and event.keycode == KEY_T:
		# % = reste de la division. Un reste n'atteint jamais son diviseur :
		# avec 3 postes, % 3 ne peut donner que 0, 1 ou 2 — jamais 3.
		# L'index revient donc à 0 tout seul après le dernier poste, sans
		# jamais déborder du tableau. Cette seule ligne remplace :
		#     current_spot_index += 1
		#     if current_spot_index >= spots.size():
		#         current_spot_index = 0
		current_spot_index = (current_spot_index + 1) % spots.size()
		_go_to_spot(current_spot_index)

# i et non current_spot_index : la fonction se sert du numéro qu'on lui
# passe. C'est ce qui permet d'appeler _go_to_spot(0) pour revenir au début.
func _go_to_spot(i):
	player.global_position = spots[i]
	print("-> Poste ", i + 1, "/", spots.size(), " : ", spots_group.get_child(i).name)
