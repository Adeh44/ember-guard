extends CharacterBody2D

# Stats
@export var hp = 50
@export var speed = 32

# IA Patrouille
var waypoints = []
var current_waypoint_index = 0
var patrol_threshold = 5

# IA États
enum State { PATROL, ALERT, CHASE }
var current_state = State.PATROL

# Détection
var player = null
var player_in_vision = false
@onready var vision_cone = $vision_cone

# ========== DÉTECTION SONORE ==========
@export var sound_detection_range = 105.0   # Portée d'un bruit d'intensité 100
@export var debug_sound = true              # Affiche le détail du calcul dans la console

var investigation_target = null

# Pénalités par type de mur : ce qu'il reste de son est DIVISÉ par ce nombre.
# Un Dictionary, c'est une liste de paires clé → valeur.
# wall_penalties["epais"] renvoie 4.0. Pratique pour associer un texte à un nombre.
var wall_penalties = {
	"epais": 4.0,
	"moyen": 2.0,
	"fin": 1.2
}

const MAX_MURS = 5          # Sécurité : au-delà, on arrête (anti boucle infinie)
const DECALAGE_MUR = 2.0    # Pixels dont on repart derrière un mur touché
const LAYER_MURS = 2        # Le raycast ne cherche QUE les murs (layer 2)

# ========== COMPORTEMENT (utile pour le banc d'essai) ==========
@export var is_stationary = false   # true = reste à son poste, ne patrouille pas
@export var vision_enabled = true   # false = cône de vision coupé (test sonore pur)

func _ready():
	var waypoints_group = get_tree().get_first_node_in_group("waypoints")
	if waypoints_group == null:
		waypoints_group = get_node_or_null("/root/TestLevel/waypoints_group")
	
	if waypoints_group != null:
		for child in waypoints_group.get_children():
			waypoints.append(child.global_position)
		print(name, " : ", waypoints.size(), " waypoints trouvés")
	else:
		print(name, " : ERREUR - Aucun groupe waypoints trouvé !")
	
	if vision_cone != null:
		vision_cone.body_entered.connect(_on_vision_body_entered)
		vision_cone.body_exited.connect(_on_vision_body_exited)
		vision_cone.monitoring = vision_enabled
		
	player = get_tree().get_first_node_in_group("player")
	SoundManager.noise_emitted.connect(_on_noise_detected)

func _on_noise_detected(noise_pos: Vector2, intensity: float):
	# S'il poursuit déjà le joueur, un bruit ne l'intéresse plus
	if current_state == State.CHASE:
		return

	# "reste" = combien de pixels ce bruit peut encore parcourir.
	# Un bruit d'intensité 100 parcourt sound_detection_range pixels.
	var reste = sound_detection_range * (intensity / 100.0)

	# Filtre rapide : si le bruit ne nous atteint même pas à vol d'oiseau
	# sans le moindre mur, inutile de lancer des raycasts.
	if global_position.distance_to(noise_pos) > reste:
		return

	# On part du point du bruit et on avance vers l'ennemi, mur après mur.
	var espace = get_world_2d().direct_space_state
	var pos = noise_pos
	var murs_traverses = 0

	while murs_traverses < MAX_MURS:
		# Raycast ponctuel : créé, utilisé, jeté. Rien n'est stocké dans la scène.
		var requete = PhysicsRayQueryParameters2D.create(pos, global_position)
		requete.collision_mask = LAYER_MURS   # ignore joueur et autres ennemis
		requete.collide_with_areas = false    # ignore cônes de vision, hitbox...
		var impact = espace.intersect_ray(requete)

		# Plus aucun mur entre nous : on sort de la boucle
		if impact.is_empty():
			break

		# 1) Le son consomme la distance qui le sépare du mur
		reste -= pos.distance_to(impact.position)
		if reste <= 0:
			if debug_sound:
				print(name, " : bruit éteint AVANT le mur")
			return

		# 2) Le mur atténue : on divise ce qu'il reste
		var type_mur = "moyen"
		if "wall_type" in impact.collider:
			type_mur = impact.collider.wall_type
		reste /= wall_penalties.get(type_mur, 2.0)

		# 3) On repart 2 px DERRIÈRE le point d'impact.
		#    Sans ce décalage, le raycast suivant retoucherait le même mur → boucle infinie.
		var direction = (global_position - pos).normalized()
		pos = impact.position + direction * DECALAGE_MUR

		murs_traverses += 1

	# Reste-t-il assez de son pour couvrir la distance qui reste ?
	var distance_finale = pos.distance_to(global_position)
	if reste >= distance_finale:
		if debug_sound:
			print(name, " : ENTENDU (reste %.1f px pour %.1f px, %d mur(s))" % [reste, distance_finale, murs_traverses])
		investigation_target = noise_pos
		current_state = State.ALERT
	elif debug_sound:
		print(name, " : étouffé (reste %.1f px, il en fallait %.1f, %d mur(s))" % [reste, distance_finale, murs_traverses])

func _physics_process(_delta):
	match current_state:
		State.PATROL:
			_patrol()
		State.ALERT:
			_investigate()
		State.CHASE:
			_chase_player()

func _investigate():
	if investigation_target == null:
		current_state = State.PATROL
		return
	
	# BANC D'ESSAI : un ennemi "stationnaire" signale qu'il a entendu (le print est déjà
	# parti) mais ne quitte pas son poste. Ça permet d'enchaîner les tests sans relancer.
	if is_stationary:
		investigation_target = null
		current_state = State.PATROL
		return
	
	var direction = (investigation_target - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	var distance = global_position.distance_to(investigation_target)
	if distance < 10 :
		print(name, " : Rien trouvé, retour patrouille")
		investigation_target = null
		current_state = State.PATROL

func _patrol():
	if is_stationary:   
		return          
	if waypoints.size() == 0:
		return
	
	var target_pos = waypoints[current_waypoint_index]
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	var distance = global_position.distance_to(target_pos)
	if distance < patrol_threshold:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func _chase_player():
	if player == null:
		current_state = State.PATROL
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * (speed * 1.3)  # ← Change 1.5 en 1.3
	move_and_slide()

func _on_vision_body_entered(body):
	if body.name == "player":
		player_in_vision = true
		current_state = State.CHASE
		print(name, " : JOUEUR DÉTECTÉ !")

func _on_vision_body_exited(body):
	if body.name == "player":
		player_in_vision = false
		current_state = State.PATROL
		print(name, " : Joueur perdu, retour patrouille")

func take_damage(amount, is_critical = false):
	hp -= amount
	if is_critical:
		print("CRITIQUE sur ", name, " ! -", amount, " HP")
	else:
		print(name, " : -", amount, " HP restants: ", hp)
	if hp <= 0:
		queue_free()
