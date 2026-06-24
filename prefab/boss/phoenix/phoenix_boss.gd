extends CharacterBody2D

@export var speed := 150.0
@export var max_health := 5
@export var left_limit := -800.0
@export var right_limit := 300.0

@export var fireball_scene: PackedScene

var health := max_health
var direction := 1
var is_hurt := false
var is_attacking := false

@onready var anim = $animations/AnimationPlayer
@onready var attack_timer = $AttackTimer
@onready var fireball_spawn = $FireballSpawn

func _ready():
	attack_timer.timeout.connect(_attack)


func _physics_process(delta):

	if !is_hurt and !is_attacking:
		velocity.x = speed * direction

		if position.x >= right_limit:
			direction = -1
		elif position.x <= left_limit:
			direction = 1

		move_and_slide()

		if anim.current_animation != "idle":
			anim.play("idle")


func _attack():
	if is_hurt or is_attacking:
		return

	is_attacking = true
	anim.play("attack1")

	await anim.animation_finished

	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)

	fireball.global_position = fireball_spawn.global_position

	if randf() < 0.5:
		fireball.direction = Vector2.DOWN
	else:
		fireball.direction = Vector2(direction, 0)

	is_attacking = false
	anim.play("idle")


func take_damage():

	if is_hurt:
		return

	health -= 1
	is_hurt = true

	anim.play("hurt")

	await anim.animation_finished

	is_hurt = false

	if health <= 0:
		queue_free()
