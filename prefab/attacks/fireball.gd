extends Area2D

@export var speed := 300.0

var direction = Vector2.DOWN
var reflected = false

func _process(delta):
	position += direction.normalized() * speed * delta

func reflect():

	if reflected:
		return

	reflected = true

	# volta para cima
	direction = Vector2.UP

func _on_body_entered(body):

	# Se acertar a fênix após refletir
	if reflected and body.has_method("take_damage"):
		body.take_damage()
		queue_free()
