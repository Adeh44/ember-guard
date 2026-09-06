# ============================================================
# enemy.gd — l'ennemi
# Patrouille entre des waypoints, entend les bruits (avec
# atténuation par les murs), enquête sur ce qu'il entend, et
# poursuit le joueur s'il le voit dans son cône de vision.
# États : PATROL → ALERT (bruit) → CHASE (vu).
# ============================================================
extends CharacterBody2D

# ========== STATS ==========
@export var hp = 50
@export var speed = 32

# ========== IA PATROUILLE ==========
var waypoints = []
var current_waypoint_index = 0
var patrol_threshold = 5   # Distance (px) à laquelle un waypoint est "atteint"

# ========== IA ÉTATS ==========
enum State { PATROL, ALERT, CHASE }
var current_state = State.PATROL

# ========== DÉTECTION VISUELLE ==========
var player = null
var player_in_vision = false
@onready var vision_cone = $vision_cone

# ========== DÉTECTION SONORE ==========
@export var sound_detection_range = 105.0   # Portée d'un bruit d'intensité 100
@export var debug_sound = true              # Affiche le détail du calcul dans la console

var investigation_target = null

# ========== MÉMOIRE DE POURSUITE ==========
# L'état ALERT a une durée de vie : sans elle, une machine à états n'est
# qu'un aiguillage, et un ennemi dont la cible est derrière un mur cherche
# pour l'éternité. Les minuteurs sont le seul mécanisme qui TERMINE une recherche.
#
# Ils sont DEUX, et c'est le point important : les durées ci-dessous comptent une
# FOUILLE SUR PLACE, jamais un budget de déplacement. Sinon un bruit lointain ne
# produirait qu'un demi-tour et un bruit proche une vraie fouille — une règle que
# le joueur ne peut pas apprendre. Le trajet a donc son propre plafond, qui n'est
# qu'un garde-fou : aucun ennemi ne sait contourner un obstacle.
@export var alert_duration_sight = 6.0   # Fouille sur place après avoir VU le joueur
@export var alert_duration_noise = 3.0   # Fouille sur place après l'avoir seulement ENTENDU
@export var alert_travel_max = 8.0       # Plafond du trajet vers le bruit
var travel_timer = 0.0                   # Temps passé à marcher vers la cible
var search_timer = 0.0                   # Temps passé à fouiller sur place
var alert_from_sight = false             # L'alerte en cours vient-elle d'une vue ?
var investigate_threshold = 10           # Distance (px) à laquelle il se considère arrivé

