extends CharacterBody2D

# Stats
var hp = 50
var speed = 60.0  # Vitesse de patrouille

# IA Patrouille
var waypoints = []  # Liste des positions à patrouiller
var current_waypoint_index = 0  # Index du waypoint actuel
var patrol_threshold = 10.0  # Distance pour considérer waypoint atteint

func _ready():
	# Récupérer tous les waypoints dans la scène
	var waypoints_group = get_tree().get_first_node_in_group("waypoints")
	if waypoints_group == null:
		# Fallback : chercher parent "waypoints_group" dans la scène
		waypoints_group = get_node_or_null("/root/TestLevel/waypoints_group")
	
	if waypoints_group != null:
		for child in waypoints_group.get_children():
			waypoints.append(child.global_position)
		print(name, " : ", waypoints.size(), " waypoints trouvés")
	else:
		print(name, " : ERREUR - Aucun groupe waypoints trouvé !")

func _physics_process(_delta):
	if waypoints.size() == 0:
		return  # Pas de waypoints, reste immobile
	
	# Obtenir position du waypoint cible
	var target_pos = waypoints[current_waypoint_index]
	
	# Calculer direction vers le waypoint
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	
	# Déplacer
	move_and_slide()
	
	# Vérifier si waypoint atteint
	var distance = global_position.distance_to(target_pos)
	if distance < patrol_threshold:
		# Passer au waypoint suivant
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

# Fonction existante (conserver)
func take_damage(amount, is_critical = false):
	hp -= amount
	
	if is_critical:
		print("COUP CRITIQUE sur ", name, " ! Dégâts : ", amount)
	else:
		print(name, " subit ", amount, " dégâts. HP restants : ", hp)
	
	if hp <= 0:
		queue_free()
