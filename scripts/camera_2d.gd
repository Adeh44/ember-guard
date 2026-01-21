extends Camera2D

#CREATION DU DECALAGE DE LA CAMERA EN FONCTION DE LA DIRECTION DU JOUEUR

var offset_camera = 50.0
var vitesse_transition = 0.05

#Fonction appelée à chaque frame
func _process(_delta: float) -> void:
	var player_velocity = get_parent().velocity
	
	if player_velocity.length() > 0:  # Si le joueur bouge
		var offset_cible = player_velocity.normalized() * offset_camera
		position = lerp(position, offset_cible, vitesse_transition)
	else:  # Si le joueur est immobile
		position = lerp(position, Vector2.ZERO, vitesse_transition)
