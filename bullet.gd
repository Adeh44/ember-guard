extends Area2D

# ========== STATS MODIFIABLES DANS L'INSPECTOR ==========
@export var speed = 400.0        # Vitesse de déplacement du projectile (pixels/seconde)
@export var damage = 10          # Dégâts infligés à l'impact
@export var lifetime = 2.0       # Durée de vie max avant auto-destruction (évite les balles infinies)

# Direction du tir (donnée par le joueur au moment du tir, pas modifiable dans l'Inspector)
var direction = Vector2.RIGHT

# Chance de critique (donnée par le joueur au moment du tir, comme hitbox_attack.gd)
var crit_chance = 0.05

func _ready():
	# Connecte le signal de collision à notre fonction
	body_entered.connect(_on_body_entered)
	
	# Auto-destruction après "lifetime" secondes (si rien n'est touché avant)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Déplace la balle en ligne droite dans sa direction, à sa vitesse
	position += direction * speed * delta

func _on_body_entered(body):
	# Ignore le joueur (évite de se tirer dessus soi-même)
	if body.name == "player":
		return
	
	# Si la cible peut prendre des dégâts, on lui en inflige
	if body.has_method("take_damage"):
		# Tirage aléatoire pour savoir si c'est un coup critique
		var is_crit = randf() < crit_chance
		
		if is_crit:
			# Critique = dégâts x4 (même règle que hitbox_attack.gd)
			body.take_damage(damage * 4, true)
		else:
			body.take_damage(damage, false)
	
	# La balle disparaît après avoir touché quelque chose
	queue_free()
