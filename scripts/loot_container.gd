extends Area2D

var has_loot = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "player" and has_loot:
		print("Loot trouvé ! (placeholder)")
		has_loot = false
		queue_free()  # Disparaît après ramassage
