# ============================================================
# loot_container.gd — conteneur fouillable (placeholder)
# Un seul loot par caisse : ramassé au contact, puis la caisse
# disparaît. L'idée "fouille avec timer + indices" attend dans
# IDEES_EN_ATTENTE.md.
# ============================================================
extends Area2D

var has_loot = true   # Passe à false une fois pillé (anti double-ramassage)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "player" and has_loot:
		print("Loot trouvé ! (placeholder)")
		has_loot = false
		queue_free()   # La caisse disparaît après ramassage
