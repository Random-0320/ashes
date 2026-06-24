extends Area2D

@export var speed := 300.0
var velocity_vector := Vector2.RIGHT

# TRAVA DE SEGURANÇA e controle de quem pode tomar dano
var foi_refletida := false

func _ready():
	update_direction_visual()

func _process(delta):
	# Move a bola de fogo
	global_position += velocity_vector * speed * delta
	
	var corpos = get_overlapping_bodies()
	for body in corpos:
		# Se a bola já foi rebatida pelo Samurai e encostar no Boss...
		if foi_refletida and body.has_method("take_damage") and body != owner:
			# Evita que ela dê dano no próprio Samurai na volta, checando o nome ou tipo do Boss
			if "Boss" in body.name or body.is_in_group("boss") or body.has_node("WyvernballSpawn"):
				print("--- BOLA DE FOGO ACERTOU O BOSS! ---")
				body.take_damage(50) # Defina aqui o dano que o Boss leva ao ser atingido pela própria bola
				queue_free() # Destrói a bola de fogo
				return

		# Lógica normal de colisão com o Samurai (só se não tiver sido refletida no mesmo frame)
		if not foi_refletida and body is CharacterBody2D and body.has_method("handle_wyvernball_collision"):
			_processa_colisao(body)
			break

func update_direction_visual():
	if velocity_vector != Vector2.ZERO:
		rotation = velocity_vector.angle()
	
	if velocity_vector.x < 0:
		scale.y = -1
	else:
		scale.y = 1

func _processa_colisao(body):
	if body.has_method("handle_wyvernball_collision"):
		if body.is_shielding:
			foi_refletida = true
			body.handle_wyvernball_collision(self)
			
			# Mantemos um pequeno tempo para ela se afastar do Samurai,
			# mas ela continuará como 'foi_refletida = true' para sempre até sumir ou bater no Boss
			await get_tree().create_timer(0.15).timeout
		else:
			body.handle_wyvernball_collision(self)


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