# Coût de traversée par type de mur, en PIXELS de portée retirés.
# Modèle soustractif (décision du 01/09) : chaque mur mange un montant fixe.
# L'empilement est linéaire : 2 tuiles épaisses = -150, lisible en level design.
var wall_penalties = {
	"epais": 75.0,
	"moyen": 35.0,
	"fin": 15.0
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

		# 2) Le mur atténue : on retire son coût en px.
		#    Le type de mur vient de deux sources différentes selon ce qu'on a touché.
		var type_mur = "moyen"   # valeur de repli si on ne trouve rien

		if impact.collider is TileMapLayer:
			# Cas TILEMAP : le collider est le calque entier, pas une tuile.
			# get_coords_for_body_rid() retrouve QUELLE case a été touchée,
			# à partir de l'identifiant physique (rid) renvoyé par le raycast.
			var coords = impact.collider.get_coords_for_body_rid(impact.rid)
			var donnees_tuile = impact.collider.get_cell_tile_data(coords)
			if donnees_tuile != null:
				type_mur = donnees_tuile.get_custom_data("wall_type")
		elif "wall_type" in impact.collider:
			# Cas OBJET : mur du banc d'essai, container, véhicule...
			type_mur = impact.collider.wall_type

		# Garde-fou : une tuile sans wall_type renseigné passerait en "moyen"
		# sans rien dire. Ici on le signale au lieu de le subir en silence.
		if debug_sound and not type_mur in wall_penalties:
			print(name, " : type de mur INCONNU '", type_mur, "' sur ", impact.collider.name, " -> moyen par defaut")

		reste -= wall_penalties.get(type_mur, 35.0)
		if debug_sound:
			print("   ↳ mur '", type_mur, "' (-", wall_penalties.get(type_mur, 35.0), " px) — reste %.1f px" % reste)

		# Garde-fou : le mur a tout absorbé -> le bruit meurt ici
		if reste <= 0:
			if debug_sound:
				print(name, " : bruit éteint PAR le mur '", type_mur, "'")
			return

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
		# Un bruit neuf relance la recherche depuis zéro : trajet ET fouille.
		travel_timer = 0.0
		search_timer = 0.0
		# Mais il ne RÉTROGRADE pas une alerte visuelle : on ne repasse en durée
		# courte que si l'ennemi patrouillait tranquillement avant ce bruit.
		# Un garde qui t'a vu de ses yeux ne redevient pas un garde qui a cru entendre.
		if current_state == State.PATROL:
			alert_from_sight = false
		current_state = State.ALERT
	elif debug_sound:
		print(name, " : étouffé (reste %.1f px, il en fallait %.1f, %d mur(s))" % [reste, distance_finale, murs_traverses])

func _physics_process(delta):
	match current_state:
		State.PATROL:
			_patrol()
		State.ALERT:
			_investigate(delta)
		State.CHASE:
			_chase_player()

func _investigate(delta):
	if investigation_target == null:
		current_state = State.PATROL
		return

	# BANC D'ESSAI : un ennemi "stationnaire" signale qu'il a entendu (le print est déjà
	# parti) mais ne quitte pas son poste. Ça permet d'enchaîner les tests sans relancer.
	if is_stationary:
		investigation_target = null
		current_state = State.PATROL
		return

	var distance = global_position.distance_to(investigation_target)

	# ===== ARRIVÉ SUR PLACE : il fouille =====
	# Seul endroit où le minuteur de fouille avance. Le joueur voit donc toujours
	# la même durée de fouille, que le bruit ait été proche ou lointain.
	if distance < investigate_threshold:
		velocity = Vector2.ZERO
		search_timer += delta
		var search_limit = alert_duration_sight if alert_from_sight else alert_duration_noise
		if search_timer >= search_limit:
			print(name, " : rien trouve, abandon apres %.2f s de fouille" % search_timer)
			investigation_target = null
			current_state = State.PATROL
		return

	# ===== EN ROUTE : le plafond de trajet court =====
	# Garde-fou pur : il ne sert que si la cible est inatteignable.
	travel_timer += delta
	if travel_timer >= alert_travel_max:
		print(name, " : abandon en route apres %.2f s (reste %.1f px)" % [travel_timer, distance])
		investigation_target = null
		current_state = State.PATROL
		return

	var direction = (investigation_target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _patrol():
	if is_stationary:
		return
	if waypoints.size() == 0:
		return

	var target_pos = waypoints[current_waypoint_index]
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# Waypoint atteint : on passe au suivant (% = retour au début en fin de liste)
	var distance = global_position.distance_to(target_pos)
	if distance < patrol_threshold:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func _chase_player():
	if player == null:
		current_state = State.PATROL
		return

	# En poursuite, l'ennemi court 30% plus vite que sa patrouille
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * (speed * 1.3)
	move_and_slide()

func _on_vision_body_entered(body):
	if body.name == "player":
		player_in_vision = true
		current_state = State.CHASE
		print(name, " : JOUEUR DÉTECTÉ !")

func _on_vision_body_exited(body):
	if body.name == "player":
		player_in_vision = false
		# On fige la dernière position connue : l'ennemi ira LÀ, pas là où le
		# joueur se trouve maintenant. C'est ce qui fait qu'un mur protège.
		investigation_target = body.global_position
		travel_timer = 0.0
		search_timer = 0.0
		alert_from_sight = true
		current_state = State.ALERT
		print(name, " : Joueur perdu de vue -> je vais voir en ", investigation_target)


func take_damage(amount, is_critical = false):
	hp -= amount
	if is_critical:
		print("CRITIQUE sur ", name, " ! -", amount, " HP")
	else:
		print(name, " : -", amount, " HP restants: ", hp)
	if hp <= 0:
		queue_free()
