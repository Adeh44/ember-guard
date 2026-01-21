extends Area2D


func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Quelque chose touché : ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(10)
