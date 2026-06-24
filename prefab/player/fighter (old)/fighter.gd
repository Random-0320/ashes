extends CharacterBody2D

const SPEED = 300.0
const RUN_SPEED = 500.0
const JUMP_FORCE = -600.0

const MAX_JUMPS = 2

const ATTACK_RANGE = 120
const ATTACK_DAMAGE = 20

const COMBO_WINDOW = 0.25

const DAMAGE_COOLDOWN = 0.5
const KNOCKBACK = 650
const KNOCKBACK_UP = -250

const ATTACK_TIME = [0.35, 0.45, 0.55]
const ATTACK_HIT = [0.12, 0.15, 0.18]

@export var enemy: CharacterBody2D

@onready var sprite = $AnimatedSprite2D

@export var health = 100
var jumps = MAX_JUMPS

var combo = 0
var combo_timer = 0.0

var is_dead = false
var is_attacking = false
var is_hurt = false
var is_shielding = false

var damage_timer = 0.0
var attack_timer = 0.0
var hit_timer = 0.0

var hit_done = false


func _ready():
	sprite.play("idle")


func _physics_process(delta):

	damage_timer -= delta
	combo_timer -= delta

	if combo_timer <= 0:
		combo = 0

	if !is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps = MAX_JUMPS

	if is_dead:
		move_and_slide()
		return

	if is_hurt:
		move_and_slide()
		return


	if is_attacking:

		velocity.x = 0

		attack_timer -= delta
		hit_timer -= delta

		if hit_timer <= 0 and !hit_done:

			hit_done = true
			do_attack()

		if attack_timer <= 0:
			is_attacking = false

		move_and_slide()
		return


	is_shielding = Input.is_action_pressed(
		"keyboard_s"
	)

	if is_shielding:

		velocity.x = 0

		if sprite.animation != "shield":
			sprite.play("shield")

		move_and_slide()
		return


	if Input.is_action_just_pressed(
		"keyboard_space"
	):
		start_attack()


	if Input.is_action_just_pressed(
		"keyboard_w"
	):

		if jumps > 0:

			jumps -= 1

			velocity.y = JUMP_FORCE


	var direction = Input.get_axis(
		"keyboard_a",
		"keyboard_d"
	)

	if direction != 0:
		sprite.flip_h = direction < 0

	var speed = SPEED

	if Input.is_action_pressed(
		"keyboard_shift"
	):
		speed = RUN_SPEED


	if direction:

		velocity.x = direction * speed

	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			80
		)

	update_animation(direction)

	move_and_slide()


func start_attack():

	if is_attacking:
		return


	if combo_timer <= 0:
		combo = 1
	else:
		combo += 1


	combo = clamp(
		combo,
		1,
		3
	)

	combo_timer = COMBO_WINDOW


	is_attacking = true
	hit_done = false

	velocity.x = 0

	sprite.play(
		"attack_%d"
		% combo
	)

	attack_timer = ATTACK_TIME[
		combo - 1
	]

	hit_timer = ATTACK_HIT[
		combo - 1
	]


func do_attack():

	if enemy == null:
		return


	# diferença entre boss e player
	var dx = (
		enemy.global_position.x
		- global_position.x
	)

	var dy = abs(
		enemy.global_position.y
		- global_position.y
	)


	# alcance horizontal
	if abs(dx) > ATTACK_RANGE:
		return


	# evita acertar inimigos muito acima/abaixo
	if dy > 80:
		return


	# verifica se está atacando para frente
	var enemy_in_front = false


	if sprite.flip_h:

		enemy_in_front = dx < 0

	else:

		enemy_in_front = dx > 0


	if !enemy_in_front:
		return


	var damage = ATTACK_DAMAGE


	match combo:

		1:
			damage = ATTACK_DAMAGE

		2:
			damage = ATTACK_DAMAGE * 1.5

		3:
			damage = ATTACK_DAMAGE * 2


	if enemy.has_method("take_damage"):

		enemy.take_damage(
			int(damage)
		)

		print(
			"Hit:",
			int(damage)
		)


func take_damage(amount = 10):

	if is_dead:
		return

	if damage_timer > 0:
		return

	# tomar dano quebra combo
	combo = 0
	combo_timer = 0

	if is_shielding and enemy:

		var dx = (
			enemy.global_position.x
			-
			global_position.x
		)

		var frontal = (
			dx > 0
			and !sprite.flip_h
		) or (
			dx < 0
			and sprite.flip_h
		)

		if frontal:
			return

	damage_timer = DAMAGE_COOLDOWN

	health -= amount
	print("Hp Fighter:", health)

	if health <= 0:
		die()
		return

	is_hurt = true

	# 🛡️ CORREÇÃO DO CRASH: Só calcula knockback se o inimigo existir de verdade!
	if enemy != null:
		var knock = sign(
			global_position.x
			-
			enemy.global_position.x
		)

		velocity.x = (
			knock
			*
			KNOCKBACK
		)
	else:
		# Se não houver inimigo definido, empurra baseado para onde o Samurai está olhando
		var knock = 1 if sprite.flip_h else -1
		velocity.x = knock * KNOCKBACK

	velocity.y = KNOCKBACK_UP

	sprite.play(
		"hurt"
	)

	await get_tree().create_timer(
		0.15
	).timeout

	if !is_dead:
		is_hurt = false

	await get_tree().create_timer(
		0.15
	).timeout


	if !is_dead:
		is_hurt = false


func update_animation(direction):

	if is_dead or is_attacking:
		return

	if is_hurt:

		sprite.play(
			"hurt"
		)

	elif !is_on_floor():

		sprite.play(
			"jump"
		)

	elif direction == 0:

		sprite.play(
			"idle"
		)

	else:

		if Input.is_action_pressed(
			"keyboard_shift"
		):

			sprite.play(
				"run"
			)

		else:

			sprite.play(
				"walk"
			)


func die():

	is_dead = true

	sprite.play(
		"dead"
	)
	get_tree().change_scene_to_file("res://levels/scorpion/scorpion_level.tscn")
	await sprite.animation_finished

	queue_free()


# ⚔️ NOVA FUNÇÃO: GERENCIA A COLISÃO COM A BOLA DE FOGO
func handle_wyvernball_collision(wyvernball):
	if is_dead:
		return
		
	# Verifica se o jogador está defendendo de fato
	if is_shielding:
		# Descobre se a bola de fogo veio pela frente do Samurai
		var dx = wyvernball.global_position.x - global_position.x
		var frontal = (dx > 0 and !sprite.flip_h) or (dx < 0 and sprite.flip_h)
		
		if frontal:
			print("--- BOLA DE FOGO REFLETIDA! ---")
			# 1. Inverte completamente o vetor de movimento da bola de fogo
			wyvernball.velocity_vector = -wyvernball.velocity_vector
			
			# 2. Atualiza a rotação e visual da bola de fogo para o novo sentido
			if wyvernball.has_method("update_direction_visual"):
				wyvernball.update_direction_visual()
			return # Sai da função sem tomar dano!

	# Se não estava defendendo ou foi pelas costas, toma dano normal da bola
	take_damage(25) # Defina a quantidade de dano que a bola causa aqui
	wyvernball.queue_free() # Destrói a bola de fogo após atingir o corpo do player
