extends Camera2D

var offset_camera = 20.0  # Distance max caméra vers souris
var vitesse_transition = 0.08  # Vitesse de suivi souris (0.01-0.15)

func _process(_delta: float) -> void:
	# Position souris dans le monde
	var mouse_pos = get_global_mouse_position()
	
	# Direction du player vers la souris
	var player_pos = get_parent().global_position
	var direction_souris = (mouse_pos - player_pos).normalized()
	
	# Offset cible (limité à offset_camera pixels)
	var offset_cible = direction_souris * offset_camera
	
	# Interpolation fluide vers offset cible
	position = lerp(position, offset_cible, vitesse_transition)
