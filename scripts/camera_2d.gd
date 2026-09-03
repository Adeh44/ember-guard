# ============================================================
# camera_2d.gd — la caméra du joueur
# Enfant direct du joueur : elle le suit automatiquement, et se
# décale de quelques pixels vers la souris pour "regarder" où
# le joueur vise.
# ============================================================
extends Camera2D

@export var offset_camera = 11          # Décalage max vers la souris, en pixels
@export var vitesse_transition = 0.08   # Vitesse du glissement (0.01 = lent, 0.15 = sec)

func _process(_delta: float) -> void:
	# Direction du joueur vers la souris
	var mouse_pos = get_global_mouse_position()
	var player_pos = get_parent().global_position
	var direction_souris = (mouse_pos - player_pos).normalized()

	# Point visé par la caméra : à offset_camera pixels du joueur, vers la souris
	var offset_cible = direction_souris * offset_camera

	# lerp = chaque frame, on parcourt une fraction du chemin restant.
	# Résultat : un glissement fluide au lieu d'un saut sec.
	position = lerp(position, offset_cible, vitesse_transition)
