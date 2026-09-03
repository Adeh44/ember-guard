# ============================================================
# player.gd — le joueur
# Gère : déplacement (3 allures), bruit de pas, visée et chance
# de critique, tir / corps à corps, rechargement, poids, vie.
# Les stats de TIR vivent dans l'arme (weapon_pistol.gd) : le
# joueur les lit et les injecte dans chaque balle.
# ============================================================
extends CharacterBody2D

# ========== SCÈNES INSTANCIÉES À LA VOLÉE ==========
var hitbox_attack_scene = preload("res://scenes/hitbox_attack.tscn")
var bullet_scene = preload("res://scenes/bullet.tscn")

# ========== MODE D'ARME ==========
enum WeaponMode { MELEE, RANGED }
var current_weapon_mode = WeaponMode.RANGED   # Mode par défaut au démarrage

# ========== STATS ==========
@export var speed = 80   # Vitesse de base en px/s (avant poids et allure)

# ========== ÉTATS ==========
var attacking = false
var is_aiming = false

# ========== VISÉE ==========
# Plus on maintient la visée, plus la chance de critique monte
# (voir calculate_crit_chance). Le réticule rétrécit en même temps.
var aim_time = 0.0
var max_aim_time = 5.0

# ========== RECUL ==========
# recoil_penalty monte à chaque tir et redescend avec le temps.
# Les vitesses (recoil_per_shot, recoil_recovery_rate) viennent de l'arme.
var recoil_penalty = 0.0

# ========== BRUIT DE PAS ==========
var noise_timer = 0.0     # Temps écoulé depuis le dernier bruit émis
var noise_interval = 0.4  # Un bruit toutes les 0.4 s de déplacement

# ========== RÉFÉRENCES ==========
@onready var anim_player = $anim_player
@onready var weapon = $weapon_pistol

# ========== POIDS / VIE ==========
var poids_total = 0.0
var poids_max = 100.0
var max_hp = 100
var current_hp = 100
var armor = 0

func _ready():
	if weapon != null:
		poids_total += weapon.weight
	# Équipement posé EN DUR en attendant le vrai système d'équipement :
	# +30 kg de charge de base, puis casque + gilet : +40 d'armure (15+25)
	# et +6 kg (2+4). À brancher sur helmet_base/vest_base en passe 2.
	poids_total += 30.0
	armor += 40
	poids_total += 6.0
	print("Armor: ", armor, " | Poids: ", poids_total, "kg")

func take_damage(amount, _is_critical = false):
	# L'armure absorbe un pourcentage : 40 d'armure = -40% de dégâts
	var damage_reduction = armor / 100.0
	var actual_damage = amount * (1.0 - damage_reduction)
	current_hp -= actual_damage
	current_hp = max(current_hp, 0)
	print("Joueur -", actual_damage, " HP | HP: ", current_hp, "/", max_hp)
	if current_hp <= 0:
		print("GAME OVER")

func _physics_process(delta):

	# ========== CHANGEMENT D'ARMEMENT ==========
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

		# Récupération du recul PENDANT la visée : 2x plus lente qu'au repos
		# (le bras est tendu), boostée par le laser.
		if recoil_penalty > 0:
			var recovery = weapon.recoil_recovery_rate * delta * 0.5
			if weapon.has_laser:
				recovery *= weapon.laser_recovery_multiplier
			recoil_penalty -= recovery
			recoil_penalty = max(recoil_penalty, 0.0)

		# Viser en marchant remplit la jauge 2x plus lentement
		var direction_input = Vector2.ZERO
		direction_input.x = Input.get_axis("left", "right")
		direction_input.y = Input.get_axis("up", "down")
		var is_moving = direction_input.length() > 0

		if is_moving:
			aim_time += delta * 0.5
		else:
			aim_time += delta
		aim_time = min(aim_time, max_aim_time)
	else:
		is_aiming = false
		aim_time = 0.0

		# Récupération du recul hors visée (pleine vitesse, boostée par le laser)
		if recoil_penalty > 0:
			var recovery = weapon.recoil_recovery_rate * delta
			if weapon.has_laser:
				recovery *= weapon.laser_recovery_multiplier
			recoil_penalty -= recovery
			recoil_penalty = max(recoil_penalty, 0.0)

	# ========== MOUVEMENT ==========
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Le poids ralentit : à 50% de charge, -50% de vitesse (plancher : 30%)
	var poids_ratio = poids_total / poids_max
	var current_speed = speed * (1.0 - poids_ratio)
	current_speed = max(current_speed, speed * 0.3)

	# Les 3 allures : lente (÷2), normale, sprint (×1.5)
	var is_slow_walking = Input.is_action_pressed("slow_walk")
	var is_sprint = Input.is_action_pressed("sprint")

	if is_slow_walking:
		current_speed = current_speed / 2
	elif is_sprint:
		current_speed = current_speed * 1.5

	# ========== BRUIT DE PAS ==========
	# Chaque allure a son intensité — c'est LE cœur de l'infiltration.
	if direction != Vector2.ZERO:
		noise_timer += delta
		if noise_timer >= noise_interval:
			noise_timer = 0.0
			if is_slow_walking:
				# 45 et non 30 : à 30, la portée du bruit était de 31 px seulement
				# (banc d'essai du 31/08) — la marche lente était inaudible partout,
				# donc le mode furtif ne coûtait rien. À 45, portée 47 px : toujours
				# étouffée par un mur épais, mais audible de près et à découvert.
				SoundManager.generate_noise(global_position, 45.0)
			elif is_sprint:
				SoundManager.generate_noise(global_position, 150.0)
			else:
				SoundManager.generate_noise(global_position, 80.0)

	# Viser ralentit fortement ; attaquer au CàC ralentit un peu
	if is_aiming:
		if direction.length() > 0:
			current_speed = current_speed * 0.3
		else:
			current_speed = 0
	elif attacking:
		current_speed = current_speed * 0.7

	velocity = direction * current_speed
	move_and_slide()

	if velocity.length() > 0:
		anim_player.play("walk")
	else:
		anim_player.stop()

	# ========== RECHARGEMENT MANUEL ==========
	if Input.is_action_just_pressed("reload") and not weapon.is_reloading and current_weapon_mode == WeaponMode.RANGED:
		weapon.is_reloading = true
		print("Rechargement...")
		await get_tree().create_timer(weapon.reload_time).timeout
		weapon.current_ammo = weapon.magazine_size
		weapon.is_reloading = false
		print("Rechargement terminé : ", weapon.current_ammo, "/", weapon.magazine_size)

	# ========== ATTAQUE ==========
	if Input.is_action_just_pressed("atq") and not weapon.is_reloading:
		var mouse_pos = get_global_mouse_position()
		var direction_atq = (mouse_pos - global_position).normalized()
		attack(direction_atq)
		aim_time = 0.0
		is_aiming = false

