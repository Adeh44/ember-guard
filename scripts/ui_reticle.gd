# ============================================================
# ui_reticle.gd — le réticule qui remplace le curseur système
# Il suit la souris et rétrécit pendant la visée : plus on vise
# longtemps, plus il est petit — retour visuel direct de la
# chance de critique.
# ============================================================
extends CanvasLayer

@onready var center_container = $center_container   # Le visuel du réticule

var player = null   # Pour lire aim_time / max_aim_time

func _ready():
	# On cache le curseur système : le réticule le remplace
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# Le réticule colle à la souris (coordonnées écran, pas monde : CanvasLayer)
	center_container.position = get_viewport().get_mouse_position()

	# Taille selon la visée : de 0.7 (pas visé) à 0.35 (visée pleine)
	if player != null:
		var aim_ratio = player.aim_time / player.max_aim_time   # 0.0 → 1.0
		var target_scale = 0.7 - (aim_ratio * 0.35)
		center_container.scale = Vector2(target_scale, target_scale)
