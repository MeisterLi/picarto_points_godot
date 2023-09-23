extends HBoxContainer

var label
var placeholder
var entry_type = ""
@onready var array_node: VBoxContainer = $BoxContainer/Array
@onready var input_node: LineEdit = $BoxContainer/LineEdit
@onready var checkbox_node: CheckBox = $BoxContainer/CheckBox
@onready var settings = get_node(^"../../../../..").setting_node

func set_label(text):
	$Label.set_text(text)
	label = text
	if label in settings.array_type:
		entry_type = "array"
		array_node.show()
		input_node.hide()
		checkbox_node.hide()
		
	elif label in settings.bool_type:
		entry_type = "bool"
		array_node.hide()
		input_node.hide()
		checkbox_node.show()
	
	elif label in settings.vector2_type:
		entry_type = "array"
		array_node.show()
		array_node.set_vector2()
		input_node.hide()
		checkbox_node.hide()

func set_placeholder(text):
	placeholder = text
	if text is bool:
		checkbox_node.set_pressed(text)
	elif text is Array:
		array_node.fill_placeholders(text)
	else:
		input_node.set_placeholder(str(text))

func set_tooltip(text):
	$BoxContainer/Array/ArrayEntry.set_tooltip(text)
	$BoxContainer/CheckBox.set_tooltip_text(text)
	$BoxContainer/LineEdit.set_tooltip_text(text)
	
func get_value():
	var returnValue
	match entry_type:
		"":
			if input_node.get_text() == "":
				returnValue = placeholder
			else:
				returnValue = input_node.get_text()
			return [label, returnValue]
		"array":
			var settings_array = []
			var all_entries = array_node.get_children()
			for entry in all_entries:
				settings_array.append(entry.get_value())
			return [label, settings_array]
		"bool":
			return [label, checkbox_node.is_pressed()]
