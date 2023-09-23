extends Control
@export var settings_entry: PackedScene
@onready var container: VBoxContainer = $Container
@onready var settings = get_node(^"../../..")
var settings_entries = []
var config
var category_name

func _ready():
	config = settings.config

func set_category_name(text):
	category_name = text

func add_settings_entry(entry_name, placeholder, tooltip):
	var entry = settings_entry.instantiate()
	container.add_child(entry)
	entry.set_label(entry_name)
	entry.set_placeholder(placeholder)
	entry.set_tooltip(tooltip)
	settings_entries.append({entry_name : ""})
	
func add_settings(entries, animations = false):
	var entry_debug = entries
	if animations:
		for entry in entries:
			for field in entries[entry]:
				add_settings_entry(field, entries[entry][field], field)
	else:
		for entry in entries:
			var placeholder = config.get_value(name, entry[0], "")
			add_settings_entry(entry[0], placeholder, entry[1])

func get_entries():
	var data = []
	var children = container.get_children()
	for child in children:
		data.append(child.get_value())
	return {"category_name" : category_name, "data" : data}
