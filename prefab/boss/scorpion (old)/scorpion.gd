extends CharacterBody2D

const SPEED = 160.0
const MAX_HP = 100

const ATTACK_RANGE_X = 120.0
const ATTACK_RANGE_Y = 60.0
const ATTACK2_RANGE_Y = 200.0

const ATTACK1_DAMAGE = 20
const ATTACK2_DAMAGE = 100

const ATTACK_COOLDOWN = 1.7

const INVUL_TIME = 0.35
const HURT_TIME = 0.20

const KNOCKBACK = 240.0
const KNOCKBACK_DECAY = 1400.0

const TURN_THRESHOLD = 25.0
const TOP_ATTACK_HEIGHT = 35.0


@export var player: CharacterBody2D

@onready var sprite = $AnimatedSprite2D


@export var hp = MAX_HP

var is_dead = false
var is_attacking = false
var is_hurt = false

var attack_cd = 0.0
var hurt_timer = 0.0
var invul = 0.0

var current_attack = 1
var hit_delay = -1.0
var hit_done = false

var facing = 1


func _ready():
	randomize()
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")


func _physics_process(delta):

	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_cd = max(attack_cd - delta, 0.0)
	invul = max(invul - delta, 0.0)

	if is_dead:
		move_and_slide()
		return


	if is_hurt:

		hurt_timer -= delta

		velocity.x = move_toward(
			velocity.x,
			0.0,
			KNOCKBACK_DECAY * delta
		)

		if sprite.animation != "hurt":
			sprite.play("hurt")

		if hurt_timer <= 0:
			is_hurt = false

			if not is_dead:
				sprite.play("idle")

		move_and_slide()
		return


	if player == null:

		velocity.x = 0

		if sprite.animation != "idle":
			sprite.play("idle")

		move_and_slide()

		return


	var dx = player.global_position.x - global_position.x
	var dy = player.global_position.y - global_position.y

	var distance_x = abs(dx)
	var distance_y = abs(dy)


	if abs(dx) > TURN_THRESHOLD:

		facing = sign(dx)

		if facing == 0:
			facing = 1


	sprite.flip_h = facing > 0


	var player_above = (
		dy < -TOP_ATTACK_HEIGHT
		and distance_x < ATTACK_RANGE_X
	)


	if player_above and not is_attacking and not is_hurt:
		force_attack_2()


	if is_attacking:

		velocity.x = 0

		if hit_delay > 0:

			hit_delay -= delta

			if hit_delay <= 0:
				do_attack()

		move_and_slide()

		return


	var can_attack = (
		distance_x <= ATTACK_RANGE_X
		and distance_y <= ATTACK_RANGE_Y
	)


	if can_attack:

		velocity.x = 0

		if attack_cd <= 0:
			start_attack()

	else:

		velocity.x = facing * SPEED

		if sprite.animation != "idle":
			sprite.play("idle")


	move_and_slide()


func start_attack():

	if is_attacking or is_hurt or is_dead:
		return


	is_attacking = true
	hit_done = false

	attack_cd = ATTACK_COOLDOWN


	if randf() < 0.75:

		current_attack = 1

		hit_delay = 0.12

		sprite.play("attack_1")

	else:

		current_attack = 2

		hit_delay = 0.18

		sprite.play("attack_2")


func force_attack_2():

	is_attacking = true

	current_attack = 2

	hit_done = false

	hit_delay = 0.05

	attack_cd = 0.5

	velocity.x = 0

	sprite.play("attack_2")


func do_attack():

	if hit_done:
		return

	hit_done = true

	if player == null:
		return


	var dx = abs(
		player.global_position.x
		-
		global_position.x
	)

	var dy = abs(
		player.global_position.y
		-
		global_position.y
	)


	var range_y = ATTACK_RANGE_Y

	if current_attack == 2:
		range_y = ATTACK2_RANGE_Y


	if dx > ATTACK_RANGE_X:
		return

	if dy > range_y:
		return


	var damage = ATTACK1_DAMAGE

	if current_attack == 2:
		damage = ATTACK2_DAMAGE


	if player.has_method("take_damage"):
		player.take_damage(damage)


func take_damage(dmg):

	if is_dead:
		return

	if invul > 0:
		return

	if is_hurt:
		return


	invul = INVUL_TIME

	hp -= dmg


	if hp <= 0:
		get_tree().change_scene_to_file("res://levels/wyvern/wyvern_level.tscn")
		die()
		return


	is_attacking = false

	hit_done = false

	hit_delay = -1

	is_hurt = true

	hurt_timer = HURT_TIME


	if player:

		velocity.x = (
			sign(
				global_position.x
				-
				player.global_position.x
			)
			*
			KNOCKBACK
		)


	sprite.play("hurt")


func die():

	if is_dead:
		return


	
	is_dead = true

	is_hurt = false

	is_attacking = false

	velocity = Vector2.ZERO

	sprite.play("dead")


func _on_animation_finished():

	if is_dead:

		if sprite.animation == "dead":
			queue_free()

		return


	match sprite.animation:

		"attack_1", "attack_2":

			is_attacking = false

			hit_delay = -1

			sprite.play("idle")

		"hurt":

			is_hurt = false

			sprite.play("idle")
			
