# ============================================================
# sound_manager.gd — le standard téléphonique du bruit
# Autoload "SoundManager" : n'importe quel script peut déclarer
# un bruit via generate_noise(), et le signal est relayé à tous
# les abonnés (les ennemis s'y branchent dans enemy.gd).
# ============================================================
extends Node

# Émis à chaque bruit : position dans le monde + intensité (0-150)
signal noise_emitted(position: Vector2, intensity: float)

# Repères d'intensité actuellement utilisés dans le jeu :
#   45 = marche lente    80 = marche normale / tir    150 = sprint
#   50 = attaque au corps à corps    40 = impact de balle
func generate_noise(pos: Vector2, intensity: float):
	print("Bruit généré : ", intensity, " à ", pos)   # DEBUG : à retirer plus tard
	noise_emitted.emit(pos, intensity)
