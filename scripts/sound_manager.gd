extends Node

# Signal émis quand un bruit est généré
signal noise_emitted(position: Vector2, intensity: float)

func generate_noise(pos: Vector2, intensity: float):
	# Intensité : 0-100
	# 10 = pas discrets
	# 50 = attaque CàC
	# 80 = tir arme
	print("Bruit généré : ", intensity, " à ", pos)
	noise_emitted.emit(pos, intensity)
