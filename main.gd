extends Node
var config = ConfigFile.new()
var config_present = true
@onready var splash = $Splash

# Called when the node enters the scene tree for the first time.
func _ready():
	var err = config.load("user://config.ini")
	if err != OK:
		config_present = false
		splash.set_label("Configuration empty! Click below to open Settings.")
	else:
		splash.set_label("Press Twitch or Picarto to start!")
		splash.show_modes()

func open_settings():
	$Settings.settings_type = "config"
	$Settings.start()
	$Settings.show()

func open_animation_settings():
	$Settings.settings_type = "animation"
	$Settings.start()
	$Settings.show()

func _on_settings_settings_exit():
	$Settings.hide()
	$Settings.close()
	$Splash.show()
