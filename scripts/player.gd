extends CharacterBody2D

# Préchargement de la scène hitbox (optimisation)
var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")

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

# Référence à l'AnimationPlayer
@onready var anim_player = $anim_player

# Système de poids
var poids_total = 0.0  # Poids actuel du joueur (kg)
var poids_max = 100.0  # Poids maximum avant pénalité totale
var base_stealth = 100  # Niveau de discrétion de base
var current_stealth = 100 # Stealth actuelle (modifiée par poids)

func _ready():
	# Test : ajout de poids temporaire
	poids_total = 30.0 # simule 30kg dans le sac du joueur

func _physics_process(_delta):
		
		# ========== SYSTÈME DE VISÉE ==========
	if Input.is_action_pressed("aim"):
		is_aiming = true
		
		# Vérifier si le joueur bouge PENDANT la visée
		var direction_input = Vector2.ZERO
		direction_input.x = Input.get_axis("left", "right")
		direction_input.y = Input.get_axis("up", "down")
		var is_moving = direction_input.length() > 0
		
		if is_moving:
			# Visée en mouvement : plus lent
			aim_time += _delta * 0.5
		else:
			# Visée immobile : vitesse normale
			aim_time += _delta
		
		aim_time = min(aim_time, max_aim_time)
	else:
		is_aiming = false
		aim_time = 0.0
		
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
		current_speed = 0
	
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
	# Calculer la chance critique AVANT de tirer
	var crit_chance = calculate_crit_chance(aim_time)
	print("Chance critique : ", crit_chance * 100, "%")
	
	# Ajouter le recul après le tir
	recoil_penalty += recoil_per_shot
	recoil_penalty = min(recoil_penalty, 0.5)
	
	# Ralentir pendant attaque (70% vitesse)
	attacking = true
	can_attack = false
	
	# Créer hitbox
	var hitbox = hitbox_attack_scene.instantiate()
	hitbox.position = direction * 30  # Position RELATIVE (pas global_position)
	hitbox.crit_chance = crit_chance
	
	# Ajouter comme ENFANT du joueur (suit automatiquement)
	add_child(hitbox)
	
	# Disparaît plus vite
	await get_tree().create_timer(0.2).timeout
	attacking = false
	hitbox.queue_free()  # Fait disparaître la hitbox
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
