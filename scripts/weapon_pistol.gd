# ============================================================
# weapon_pistol.gd — le pistolet
# L'arme porte TOUTES les stats de tir : player.gd les lit et
# les injecte dans chaque balle. Changer d'arme change donc le
# comportement des balles sans toucher au code.
#
# ⚠ RAPPEL @export : si une valeur a été modifiée dans
# l'Inspector, c'est ELLE qui gagne — la valeur écrite ici ne
# sert plus. Les vraies valeurs vivent dans weapon_pistol.tscn.
# ============================================================
extends Node2D

# ========== IDENTITÉ / STATS DE BASE ==========
var weapon_name = "Pistolet"
var base_damage = 10
var damage = 10        # Dégâts actuels (modifiés par les modules, ex. silencieux)
var weight = 1.5       # Poids en kg (compté dans poids_total du joueur)
var noise_level = 80   # Bruit du tir (40 avec silencieux)
# ⚠ PAS ENCORE UTILISÉ : cadence de tir prévue, en attente du
# système de cadence (aujourd'hui on peut tirer aussi vite qu'on clique).
var fire_rate = 0.3

# ========== RECUL / PRÉCISION ==========
# Le pistolet est l'arme la MOINS précise du jeu : canon court, ligne de
# visée courte. Les armes d'épaule feront mieux — c'est le cœur de la
# progression (pistolet punitif → fusil gratifiant).
@export var max_spread_angle = 30.0      # Dispersion max en degrés à recul plein
@export var recoil_per_shot = 0.05       # Recul ajouté par tir (Inspector : 0.3)
@export var recoil_recovery_rate = 0.15  # Vitesse de récupération du recul (Inspector : 0.4)
@export var bullet_speed = 400.0         # Vitesse des balles en px/s (Inspector : 1400)
@export var bullet_range = 400.0         # Portée en pixels (Inspector : 700)
@export var bullet_impact_noise = 40.0   # Bruit fait par la balle en frappant une surface

# ========== RECUL VISUEL (purement cosmétique) ==========
@export var visual_recoil_distance = 4.0        # Recul de l'arme en pixels
@export var visual_recoil_angle = 15.0          # Recul en rotation, en degrés
@export var visual_recoil_recovery_speed = 8.0  # Vitesse de retour à la normale
var recoil_offset = Vector2.ZERO                # Décalage actuel dû au recul
var recoil_rotation_offset = 0.0                # Rotation actuelle due au recul

# ========== MODULES (slots d'équipement) ==========
var slot_muzzle = null   # Silencieux OU frein de bouche (mutuellement exclusif)
var slot_optic = null    # Reflex OU zoom (mutuellement exclusif)

@onready var sprite_silencer = $mod_silencer
@onready var sprite_reflex = $mod_reflex

# Laser : pas encore un vrai module équipable, juste des stats en attente
@export var has_laser = false                  # Le laser est-il équipé ?
@export var laser_spread_reduction = 0.15      # -15% de dispersion max
@export var laser_recovery_multiplier = 2.0    # Récupération du recul ×2

# ========== MUNITIONS ==========
# 6 cartouches en début de partie — la progression passera par de meilleurs chargeurs
@export var magazine_size = 6
var current_ammo = 6                  # Munitions actuelles dans le chargeur
@export var reload_time = 1.5         # Temps de rechargement en secondes
var is_reloading = false              # Empêche de tirer pendant le rechargement

func _ready():
	print("Arme créée : ", weapon_name)
	print("Dégâts de base : ", base_damage)

	# TEST : silencieux + reflex équipés d'office, en attendant l'inventaire
	equip_module("muzzle", "silencer")
	equip_module("optic", "reflex")

func _process(delta):
	# L'arme tourne pour pointer vers la souris
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).angle()
	rotation = direction
	rotation += recoil_rotation_offset

	# Miroir vertical quand on vise à gauche, pour que l'arme ne soit pas à l'envers.
	# Valeur 1 et non 0.4 : en pixel art, un scale non entier détruit le rendu.
	if abs(direction) > PI / 2:
		scale.y = -1
	else:
		scale.y = 1

	# Retour progressif à la position normale après le recul visuel
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, visual_recoil_recovery_speed * delta)
	recoil_rotation_offset = lerp(recoil_rotation_offset, 0.0, visual_recoil_recovery_speed * delta)
	position = recoil_offset

# Appelé par player.gd à chaque tir : projette l'arme vers l'arrière
func apply_visual_recoil():
	var recoil_direction = -Vector2.RIGHT.rotated(rotation)
	recoil_offset = recoil_direction * visual_recoil_distance
	recoil_rotation_offset = deg_to_rad(visual_recoil_angle)   # Converti en radians

# ========== GESTION DES MODULES ==========
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

func unequip_module(slot_type):
	if slot_type == "muzzle":
		slot_muzzle = null
		sprite_silencer.visible = false
		# Restaurer les stats de base
		damage = base_damage
		noise_level = 80
		print("Silencieux retiré : Dégâts restaurés à ", base_damage)

	elif slot_type == "optic":
		slot_optic = null
		sprite_reflex.visible = false
		print("Optique retirée")
