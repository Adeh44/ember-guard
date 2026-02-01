extends CharacterBody2D

var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")

# Stats
var speed = 150.0
var sprint_speed = 225.0  # v0.20 : Sprint

# États
var attacking = false
var is_aiming = false
var is_sprinting = false  # v0.20

# Visée
var aim_time = 0.0
var max_aim_time = 5.0

# Recul
var recoil_penalty = 0.0
var recoil_per_shot = 0.05
var recoil_recovery_rate = 0.15

# Cooldown
var can_attack = true
var attack_cooldown = 0.3

# Bruit course v0.20
var sprint_noise_timer = 0.0
var sprint_noise_interval = 0.5  # Bruit tous les 0.5s en sprint

# Références
@onready var anim_player = $anim_player
@onready var weapon = $weapon_pistol

# Poids/Stats
var poids_total = 0.0
var poids_max = 100.0
var base_stealth = 100
var current_stealth = 100
var max_hp = 100
var current_hp = 100
var armor = 0

func _ready():
	if weapon != null:
		poids_total += weapon.weight
	poids_total += 30.0
	armor += 40
	poids_total += 6.0
	print("Armor: ", armor, " | Poids: ", poids_total, "kg")

func take_damage(amount, _is_critical = false):
	var damage_reduction = armor / 100.0
	var actual_damage = amount * (1.0 - damage_reduction)
	current_hp -= actual_damage
	current_hp = max(current_hp, 0)
	print("Joueur -", actual_damage, " HP | HP: ", current_hp, "/", max_hp)
	if current_hp <= 0:
		print("GAME OVER")

func _physics_process(_delta):
	# Visée
	if Input.is_action_pressed("aim"):
		is_aiming = true
		if recoil_penalty > 0:
			recoil_penalty -= recoil_recovery_rate * _delta * 0.5
			recoil_penalty = max(recoil_penalty, 0.0)
		var direction_input = Vector2.ZERO
		direction_input.x = Input.get_axis("left", "right")
		direction_input.y = Input.get_axis("up", "down")
		var is_moving = direction_input.length() > 0
		if is_moving:
			aim_time += _delta * 0.5
		else:
			aim_time += _delta
		aim_time = min(aim_time, max_aim_time)
	else:
		is_aiming = false
		aim_time = 0.0
		if recoil_penalty > 0:
			recoil_penalty -= recoil_recovery_rate * _delta
			recoil_penalty = max(recoil_penalty, 0.0)
	
	# Mouvement
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	# Sprint v0.20
	is_sprinting = Input.is_action_pressed("sprint") and direction.length() > 0 and not is_aiming
	
	var poids_ratio = poids_total / poids_max
	var current_speed = speed * (1.0 - poids_ratio)
	current_speed = max(current_speed, speed * 0.3)
	
	# Appliquer sprint
	if is_sprinting:
		current_speed = sprint_speed * (1.0 - poids_ratio * 0.5)  # Moins pénalisé en sprint
	
	if is_aiming:
		if direction.length() > 0:
			current_speed = current_speed * 0.3
		else:
			current_speed = 0
	elif attacking:
		current_speed = current_speed * 0.7
	
	velocity = direction * current_speed
	current_stealth = base_stealth - (poids_total * 2)
	current_stealth = max(current_stealth, 0)
	
	move_and_slide()
	
	# Animation
	if velocity.length() > 0:
		anim_player.play("walk")
	else:
		anim_player.stop()
	
	# v0.20 : Bruit sprint
	if is_sprinting:
		sprint_noise_timer += _delta
		if sprint_noise_timer >= sprint_noise_interval:
			SoundManager.generate_noise(global_position, 25.0)  # Bruit moyen
			sprint_noise_timer = 0.0
	else:
		sprint_noise_timer = 0.0
	
	# Tir
	if Input.is_action_just_pressed("atq") and can_attack:
		var mouse_pos = get_global_mouse_position()
		var direction_atq = (mouse_pos - global_position).normalized()
		attack(direction_atq)
		aim_time = 0.0
		is_aiming = false

func calculate_crit_chance(aim_duration):
	var chance = 0.05
	var aim_ratio = aim_duration / max_aim_time
	chance += aim_ratio * 0.40
	chance -= recoil_penalty
	return clamp(chance, 0.05, 1.0)

func attack(direction):
	var crit_chance = calculate_crit_chance(aim_time)
	print("Crit: ", crit_chance * 100, "%")
	recoil_penalty += recoil_per_shot
	recoil_penalty = min(recoil_penalty, 0.5)
	attacking = true
	can_attack = false
	
	# v0.20 : Bruit tir fort
	SoundManager.generate_noise(global_position, 100.0)  # Augmenté 50→100
	
	var hitbox = hitbox_attack_scene.instantiate()
	hitbox.position = direction * 25
	hitbox.crit_chance = crit_chance
	add_child(hitbox)
	
	await get_tree().create_timer(0.2).timeout
	attacking = false
	hitbox.queue_free()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
