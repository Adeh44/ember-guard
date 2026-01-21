extends CharacterBody2D

var hp = 50

func take_damage(amount):
	hp = hp - amount
	print("l'ennemi subit des degats, il reste ", hp, "HP")
	
	if hp <= 0:
		queue_free()
