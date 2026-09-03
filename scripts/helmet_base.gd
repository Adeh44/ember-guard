# ============================================================
# helmet_base.gd — casque (placeholder équipement)
# Porte juste ses stats pour l'instant. Le vrai système
# d'équipement (ramassage, slots, poids) viendra plus tard.
# ============================================================
extends Node2D

var item_name = "Casque militaire"
var armor = 15     # Points d'armure
var weight = 2.0   # Poids en kg

func _ready():
	print("Casque : +", armor, " armor, ", weight, "kg")