func calculate_crit_chance(aim_duration):
	# Base 5%, +40% max avec la visée, malus du recul accumulé.
	# clamp = jamais sous 5%, jamais au-dessus de 100%.
	var chance = 0.05
	var aim_ratio = aim_duration / max_aim_time
	chance += aim_ratio * 0.40
	chance -= recoil_penalty
	return clamp(chance, 0.05, 1.0)

func attack(direction):
	var crit_chance = calculate_crit_chance(aim_time)
	print("Chance critique : ", crit_chance * 100, "%")

	if current_weapon_mode == WeaponMode.MELEE:
		# ===== CORPS À CORPS =====
		attacking = true

		SoundManager.generate_noise(global_position, 50.0)

		# La hitbox naît devant le joueur, frappe pendant 0.2 s, puis disparaît
		var hitbox = hitbox_attack_scene.instantiate()
		hitbox.position = direction * 13
		hitbox.crit_chance = crit_chance
		add_child(hitbox)

		await get_tree().create_timer(0.2).timeout
		hitbox.queue_free()
		attacking = false
	else:
		# ===== TIR =====
		# Chargeur vide : rechargement automatique, pas de tir
		if weapon.current_ammo <= 0:
			weapon.is_reloading = true
			print("Chargeur vide, rechargement automatique...")
			await get_tree().create_timer(weapon.reload_time).timeout
			weapon.current_ammo = weapon.magazine_size
			weapon.is_reloading = false
			print("Rechargement terminé : ", weapon.current_ammo, "/", weapon.magazine_size)
			return

		attacking = true

		weapon.current_ammo -= 1
		print("Munitions restantes : ", weapon.current_ammo, "/", weapon.magazine_size)

		SoundManager.generate_noise(global_position, weapon.noise_level)

		# Dispersion selon le recul accumulé.
		# L'ORDRE COMPTE : le spread de CE tir utilise le recul d'AVANT ce tir,
		# puis on ajoute le recul du tir. Sinon le premier tir serait déjà dévié.
		var spread_angle = recoil_penalty * weapon.max_spread_angle

		recoil_penalty += weapon.recoil_per_shot
		recoil_penalty = min(recoil_penalty, 1.0)

		print("Tir | spread applique : ", spread_angle, "° | recul apres tir : ", recoil_penalty)

		# Le laser réduit la dispersion (après le print : celui-ci montre le brut)
		if weapon.has_laser:
			spread_angle *= (1.0 - weapon.laser_spread_reduction)
		var random_spread = deg_to_rad(randf_range(-spread_angle, spread_angle))
		var dispersed_direction = direction.rotated(random_spread)

		var bullet = bullet_scene.instantiate()
		# add_child D'ABORD : global_position n'a de sens qu'une fois dans la scène
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = dispersed_direction
		bullet.crit_chance = crit_chance
		# La balle hérite de TOUTES les stats de l'arme.
		# Changer d'arme change le comportement des balles sans toucher au code.
		bullet.speed = weapon.bullet_speed
		bullet.damage = weapon.damage                # damage et non base_damage : le silencieux compte
		bullet.max_range = weapon.bullet_range
		bullet.impact_noise = weapon.bullet_impact_noise

		attacking = false

		weapon.apply_visual_recoil()

func _unhandled_input(event):
	# Échap ferme le jeu. Temporaire : sera remplacé par un vrai menu pause.
	# "ui_cancel" est une action native de Godot, déjà mappée sur Échap.
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
