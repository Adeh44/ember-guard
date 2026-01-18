extends CharacterBody2D
var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")

var speed = 150
var attacking = false

func _physics_process(_delta):
	if not attacking :
		var direction = Vector2.ZERO
		direction.x = Input.get_axis("left", "right")
		direction.y = Input.get_axis("up", "down")
	
		if direction != Vector2.ZERO:
			direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()
	
	if Input.is_action_just_pressed("atq"):
		var mouse_pos = get_global_mouse_position()
		var direction_atq = (mouse_pos - global_position).normalized()
		attack(direction_atq)
		print("direction attaque : ", direction_atq)
	
		
func attack(direction):
	attacking = true
	var hitbox = hitbox_attack_scene.instantiate()
	hitbox.global_position = global_position + direction * 30
	get_tree().current_scene.add_child(hitbox)
	await get_tree().create_timer(0.2).timeout
	attacking = false
	hitbox.queue_free()
	

	
