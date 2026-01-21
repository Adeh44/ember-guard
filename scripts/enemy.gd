extends CharacterBody2D

var hp = 50

# Fonction qui gère les dégâts reçus
# amount = quantité de dégâts
# is_critical = true si coup critique (affichage différent)
func take_damage(amount, is_critical = false):
	hp -= amount
	
	if is_critical:
		print("COUP CRITIQUE sur ", name, " ! Dégâts : ", amount)
	else:
		print(name, " subit ", amount, " dégâts. HP restants : ", hp)
	
	if hp <= 0:
		queue_free()
