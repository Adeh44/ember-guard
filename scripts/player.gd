extends CharacterBody2D

var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")
var bullet_scene = preload("res://scenes/bullet.tscn")

enum WeaponMode { MELEE, RANGED }
var current_weapon_mode = WeaponMode.RANGED  # Mode par défaut au démarrage

# Stats
var speed = 150.0

# États
var attacking = false
var is_aiming = false

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

var noise_timer = 0.0  # Compte le temps depuis le dernier bruit émis
var noise_interval = 0.4  # Émet un bruit toutes les 0.4 secondes

# Référence à l'AnimationPlayer
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
	
	# ========== GESTION ARMEMENT ==========
	# Bascule temporaire CàC/Arme (en attendant la roue d'armement)
	if Input.is_action_just_pressed("switch_weapon"):
		if current_weapon_mode == WeaponMode.RANGED:
			current_weapon_mode = WeaponMode.MELEE
			print("Mode : Corps à corps")
		else:
			current_weapon_mode = WeaponMode.RANGED
			print("Mode : Arme à feu")
	
	# ========== SYSTÈME DE VISÉE ==========
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
	
	# ========== MOUVEMENT ==========
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	var poids_ratio = poids_total / poids_max
	var current_speed = speed * (1.0 - poids_ratio)
	current_speed = max(current_speed, speed * 0.3)

	# Marche lente (Ctrl) et sprint (Shift)
	var is_slow_walking = Input.is_action_pressed("slow_walk")
	var is_sprint = Input.is_action_pressed("sprint")

	if is_slow_walking:
		current_speed = current_speed / 2
	elif is_sprint:
		current_speed = current_speed * 1.5

	# Bruit de déplacement (throttlé toutes les 0.4s)
	if direction != Vector2.ZERO:
		noise_timer += _delta
		if noise_timer >= noise_interval:
			noise_timer = 0.0
			if is_slow_walking:
				SoundManager.generate_noise(global_position, 30.0)
			elif is_sprint:
				SoundManager.generate_noise(global_position, 150.0)
			else:
				SoundManager.generate_noise(global_position, 80.0)
	
	# PRIORITÉ 1 : Visée (réduit vitesse drastiquement)
	if is_aiming:
		if direction.length() > 0:
			current_speed = current_speed * 0.3
		else:
			current_speed = 0
	# PRIORITÉ 2 : Attaque en cours (CàC)
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
	
	# ========== TIR ==========
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
	# Calculer la chance critique AVANT de tirer (commun aux deux modes)
	var crit_chance = calculate_crit_chance(aim_time)
	print("Chance critique : ", crit_chance * 100, "%")
	
	recoil_penalty += recoil_per_shot
	recoil_penalty = min(recoil_penalty, 0.5)
	
	attacking = true
	can_attack = false
	
	if current_weapon_mode == WeaponMode.MELEE:
		# ===== CORPS À CORPS =====
		SoundManager.generate_noise(global_position, 50.0)
		
		var hitbox = hitbox_attack_scene.instantiate()
		hitbox.position = direction * 25
		hitbox.crit_chance = crit_chance
		add_child(hitbox)
		
		await get_tree().create_timer(0.2).timeout
		hitbox.queue_free()
	else:
		# ===== ARME À FEU (projectile) =====
		SoundManager.generate_noise(global_position, weapon.noise_level)
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = direction
		bullet.crit_chance = crit_chance
		get_tree().current_scene.add_child(bullet)
	
	attacking = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
