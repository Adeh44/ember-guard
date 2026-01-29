extends CharacterBody2D

# Stats
var hp = 50
var speed = 60.0  # Vitesse de patrouille

# IA Patrouille
var waypoints = []  # Liste des positions à patrouiller
var current_waypoint_index = 0  # Index du waypoint actuel
var patrol_threshold = 10.0  # Distance pour considérer waypoint atteint

# IA États
enum State { PATROL, ALERT, CHASE }
var current_state = State.PATROL

# Détection
var player = null  # Référence au joueur
var player_in_vision = false
@onready var vision_cone = $vision_cone

func _ready():
	# ... (code waypoints existant)
	
	# Connecter détection vision
	if vision_cone != null:
		vision_cone.body_entered.connect(_on_vision_body_entered)
		vision_cone.body_exited.connect(_on_vision_body_exited)
	
	# Trouver le joueur
	player = get_tree().get_first_node_in_group("player")
	if waypoints_group != null:
		for child in waypoints_group.get_children():
			waypoints.append(child.global_position)
		print(name, " : ", waypoints.size(), " waypoints trouvés")
	else:
		print(name, " : ERREUR - Aucun groupe waypoints trouvé !")

func _physics_process(_delta):
	match current_state:
		State.PATROL:
			_patrol()
		State.CHASE:
			_chase_player()

func _patrol():
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
	velocity = direction * (speed * 1.5)  # Plus rapide en poursuite
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
		
		
# Fonction existante (conserver)
func take_damage(amount, is_critical = false):
	hp -= amount
	
	if is_critical:
		print("COUP CRITIQUE sur ", name, " ! Dégâts : ", amount)
	else:
		print(name, " subit ", amount, " dégâts. HP restants : ", hp)
	
	if hp <= 0:
		queue_free()
