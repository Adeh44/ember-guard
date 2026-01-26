extends Node2D

# Stats de l'arme de base
var weapon_name = "Pistolet"
var base_damage = 10
var damage = 10  # Dégâts actuels (modifiés par modules)
var weight = 1.5
var noise_level = 80
var fire_rate = 0.3

# Système de slots (modules équipés)
var slot_muzzle = null  # Silencieux OU frein (mutuellement exclusif)
var slot_optic = null   # Reflex OU zoom (mutuellement exclusif)

# Références aux sprites modules
@onready var sprite_silencer = $mod_silencer
@onready var sprite_reflex = $mod_reflex

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
	
	# Flip si vise à gauche
	if abs(direction) > PI / 2:
		scale.y = -0.4
	else:
		scale.y = 0.4

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
