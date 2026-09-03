# ============================================================
# vest_base.gd — gilet tactique (placeholder équipement)
# Même logique que helmet_base.gd : des stats en attente du
# vrai système d'équipement.
# ============================================================
extends Node2D

var item_name = "Gilet tactique"
var armor = 25     # Points d'armure
var weight = 4.0   # Poids en kg

func _ready():
	print("Gilet : +", armor, " armor, ", weight, "kg")
