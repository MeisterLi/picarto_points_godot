extends Node
@export var websocket: PackedScene
var config = ConfigFile.new()
var uuid_util = preload("res://addons/uuid.gd")
@onready var connector
var identified = false
var running_requests = []
var responses = []
var dont_keep_response = []
const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
var animations
var ticker_display_time
var ticker_scene
var ticker_wait_time
var ticker_id

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = FileAccess.open("user://animations.json", FileAccess.READ)
	var contents = file.get_as_text()
	file.close()
	var _json = JSON.new()
	animations = _json.parse_string(contents)
	var err = config.load("user://config.ini")
	connector = websocket.instantiate()
	add_child(connector)
	connector.set_url(config.get_value("obs", "host"))
	connector.set_port(config.get_value("obs", "port"))
	var singal_err = get_node("Websocket").connect("connected", send_command)
	if singal_err != OK:
		print(singal_err)
	connector.start()
	ticker_display_time = int(config.get_value("obs", "points_display_time"))
	ticker_scene = config.get_value("obs", "ticker_scene")
	ticker_wait_time = int(config.get_value("obs", "points_display_interval"))

# handling incoming messages as well as identify step
func on_received_data(packet):
	if packet["op"] == 0:
		print("Handshake successful")
		var identify = {'op': 1, 'd' : {"rpcVersion": 1}}
		connector.send(str(identify).to_utf8_buffer())
	elif packet['op'] == 2:
		identified = true
		setup()
	elif packet['op'] == 7:
		check_for_success(packet)

func check_for_success(packet):
	var uuid = packet['d']['requestId']
	if uuid in running_requests:
		running_requests.erase(uuid)
		if uuid not in dont_keep_response:
			responses.append({"uuid" : uuid, "response" : packet})
		else:
			dont_keep_response.erase(uuid)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func setup():
	ticker_id = await get_scene_item_id(ticker_scene, "Ticker")
	$text_loop_wait.start(ticker_wait_time)
	
func send_animations(animation_name, spawner_name):
	spawn_animation(animation_name, spawner_name)

# actual requests to send to OBS	
func change_text(inputName, text):
	set_input_settings(inputName, {'text' : text})

func spawn_animation(selected_animation, spawning_user):
	var file = animations[selected_animation]['file']
	if file is Array:
		for entry in file:
			if animations[selected_animation]['file'].find(entry) == 0:
				var final_file = determine_shiney(selected_animation)
				spawn_media(selected_animation, spawning_user, final_file)
			else:
				spawn_media(selected_animation, spawning_user, entry, true)
	else:
		var final_file = determine_shiney(selected_animation)
		spawn_media(selected_animation, spawning_user, final_file)

func spawn_media(selected_animation, spawning_user, file, override_fade = false):
	await spawn_media_node(spawning_user, file, selected_animation, override_fade)

func spawn_media_node(spawning_user, final_file, selected_animation, override_fade):
	var looping = determine_looping_behavior(selected_animation, final_file)
	var scene_name = config.get_value("obs", "animation_scene")
	var random_string = get_random_string(8)
	var scene_item_name = "{spawning_user}_{selected_animation}_{random_string}".format({"spawning_user" : spawning_user, "selected_animation" :  selected_animation, "random_string" : random_string})
	var requestData = {
			"sceneName": scene_name,
			"inputName": scene_item_name,
			"inputKind": "ffmpeg_source",
			"inputSettings": {"hw_decode": true, "local_file": final_file, "looping": looping},
			"sceneItemEnabled" : false
		}
	var uuid = send_scene_command('CreateInput', requestData, false)
	await wait_for_completed_command(uuid)
	var scene_item_id = await get_scene_item_id(scene_name, scene_item_name)
	update_scene_item_transform(scene_item_id, scene_item_name, selected_animation, override_fade)

func update_scene_item_transform(scene_item_id, scene_item_name, animation_name, override_fade):
	var command = "SetSceneItemTransform"
	var scene_name = config.get_value("obs", "animation_scene")
	var final_position = determine_final_position(animations[animation_name]["coordinates"], animations[animation_name]["random_position"])
	var final_position_x = final_position[0]
	var final_position_y = final_position[1]
	var final_rotation = determine_final_rotation(0.0, animations[animation_name]["random_rotation"])
	var final_scale = determine_final_scale(animations[animation_name]['scale'], animations[animation_name]["random_scale"])
	var animation_scene = config.get_value("obs", "animation_scene")
	var scene_item_transform = {
				"alignment": 5,
				"boundsAlignment": 0,
				"boundsHeight": 1.0,
				"boundsType": "OBS_BOUNDS_NONE",
				"boundsWidth": 1.0,
				"cropBottom": 0,
				"cropLeft": 0,
				"cropRight": 0,
				"cropTop": 0,
				"height": 100.0,
				"positionX": final_position_x,
				"positionY": final_position_y,
				"rotation": final_rotation,
				"scaleX": final_scale,
				"scaleY": final_scale,
				"sourceHeight": 100.0,
				"sourceWidth": 100.0,
				"width": 100.0,
			}
	var request = { 
			"sceneName": animation_scene,
			"sceneItemId": scene_item_id,
			"sceneItemTransform": scene_item_transform
		}
	send_scene_command(command, request, false)
	enable_scene_item(scene_name, scene_item_id)
	if animations[animation_name]["fade"] == true && !override_fade:
		await get_tree().create_timer(animations[animation_name]["fade_time"]).timeout
		await fade_out(scene_item_name)
	else:
		await clean_up(scene_item_name, false)
	
