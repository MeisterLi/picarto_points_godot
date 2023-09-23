extends Node

var obs_settings = [
	["host", "IP of the Computer running OBS"],
	["port", "Port of the Computer running OBS"],
	["password", "Password for the OBS Websocket"],
	["animation_scene", "Name of the Scene to play Animations in"],
	["ticker_scene", "Name of the Scene the Ticker is in"],
	["friend_scene", "Name of the Scene friends are placed in"],
	["canvas_width", "Width of the OBS canvas"],
	["canvas_height", "Height of the OBS canvas"],
	["points_display_time", "Time to show the Ticker in OBS for"],
	["points_display_interval", "Time to hide the Ticker in OBS for"],
	["fade_text_field", "Should the Ticker be hidden occasionally or show at all times?"]
	]
var picarto_settings = [
	["channel_owner", "Picarto Channel Owner"],
	["channel_auth", "Picarto Chat Bot Token"],
	["granters", "Chatters who are able to grant points via command"],
	["friends", "Friends who's scene objects get enabled/disabled when they join or leave"]
]
var twitch_settings = [
	["user_name", "User Name for Twitch"]
]
var point_settings = [
	["base", "Base amount of points to grant per interval"],
	["boosted", "Base amount of points to grant per interval"],
	["frequency", "Frequency in Seconds to award points at"]
]
var web_settings = [
	["url", "Url to connect for website point display"],
	["key", "Key to authorize for website updates"]
]
var bool_type = [
	"fade_text_field"
]
var array_type = [
	"friends",
	"granters"
]
var vector2_type = []
var categories = {"obs" : obs_settings, "picarto" : picarto_settings, "twitch" : twitch_settings, "points" : point_settings, "web" : web_settings}
var config_file = "user://config.ini"
var config = ConfigFile.new()

func save(spawned_categories):
	var data_to_save = {}
	var all_settings = []
	for category in spawned_categories:
		all_settings.append(category.get_entries())
	for setting in all_settings:
		for entry in setting["data"]:
			config.set_value(setting['category_name'], entry[0], entry[1])
	var err = config.save(config_file)
	if err != OK:
		print(err)
