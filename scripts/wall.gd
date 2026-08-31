@tool
# @tool = ce script tourne AUSSI dans l'éditeur Godot, pas seulement en jeu.
# Concrètement : quand tu changes "Size" ou "Wall Type" dans l'Inspector,
# le mur se redimensionne et change de couleur tout de suite, sans lancer le jeu.

extends StaticBody2D

# ========== TYPE DE MUR ==========
# Décide de la force d'atténuation du son.
# Les valeurs correspondantes sont dans "wall_penalties" (enemy.gd).
# @export_enum = liste déroulante dans l'Inspector au lieu d'un champ texte libre
# (impossible de taper "epai" par erreur).
@export_enum("epais", "moyen", "fin") var wall_type: String = "moyen":
	set(value):
		wall_type = value
		_refresh()

# ========== DIMENSIONS ==========
# Taille du mur en pixels. Le mur est centré sur sa position.
@export var size: Vector2 = Vector2(100, 8):
	set(value):
		size = value
		_refresh()

@onready var forme: CollisionShape2D = $CollisionShape2D
@onready var visuel: ColorRect = $visuel

# Couleur d'affichage selon le type : plus le mur est épais, plus il est sombre.
# C'est purement une aide visuelle pour le banc d'essai.
const COULEURS = {
	"epais": Color(0.28, 0.26, 0.31),
	"moyen": Color(0.45, 0.42, 0.48),
	"fin":   Color(0.64, 0.60, 0.67)
}

func _ready():
	_refresh()

func _refresh():
	# Les variables @onready n'existent pas encore quand Godot charge la scène
	# et appelle les "set" ci-dessus. is_node_ready() renvoie false à ce moment-là :
	# on sort, et _ready() fera le vrai refresh juste après.
	if not is_node_ready():
		return

	# On recrée une forme neuve à chaque fois.
	# IMPORTANT : si on réutilisait la forme définie dans wall.tscn, TOUS les murs
	# du niveau partageraient le même objet et donc la même taille.
	var rect := RectangleShape2D.new()
	rect.size = size
	forme.shape = rect

	# Le ColorRect se positionne par ses bords (offsets), pas par son centre :
	# on le décale de la moitié de la taille pour qu'il soit centré comme la collision.
	visuel.offset_left = -size.x / 2.0
	visuel.offset_top = -size.y / 2.0
	visuel.offset_right = size.x / 2.0
	visuel.offset_bottom = size.y / 2.0
	visuel.color = COULEURS.get(wall_type, Color.MAGENTA)
