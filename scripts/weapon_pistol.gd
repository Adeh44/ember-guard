extends Node2D

# Stats de l'arme de base
var weapon_name = "Pistolet"
var base_damage = 10
var damage = 10  # Dégâts actuels (modifiés par modules)
var weight = 1.5
var noise_level = 80
var fire_rate = 0.3

# ========== STATS RECUL / PRÉCISION ==========
@export var max_spread_angle = 30.0   # Dispersion max en degrés (varie selon l'arme : pistolet précis, fusil moins)
@export var recoil_per_shot = 0.05    # Augmentation du recul par tir (déjà présent côté joueur, à déplacer ici)
@export var recoil_recovery_rate = 0.15  # Vitesse de récupération du recul
@export var bullet_speed = 400.0  # Vitesse des balles tirées par cette arme

# ========== RECUL VISUEL ==========
@export var visual_recoil_distance = 4.0  # Distance de recul en pixels
@export var visual_recoil_recovery_speed = 8.0  # Vitesse de retour à la position normale
var recoil_offset = Vector2.ZERO  # Décalage actuel dû au recul
@export var visual_recoil_angle = 15.0  # Angle de recul en degrés
var recoil_rotation_offset = 0.0  # Décalage de rotation actuel

# Système de slots (modules équipés)
var slot_muzzle = null  # Silencieux OU frein (mutuellement exclusif)
var slot_optic = null   # Reflex OU zoom (mutuellement exclusif)

# ========== SYSTÈME DE MUNITIONS ==========
@export var magazine_size = 6      # Taille du chargeur (6 cartouches, cohérent avec le tuto)
var current_ammo = 6                # Munitions actuelles dans le chargeur
@export var reload_time = 1.5       # Temps de rechargement en secondes
var is_reloading = false            # Empêche de tirer pendant le rechargement

# Références aux sprites modules
@onready var sprite_silencer = $mod_silencer
@onready var sprite_reflex = $mod_reflex
@export var has_laser = false  # Le laser est-il équipé sur cette arme ?
@export var laser_spread_reduction = 0.15  # Réduit légèrement la dispersion max (15%)
@export var laser_recovery_multiplier = 2.0  # Récupération du recul 2x plus rapide avec laser
func apply_visual_recoil():
	var recoil_direction = -Vector2.RIGHT.rotated(rotation)
	recoil_offset = recoil_direction * visual_recoil_distance
	recoil_rotation_offset = deg_to_rad(visual_recoil_angle)  # Recul en rotation (converti en radians)

func _ready():
	print("Arme créée : ", weapon_name)
	print("Dégâts de base : ", base_damage)
	
	# TEST : Équiper silencieux et reflex
	equip_module("muzzle", "silencer")
	equip_module("optic", "reflex")

func _process(_delta):
	# Faire tourner l'arme vers la souris
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).angle()
	rotation = direction
	rotation += recoil_rotation_offset
		
	# Flip si vise à gauche
	if abs(direction) > PI / 2:
		scale.y = -0.4
	else:
		scale.y = 0.4

	# Retour progressif à la position normale après le recul
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, visual_recoil_recovery_speed * _delta)
	recoil_rotation_offset = lerp(recoil_rotation_offset, 0.0, visual_recoil_recovery_speed * _delta)
	position = recoil_offset
	
# Fonction pour équiper un module
func equip_module(slot_type, module_name):
	if slot_type == "muzzle":
		slot_muzzle = module_name
		if module_name == "silencer":
			sprite_silencer.visible = true
			# Effet silencieux : -30% dégâts, -50% bruit
			damage = base_damage * 0.7
			noise_level = 40
			print("Silencieux équipé : Dégâts ", damage, " | Bruit ", noise_level)
		else:
			sprite_silencer.visible = false
			
	elif slot_type == "optic":
		slot_optic = module_name
		if module_name == "reflex":
			sprite_reflex.visible = true
			print("Reflex équipé (placeholder, pas d'effet pour l'instant)")
		else:
			sprite_reflex.visible = false

# Fonction pour retirer un module
func unequip_module(slot_type):
	if slot_type == "muzzle":
		slot_muzzle = null
		sprite_silencer.visible = false
		# Restaurer stats de base
		damage = base_damage
		noise_level = 80
		print("Silencieux retiré : Dégâts restaurés à ", base_damage)
		
	elif slot_type == "optic":
		slot_optic = null
		sprite_reflex.visible = false
		print("Optique retirée")
