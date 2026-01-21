extends CanvasLayer

# Référence au conteneur central
@onready var center_container = $center_container

func _ready():
	# Cacher le curseur système
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	# Faire suivre le réticule à la souris
	center_container.position = get_viewport().get_mouse_position()
