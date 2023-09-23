extends Node

var config_file = "user://animations.json"
var _json = JSON.new()
var animations
var categories = []
var array_type = ["file"]
var bool_type = ["random_position", "random_rotation", "fade", "static"]
var vector2_type = ["coordinates", "scale", "random_scale"]
var animation = {"sample_animation" : {
		"file" : [],
		"coordinates" : [0, 0],
		"scale" : [1.0, 1.0],
		"trigger" : "!" + "sample_animation",
		"price" : 20,
		"random_position" : false,
		"random_rotation" : false,
		"random_scale" : [1, 1],
		"fade" : true,
		"static" : true,
		"fade_time" : 3,
		"volume" : -12,
		"rare_file" : "",
		"rare_chance" : 0
	}}

func _ready():
	if FileAccess.file_exists(config_file):
		var file = FileAccess.open(config_file, FileAccess.READ)
		var contents = file.get_as_text()
		animations = _json.parse_string(contents)
		file.close()
		for animation in animations:
			categories.append({animation : animations.get(animation)})
	else:
		categories.append(animation)

func save(spawned_categories):
	var data_to_save = {}
	var all_settings = []
	for category in spawned_categories:
		all_settings.append(category.get_entries())
	for setting in all_settings:
		var data = {}
		for data_entry in setting.get("data"):
			var data_string = data_entry[0]
			data.merge({data_entry[0] : data_entry[1]})
		var entry = {setting.get("category_name") : data}
		data_to_save.merge(entry)
	var file = FileAccess.open(config_file, FileAccess.WRITE)
	file.store_string(_json.stringify(data_to_save))
	file.close()
