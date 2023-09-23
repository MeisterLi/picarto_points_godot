extends Control

@export var settings_category: PackedScene
@onready var box = $ScrollContainer/VBoxContainer
@onready var tabBar : TabBar = $TabsContainer/TabBar
@onready var settingsData = $SettingsData
@onready var animationData = $AnimationsData
@onready var title = $HBoxContainer/Label
var spawned_categories = []
var config = ConfigFile.new()
var _json = JSON.new()
var animations
var settings_type
var categories
var setting_node
var current_category
signal settings_exit

func start():
	if settings_type == "config":
		title.set_text("Settings")
		$TabsContainer/NewAnimationButton.hide()
		$TabsContainer/ChangeAnimationNameButton.hide()
		$TabsContainer/Label.hide()
		config.load(settingsData.config_file)
		categories = settingsData.categories
		setting_node = settingsData
	elif settings_type == "animation":
		title.set_text("Animations")
		$TabsContainer/NewAnimationButton.show()
		$TabsContainer/ChangeAnimationNameButton.show()
		$TabsContainer/Label.show()
		categories = animationData.categories
		var file = FileAccess.open(settingsData.config_file, FileAccess.READ)
		var contents = file.get_as_text()
		animations = _json.parse_string(contents)
		setting_node = animationData
		file.close()
	add_categories()

func add_categories():
	for key in categories:
		current_category = 0
		var entry = settings_category.instantiate()
		box.add_child(entry)
		if settings_type == "animation":
			if key != categories[0]:
				entry.hide()
			entry.set_category_name(key.keys()[0])
			entry.set_name(key.keys()[0])
			add_tab(key.keys()[0])
			entry.add_settings(key, true)
			spawned_categories.append(entry)
		elif settings_type == "config":
			if categories.keys()[0] != key:
				entry.hide()
			entry.set_category_name(key)
			entry.set_name(key)
			add_tab(key)
			entry.add_settings(categories[key])
			spawned_categories.append(entry)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_tab(category):
	tabBar.add_tab(category)

func _on_save_button_pressed():
	setting_node.save(spawned_categories)

func _on_tab_bar_tab_changed(tab):
	if settings_type == "config":
		change_to_tab_contents(categories.keys()[tab])
	else:
		var category_entries = categories
		var category_keys = categories[tab].keys()[0]
		change_to_tab_contents(categories[tab].keys()[0])

func change_to_tab_contents(tab):
	for category in spawned_categories:
		if category.get_name() != tab:
			category.hide()
		else:
			category.show()
			current_category = tab

func _on_settings_data_loaded():
	config = $SettingsData.config
	add_categories()

func _on_button_pressed():
	var animation_name = $TabsContainer/Label.get_text()
	var animation = {animation_name : {
		"file" : [],
		"coordinates" : [0, 0],
		"scale" : [1.0, 1.0],
		"trigger" : "!" + animation_name,
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
	var entry = settings_category.instantiate()
	box.add_child(entry)
	entry.hide()
	entry.set_category_name(animation_name)
	entry.set_name(animation_name)
	add_tab(animation_name)
	entry.add_settings(animation, true)
	spawned_categories.append(entry)
	categories.append(animation)

func _on_change_animation_name_button_pressed():
	var animation_name = $TabsContainer/Label.get_text()
	spawned_categories[current_category].set_category_name(animation_name)
	tabBar.set_tab_title(current_category, animation_name)

func _on_exit_button_pressed():
	settings_exit.emit()
