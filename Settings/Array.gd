extends VBoxContainer
@export var array_entry: PackedScene
var vector2

func spawn_child():
	var entry = array_entry.instantiate()
	add_child(entry)
	if vector2:
		entry.disable_buttons()
	
func spawn_child_return():
	var entry = array_entry.instantiate()
	add_child(entry)
	if vector2:
		entry.disable_buttons()
	return entry

func fill_placeholders(placeholders):
	if placeholders == []:
		return
	get_child(0).set_placeholder(placeholders[0])
	if placeholders.size() > 1:
		for i in range(placeholders.size()):
			if i == 0:
				pass
			else:
				var new_child = spawn_child_return()
				new_child.set_placeholder(placeholders[i])

func set_vector2():
	vector2 = true
	var children = get_children()
	for child in children:
		child.disable_buttons()
