extends Control
var connection_controller : PackedScene = preload("res://ClientHandlers/connection_controller.tscn")

func _on_settings_button_pressed():
	get_parent().open_settings()
	hide()
	
func set_label(text):
	$HBox/Label.set_text(text)

func show_modes():
	$HBox/ModeSelect.show()


func _on_animation_settings_button_pressed():
	get_parent().open_animation_settings()
	hide()

func _on_picarto_button_pressed():
	hide()
	var controller = connection_controller.instantiate()
	$/root/Main.add_child(controller)
