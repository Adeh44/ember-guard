# ============================================================
# hitbox_attack.gd — la zone de frappe du corps à corps
# Créée par player.gd à chaque attaque, placée devant le joueur,
# détruite 0.2 s plus tard. Tout ce qu'elle touche entre-temps
# prend des dégâts.
# ============================================================
extends Area2D

var crit_chance = 0.05   # Écrasé par player.gd à chaque attaque
# ⚠ damage n'est PAS écrasé par player.gd : le corps à corps fait toujours 10,
# quelle que soit l'arme équipée (à corriger en passe 2).
var damage = 10

func _ready():
	# is_connected : évite de brancher deux fois le même signal
	# si la connexion existait déjà dans l'éditeur.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Quelque chose touché : ", body.name)               # DEBUG : à retirer plus tard
	print("Crit chance hitbox : ", crit_chance * 100, "%")    # DEBUG : à retirer plus tard

	# Le joueur ne peut pas se frapper lui-même
	if body.name == "player":
		return

	if body.has_method("take_damage"):
		var is_crit = randf() < crit_chance
		if is_crit:
			body.take_damage(damage * 4, true)   # Critique = ×4 (même règle que bullet.gd)
		else:
			body.take_damage(damage, false)
