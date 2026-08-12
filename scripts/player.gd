extends CharacterBody2D

# Préchargement de la scène hitbox (optimisation)
var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")
var bullet_scene = preload("res://scenes/bullet.tscn")

enum WeaponMode { MELEE, RANGED }
var current_weapon_mode = WeaponMode.RANGED  # Mode par défaut au démarrage

# Stats du joueur
var speed = 150.0 # Vitesse de déplacement normale

# États du joueur
var attacking = false  # True si le joueur est en train d'attaquer (ralenti à 70%)
var is_aiming = false  # True si le joueur vise (clic droit maintenu)

# Système de visée
var aim_time = 0.0  # Temps écoulé depuis le début de la visée
var max_aim_time = 5.0  # Temps max pour atteindre 100% de précision

# Système de recul
var recoil_penalty = 0.0  # Pénalité de précision actuelle (0-100%)
var recoil_per_shot = 0.05  # -5% par tir
var recoil_recovery_rate = 0.15  # Récupération 15%/seconde

# Système de cooldown attaque
var can_attack = true
var attack_cooldown = 0.3  # Secondes entre chaque attaque

var noise_timer = 0.0  # Compte le temps depuis le dernier bruit émis
var noise_interval = 0.4  # Émet un bruit toutes les 0.4 secondes

# Référence à l'AnimationPlayer
@onready var anim_player = $anim_player
@onready var weapon = $weapon_pistol  # Référence à l'arme

# Système de poids
var poids_total = 0.0  # Poids actuel du joueur (kg)
var poids_max = 100.0  # Poids maximum avant pénalité totale
var base_stealth = 100  # Niveau de discrétion de base
var current_stealth = 100 # Stealth actuelle (modifiée par poids)
# Système HP et armor
var max_hp = 100
var current_hp = 100
var armor = 0  # Réduit dégâts reçus

func _ready():
	# Ajouter le poids de l'arme au poids total
	if weapon != null:
		poids_total += weapon.weight
	
	# Test : ajout poids supplémentaire (sac, équipement)
	poids_total += 30.0

# TEST : Équiper casque et gilet
	armor += 15  # Casque
	poids_total += 2.0
	armor += 25  # Gilet
	poids_total += 4.0
	
	print("Équipement : Armor total = ", armor, " | Poids total = ", poids_total, "kg")
	
func take_damage(amount, _is_critical = false):
	# Réduction par armor (1 armor = -1% dégâts)
	var damage_reduction = armor / 100.0
	var actual_damage = amount * (1.0 - damage_reduction)
	
	current_hp -= actual_damage
	current_hp = max(current_hp, 0)
	
	print("Joueur touché ! -", actual_damage, " HP (armor: ", armor, ") | HP: ", current_hp, "/", max_hp)
	
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
		
		# Récupération recul PENDANT la visée
		if recoil_penalty > 0:
			recoil_penalty -= recoil_recovery_rate * _delta * 0.5  # Plus lent pendant visée
			recoil_penalty = max(recoil_penalty, 0.0)
		
		# Vérifier si le joueur bouge PENDANT la visée
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
		
		# Récupération recul (quand on ne vise pas)
		if recoil_penalty > 0:
			recoil_penalty -= recoil_recovery_rate * _delta
			recoil_penalty = max(recoil_penalty, 0.0)
		
	# ========== MOUVEMENT ==========
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	# Calculer vitesse avec pénalité de poids
	var poids_ratio = poids_total / poids_max
	var current_speed = speed * (1.0 - poids_ratio)
	current_speed = max(current_speed, speed * 0.3)

		#on voit si Ctrl est présse pour activier la marche lente.
	var is_slow_walking = Input.is_action_pressed("slow_walk") 
		
	var is_sprint = Input.is_action_pressed("sprint")
		# Si le joueur bouge (direction différente de zéro)
	if direction != Vector2.ZERO:
		# On ajoute le temps écoulé depuis la dernière frame au compteur
		noise_timer += _delta

	if is_slow_walking:
		current_speed = current_speed / 2
	elif is_sprint:
		current_speed = current_speed * 1.5
		
	# Si le compteur a atteint ou dépassé le seuil (0.4s)
	if noise_timer >= noise_interval:
		# On remet le compteur à zéro pour recommencer à compter
		noise_timer = 0.0

			# On choisit l'intensité du bruit selon la vitesse de déplacement
		if is_slow_walking:
			SoundManager.generate_noise(global_position, 30.0)
		elif is_sprint:
			SoundManager.generate_noise(global_position, 150.0)
		else:
			SoundManager.generate_noise(global_position, 80.0)
	
	# PRIORITÉ 1 : Visée (réduit vitesse drastiquement)
	if is_aiming:
		if direction.length() > 0:
			# Vise en bougeant = très lent
			current_speed = current_speed * 0.3
		else:
			# Vise immobile = bloqué
			current_speed = 0
	# PRIORITÉ 2 : Attaque en cours (CàC)
	elif attacking:
		current_speed = current_speed * 0.7  # Ralentir à 70%, pas bloquer
	
	velocity = direction * current_speed
	
	# Calculer stealth avec pénalité de poids
	current_stealth = base_stealth - (poids_total * 2)
	current_stealth = max(current_stealth, 0)
	
	# Déplacer le joueur (gère les collisions automatiquement)
	move_and_slide()
	
	# Animation selon mouvement
	if velocity.length() > 0:
		anim_player.play("walk")
	else:
		anim_player.stop()
		
	# ========== TIR ==========
	# Tir déclenché au clic GAUCHE
	if Input.is_action_just_pressed("atq") and can_attack:
		# Calculer la direction vers la souris
		var mouse_pos = get_global_mouse_position()
		var direction_atq = (mouse_pos - global_position).normalized()
		
		# Déclencher l'attaque (avec aim_time actuel)
		attack(direction_atq)
		
		# Réinitialiser la visée après le tir
		aim_time = 0.0
		is_aiming = false


# Calcule la chance de coup critique selon aim_time et recoil
func calculate_crit_chance(aim_duration):
	var chance = 0.05  # Base 5%
	
	# Bonus visée (0-40%)
	var aim_ratio = aim_duration / max_aim_time
	chance += aim_ratio * 0.40
	
	# Malus recul (-5% par tir précédent)
	chance -= recoil_penalty
	
	# Plafonnement 5-100%
	return clamp(chance, 0.05, 1.0)
	
func attack(direction):
	# Calculer la chance critique AVANT de tirer (commun aux deux modes)
	var crit_chance = calculate_crit_chance(aim_time)
	print("Chance critique : ", crit_chance * 100, "%")
	
	# Ajouter le recul après le tir (seulement pertinent pour arme à feu, mais ne gêne pas le CàC)
	recoil_penalty += recoil_per_shot
	recoil_penalty = min(recoil_penalty, 0.5)
	
	attacking = true
	can_attack = false
	
	if current_weapon_mode == WeaponMode.MELEE:
		# ===== CORPS À CORPS (ancien système hitbox) =====
		SoundManager.generate_noise(global_position, 50.0)
		
		var hitbox = hitbox_attack_scene.instantiate()
		hitbox.position = direction * 25
		hitbox.crit_chance = crit_chance
		add_child(hitbox)
		
		await get_tree().create_timer(0.2).timeout
		hitbox.queue_free()
	else:
		# ===== ARME À FEU (nouveau système projectile) =====
		SoundManager.generate_noise(global_position, weapon.noise_level)
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = direction
		bullet.crit_chance = crit_chance
		get_tree().current_scene.add_child(bullet)
	
	attacking = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
