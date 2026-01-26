extends Node2D

var item_name = "Casque militaire"
var armor = 15  # Points d'armure
var weight = 2.0  # kg

func _ready():
	print("Casque : +", armor, " armor, ", weight, "kg")