func enable_scene_item(scene_name, scene_item_id):
	var command = "SetSceneItemEnabled"
	var data = {
		"sceneName": scene_name, 
		"sceneItemId": scene_item_id, 
		"sceneItemEnabled": true
	}
	send_scene_command(command, data, false)

func show_friend(friend, remove):
	var friend_scene = config.get_value("obs", "friend_scene")
	var friend_scene_item_id = await get_scene_item_id(friend_scene, friend)
	enable_scene_item(friend_scene, friend_scene_item_id)
	
func disable_scene_item(scene_name, scene_item_id):
	var command = "SetSceneItemEnabled"
	var data = {
		"sceneName": scene_name, 
		"sceneItemId": scene_item_id, 
		"sceneItemEnabled": false
	}
	send_scene_command(command, data, false)

func hide_friend(friend, remove):
	var friend_scene = config.get_value("obs", "friend_scene")
	var friend_scene_item_id = await get_scene_item_id(friend_scene, friend)
	disable_scene_item(friend_scene, friend_scene_item_id)
	
func get_random_string(length):
	var return_string = ""
	for i in range(length):
		return_string += chars[randi_range(0, chars.length() - 1)]
	return return_string
	
func determine_shiney(selected_animation):
	var file = animations[selected_animation]['file']
	var final_file
	if file is Array:
		final_file = file[0]
	if animations[selected_animation]['rare_file'] != "":
		if randi_range(0, 100) < animations[selected_animation]['rare_chance']:
			final_file = animations[selected_animation]['rare_file']
	return final_file
	
func determine_final_position(position, random):
	var final_coordinates = position
	if random:
		var canvas_width = int(config.get_value("obs", "canvas_width")) - 420
		var canvas_height = int(config.get_value("obs", "canvas_height")) - 300
		final_coordinates[0] = randi_range(0, canvas_width - 1)
		final_coordinates[1] = randi_range(0, canvas_height - 1)
	return final_coordinates

func determine_looping_behavior(selected_animation, file):
	var looping = animations[selected_animation]['static']
	if animations[selected_animation]['file'].find(file) != 0:
		looping = false
	return looping

func determine_final_rotation(rotation, random):
	var final_rotation = rotation
	if random:
		final_rotation = int(randi_range(0, 360))
	return final_rotation
	
func determine_final_scale(scale, random):
	var final_scale = scale
	if random != [1, 1]:
		final_scale = randf_range(random[0], random[1])
	return final_scale
	
func wait_for_completed_command(uuid):
	while uuid in running_requests:
		await get_tree().create_timer(0.2).timeout
	return true
	
func clean_up(name, skipwait):
	if !skipwait:
		await get_tree().create_timer(20).timeout
	else:
		send_scene_command("RemoveInput", {'inputName' : name}, false)
	
func fade_out(name):
	var command = "CreateSourceFilter"
	var data = {
		"sourceName": name,
		"filterName": "fade",
		"filterKind": "color_filter_v2",
		"filterSettings": {"opacity": 1.0},
		}
	send_scene_command(command, data, false)
	var num_steps = int(1.0 / 0.02)
	var step_size = (1.0 - 0.0) / num_steps
	var current_value = 1.0
	var set_filter_command = "SetSourceFilterSettings"
	
	for i in range(num_steps):
		current_value -= step_size
		await  get_tree().create_timer(0.02).timeout
		var request = {
			"sourceName": name,
			"filterName": "fade",
			"filterSettings": {"opacity": current_value},
			}
		send_scene_command(set_filter_command, request, false)
	await clean_up(name, true)
	
func update_scroll_text(new_text):
	var inputSettings = {"text": new_text}
	var command = "SetInputSettings"
	var request = {"inputName": "Ticker", "inputSettings": inputSettings}
	send_scene_command(command, request, false)
	
func get_scene_item(scene_name, scene_item_name):
	var uuid = send_scene_command('GetSceneItemList', {"sceneName": scene_name}, true)
	await wait_for_completed_command(uuid)
	for response in responses:
		if response['uuid'] == uuid:
			var scene_items = response['response']['d']['responseData']['sceneItems']
			responses.erase(response)
			for item in scene_items:
				if item['sourceName'] == scene_item_name:
					return item

func get_scene_item_id(scene_name, scene_item_name):
	var scene_item = await get_scene_item(scene_name, scene_item_name)
	return scene_item['sceneItemId']
	
func set_input_settings(inputName, inputSettings):
	var requestType = 'SetInputSettings'
	var requestData = {'inputName' : inputName, 'inputSettings' : inputSettings}
	send_scene_command(requestType, requestData, false)
	
func get_request_dict(requestType, requestData):
	var uuid = 'emit_{id}'.format({"id" : uuid_util.v4()})
	running_requests.append(uuid)
	return {'requestType' : requestType, 'requestId' : uuid, 'requestData' : requestData}
	
func send_scene_command(requestType, requestData, keep_response):
	var data = get_request_dict(requestType, requestData)
	var request = {'op' : 6, 'd' : data}
	send_command(request)
	if !keep_response:
		dont_keep_response.append(request['d']['requestId'])
	return data['requestId']

func send_command(command):
	connector.send(str(command).to_utf8_buffer())

func _on_text_loop_wait_timeout():
	enable_scene_item(ticker_scene, ticker_id)
	$text_loop_display.start(ticker_display_time)

func _on_text_loop_display_timeout():
	enable_scene_item(ticker_scene, ticker_id)
	$text_loop_wait.start(ticker_wait_time)
