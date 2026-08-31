extends CharacterBody2D
# CharacterBody2D nous donne move_and_collide(), qui teste TOUT le trajet
# de la frame. Indispensable pour les balles rapides : à 1500 px/s la balle
# avance de 25 px par frame et sauterait par-dessus un mur de 16 px.

# ========== VALEURS PAR DÉFAUT ==========
# Toutes ces valeurs sont ÉCRASÉES par l'arme au moment du tir (voir player.gd).
# Elles ne servent que si on pose une balle à la main dans une scène.
@export var speed = 375          # Vitesse en pixels/seconde
@export var damage = 10            # Dégâts à l'impact
@export var max_range = 400.0      # Portée en pixels avant auto-destruction
@export var impact_noise = 40.0    # Bruit généré quand la balle frappe

# ========== DONNÉS PAR player.gd AU MOMENT DU TIR ==========
var direction = Vector2.RIGHT
var crit_chance = 0.05

# ========== INTERNE ==========
var distance_travelled = 0.0   # Distance parcourue depuis le tir

func _ready():
	# La balle naît DANS le joueur. Sans cette exception, move_and_collide
	# détecterait le joueur dès la première frame et la balle mourrait aussitôt.
	# add_collision_exception_with() dit au moteur physique : "ignore ce corps".
	# Oriente la balle dans le sens du tir (le sprite pointe vers la droite au repos)
	rotation = direction.angle()
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		add_collision_exception_with(player)

func _physics_process(delta):
	# Le déplacement voulu pour cette frame
	var motion = direction * speed * delta
	
	# move_and_collide déplace la balle et s'arrête net au premier obstacle
	# rencontré SUR LE TRAJET. Renvoie null si rien n'a été touché.
	var collision = move_and_collide(motion)
	
	if collision != null:
		_on_impact(collision)
		return
	
	# Rien touché : on comptabilise la distance parcourue
	distance_travelled += motion.length()
	
	# Portée épuisée : la balle retombe (on ne simule pas la chute, elle disparaît)
	if distance_travelled >= max_range:
		queue_free()

func _on_impact(collision):
	# get_collider() = l'objet touché (ennemi, TileMapLayer des murs, caisse...)
	var body = collision.get_collider()
	
	# DEBUG : à retirer quand tout sera validé
	print("IMPACT balle sur : ", body.name)
	
	# get_position() = le point de contact EXACT, en coordonnées globales.
	# Plus juste que global_position pour le futur système de propagation sonore.
	SoundManager.generate_noise(collision.get_position(), impact_noise)
	
	# Dégâts uniquement si la cible sait en encaisser (un mur ne sait pas)
	if body != null and body.has_method("take_damage"):
		var is_crit = randf() < crit_chance
		if is_crit:
			body.take_damage(damage * 4, true)   # Critique = ×4
		else:
			body.take_damage(damage, false)
	
	# Touché un mur ou un ennemi : la balle est consommée dans les deux cas
	queue_free()
