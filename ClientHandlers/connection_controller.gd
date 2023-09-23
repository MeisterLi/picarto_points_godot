extends Node

@onready var picarto_handler = $PicartoHandler
@onready var obs_handler = $obs_handler

func _on_picarto_handler_hide_friend(friend_name, remove):
	obs_handler.hide_friend(friend_name, remove)

func _on_picarto_handler_show_friend(friend_name, remove):
	obs_handler.show_friend(friend_name, remove)

func _on_picarto_handler_update_scroll_text(result):
	obs_handler.update_scroll_text(result)

func _on_picarto_handler_trigger_animation(animation, message_author):
	obs_handler.spawn_animation(animation, message_author)

func _on_obs_handler_connected():
	$Label.set_text($Label.get_text() + "OBS connected! \n")

func _on_picarto_handler_connected():
	$Label.set_text($Label.get_text() + "Picarto connected! \n")
