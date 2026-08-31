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

# Détection sonore
@export var sound_detection_range = 105
var investigation_target = null

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
	
	player = get_tree().get_first_node_in_group("player")
	SoundManager.noise_emitted.connect(_on_noise_detected)

func _on_noise_detected(noise_pos: Vector2, intensity: float):
	# v0.20 FIX : Ignorer bruit si déjà en poursuite
	if current_state == State.CHASE:
		return
	
	var distance = global_position.distance_to(noise_pos)
	if distance < sound_detection_range:
		var effective_range = sound_detection_range * (intensity / 100.0)
		if distance < effective_range:
			print(name, " : Bruit entendu ! Investigation...")
			investigation_target = noise_pos
			current_state = State.ALERT

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
	
	var direction = (investigation_target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	var distance = global_position.distance_to(investigation_target)
	if distance < 10 :
		print(name, " : Rien trouvé, retour patrouille")
		investigation_target = null
		current_state = State.PATROL

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
