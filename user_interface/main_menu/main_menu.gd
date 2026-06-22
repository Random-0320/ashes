extends Node2D

func _ready() -> void:
	$first.show()
	$second.hide()
	$third.hide()
	$Button_Manager.hide()
	$fade_transition.show()
	$fade_transition/first_timer.start()
	$fade_transition/second_timer.start()
	$fade_transition/third_timer.start()
	$fade_transition/fourth_timer.start()
	$fade_transition/fifth_timer.start()
	$fade_transition/animation_player.play("fade_in")
	
func _on_first_timer_timeout():
	$fade_transition/animation_player.play("fade_out")
	
func _on_second_timer_timeout():
	$fade_transition/animation_player.play("fade_in")
	$first.hide()
	$second.show()
	
func _on_third_timer_timeout():
	$fade_transition/animation_player.play("fade_out")
	
func _on_fourth_timer_timeout():
	$fade_transition/animation_player.play("fade_in")
	$second.hide()
	$third.show()
	$Button_Manager.show()

func _on_fifth_timer_timeout():
	$fade_transition.hide()
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Scorpion_Stage.tscn")

func _on_button_2_pressed() -> void:
	pass # Replace with function body.
	get_tree().quit()
