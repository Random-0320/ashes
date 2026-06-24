extends CharacterBody2D

# Adicione uma variável de vida no topo do script do Boss se já não tiver, ex:
@export var speed := 150.0
@export var left_limit := -2400.0
@export var right_limit := 300.0
@export var max_health := 250
@onready var health := max_health

# Arraste o nó da barra de vida para cá no Inspector, ou use o caminho direto:
@onready var health_bar = get_node("/root/BossUI/BossHealthBar") # <-- AJUSTE O CAMINHO CONFORME O NOME DA SUA CENA!
func _ready():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.show() # Garante que a barra apareça
# ADICIONE essa linha lá em cima no script do Boss, junto com as outras variáveis exportadas:
@export var launch_angle_degrees := 30.0 # Altere esse valor no Inspector para mudar a inclinação!

@export var fireball_scene: PackedScene
@export var attack_cooldown := 1.5

var direction := 1
var can_attack := true
var is_attacking := false

@onready var anim = $animations/AnimationPlayer
@onready var fireball_spawn = $FireballSpawn


func _physics_process(delta):

	if !is_attacking:
		velocity.x = speed * direction

		if position.x >= right_limit:
			direction = -1
		elif position.x <= left_limit:
			direction = 1

		move_and_slide()

		# 🛡️ CORREÇÃO AQUI: Só volta para o idle se ele NÃO estiver atacando e a animação atual não for "hurt"
		if anim.current_animation != "idle" and anim.current_animation != "hurt":
			anim.play("idle")

	# Se ele estiver atacando, ainda precisamos processar a física (como gravidade se houver, ou apenas manter parado)
	else:
		velocity.x = 0
		move_and_slide()

	_try_attack()


# 🔥 ATAQUE SEM TIMER NODE
func _try_attack():
	if is_attacking:
		return
	if !can_attack:
		return

	# chance simples por frame
	if randf() < 0.02:
		_attack()


func _attack():
	is_attacking = true
	can_attack = false

	anim.play("attack_1")

	var fireball = fireball_scene.instantiate()
	
	# 1. Define a posição inicial no Spawn
	fireball.global_position = fireball_spawn.global_position
	
	# 2. Converte o ângulo do Inspector para Radianos
	var angulo_rad = deg_to_rad(launch_angle_degrees)
	
	# 3. CONSTRUÇÃO DO VETOR PELO ÂNGULO REAL:
	var angulo_final := 0.0
	if direction > 0:
		# Se vai para a direita (0 radianos), adiciona ou subtrai o ângulo
		angulo_final = angulo_rad
	else:
		# Se vai para a esquerda (PI radianos = 180°), inverte o ângulo para espelhar
		angulo_final = PI - angulo_rad

	# Cria o vetor de movimento perfeito a partir do ângulo final gerado
	var direcao_final = Vector2.from_angle(angulo_final)

	# 4. Passa o vetor para a bola de fogo
# Substitua a linha do erro por esta (ela tenta definir no nó pai e, se não achar, define na Area2D)
	if "velocity_vector" in fireball:
		fireball.velocity_vector = direcao_final
	elif fireball.has_node("Area2D") and "velocity_vector" in fireball.get_node("Area2D"):
		fireball.get_node("Area2D").velocity_vector = direcao_final

# 5. Adiciona na cena do jogo
	get_tree().current_scene.add_child(fireball)

	#ESPERA A ANIMAÇÃO DE ATAQUE ACABAR ANTES DE VOLTAR PRO IDLE
	if anim.has_animation("attack_1"):
		await anim.animation_finished

	is_attacking = false
	anim.play("idle")

	# O cooldown roda aqui em segundo plano, sem travar as animações do Boss
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
func take_damage(amount: int):
	health -= amount
	print("HP do Boss: ", health)
	
	# 🔴 ATUALIZA A BARRA DE VIDA NA TELA!
	if health_bar:
		health_bar.value = health
		
	# Se o boss morrer, esconde a barra e remove o Boss
	if health <= 0:
		print("Boss derrotado!")
		if health_bar:
			health_bar.hide() # Some com a barra de vida da tela
		queue_free() 
		return
		
	# Trava o movimento para sentir dor
	is_attacking = true
	velocity.x = 0 
	
	if anim.has_animation("hurt"):
		anim.play("hurt")
	
	await get_tree().create_timer(0.2).timeout
	
	is_attacking = false
	anim.play("idle")
