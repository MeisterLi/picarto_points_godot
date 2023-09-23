extends BoxContainer

@onready var line_edit: LineEdit = $LineEdit

func _ready():
	if get_parent().get_children().size() == 1:
		$RemoveEntryButton.hide()

func spawn_new():
	get_parent().spawn_child()

func _on_add_entry_button_pressed():
	spawn_new()

func get_value():
	if line_edit.get_text() == "":
		if line_edit.get_placeholder() == "":
			pass
		else:
			return line_edit.get_placeholder()
	else:
		return line_edit.get_text()

func _on_remove_entry_button_pressed():
	queue_free()
	
func set_tooltip(text):
	line_edit.set_tooltip_text(text)
	
func set_placeholder(text):
	line_edit.set_placeholder(str(text))
	
func disable_buttons():
	$RemoveEntryButton.hide()
	$AddEntryButton.hide()
