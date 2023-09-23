extends Node

var user_list = {}
var active_users = []
@export var websocket: PackedScene
@onready var connector
@onready var award_timer = $award_timer
var _json = JSON.new()
var config = ConfigFile.new()
var ws
var boosted_users
var award_base
var award_boosted
var award_frequency
var animations
signal show_friend
signal hide_friend
signal update_scroll_text
signal trigger_animation
signal connected

func _ready():
	_read_config()
	_read_boosted_users()
	_read_animations()
	_read_user_points()
	connector = websocket.instantiate()
	add_child(connector)
	var picarto_host = "wss://chat.picarto.tv/bot/username={channel_owner}&password={channel_auth}".format({"channel_owner" : config.get_value("picarto", "channel_owner"), "channel_auth" : config.get_value("picarto", "channel_auth")})
	connector.set_url(picarto_host)
	var header = "User-Agent: PTV-BOT-{channel_owner}".format({"channel_owner" : config.get_value("picarto", "channel_owner")})
	connector.set_headers(header)
	var singal_err = get_node("Websocket").connect("connected", send_command)
	if singal_err != OK:
		print(singal_err)
	connected.emit()
	connector.start()
	award_timer.start(float(award_frequency))

func _read_config():
	var err = config.load("user://config.ini")
	award_boosted = int(config.get_value("points", "boosted"))
	award_base = int(config.get_value("points", "base"))
	award_frequency = int(config.get_value("points", "frequency"))

func _read_boosted_users():
	var file = FileAccess.open("user://boosted_users.json", FileAccess.READ)
	var contents = file.get_as_text()
	boosted_users = _json.parse_string(contents)
	file.close()

func _read_user_points():
	var file = FileAccess.open("user://user_points.json", FileAccess.READ)
	var contents = file.get_as_text()
	user_list = _json.parse_string(contents)
	file.close()	
	
func _read_animations():
	var file = FileAccess.open("user://animations.json", FileAccess.READ)
	var contents = file.get_as_text()
	animations = _json.parse_string(contents)
	file.close()

func on_received_data(packet):
	var user_name
	var chat_message
	var message_author
	var _err = _json.parse(str(packet))
	var message_content = _json.get_data()
	if message_content["t"] == "un":
		user_name = message_content["m"]["n"]
		print("User {user_name} joined!".format({"user_name" : user_name}))
		if user_name not in user_list:
			user_list.merge({user_name : 0})
		if user_name not in active_users:
			active_users.append(user_name)
		check_for_friend(user_name, false)
	if message_content["t"] == "ur":
		user_name = message_content["m"]["n"]
		print("User {user_name} left!".format({"user_name" : user_name}))
		if user_name in active_users:
			active_users.remove(user_name)
			check_for_friend(user_name, true)
	if message_content["t"] == "c":
		chat_message = message_content["m"][0]["m"]
		message_author = message_content["m"][0]["n"]
		print("Message {chat_message} from {message_author}".format({"chat_messsage" : chat_message, "message_author" : message_author}))
		check_online_state(message_author)
		check_for_channel_owner(chat_message, message_author)
		check_for_points(chat_message, message_author)
		determine_animation_and_price(chat_message, message_author)
		
func determine_animation_and_price(chat_message, message_author):
	for animation in animations:
		if animations[animation]["trigger"] in chat_message:
			if user_list[message_author] >= animations[animation]['price']:
				user_list[message_author] -= animations[animation]['price']
				trigger_animation.emit(animation, message_author)
				log_redemption(user_list[message_author], animation, animations[animation]['price'])
			elif user_list[message_author] <= animations[animation]['price']:
				print("{user} does not have enough points to spend!".format({"user" : message_author}))
		
func check_online_state(message_author):
	if message_author not in active_users:
		active_users.append(message_author)
	if message_author not in user_list:
		user_list.merge({message_author : 0})
		
func log_redemption(user, animation, price):
	var file = FileAccess.open("user://redemption.log", FileAccess.WRITE_READ)
	var contents = file.get_as_text()
	var now = Time.get_datetime_string_from_system()
	contents += "[{now}] - Redemption of {animation} for {price} by {user} \n".format({"now" : now, "animation" : animation, "price" : price, "user" : user})
	file.store_string(contents)
	file.close()

func check_for_friend(user_name, remove):
	var friends = config.get_value("picarto", "friends")
	if user_name in friends:
		if remove:
			hide_friend_obs(user_name, remove)
		else:
			show_friend_obs(user_name, remove)
		
func show_friend_obs(user_name, remove):
	show_friend.emit(user_name, remove)
	
func hide_friend_obs(user_name, remove):
	hide_friend.emit(user_name, remove)
	
func check_for_channel_owner(chat_message, message_author):
	if message_author in config.get_value("picarto", "granters") and '!grant' in chat_message:
		print("Got granting message!")
		var split_text = chat_message.split()
		var user = split_text[2]
		var amount = int(split_text[1])
		if user in user_list:
			user_list[user] += amount
			print("Updated {user} to {list}".format({"user" : user, "list" : user_list[user]}))
			update_obs_scroll_text()

func check_for_points(chat_message, message_author):
	if "!points" in chat_message:
		send_whisper("You currently have {list} points!".format({"list" : user_list[message_author]}), message_author)
		
func send_whisper(message, user):
	var message_data = {"type": "whisper", "displayName": user, "message": message}
	send_command(message_data)
	
func send_command(command):
	connector.send(str(command).to_utf8_buffer())
	
func update_standings():
	for user in active_users:
		if user in boosted_users:
			user_list[user] += award_boosted
		else:
			user_list[user] += award_base
		print("{user} now has {list} points!".format({"user" : user, "list" : user_list[user]}))
	save_standings()
	update_obs_scroll_text()
	if config.get_value('web', 'url') != "":
		update_standings_server()

func update_standings_server():
	var app_url = config.get_value("web", "url") + "/new_data"
	var key = config.get_value("web", "key")

	var update_list = []

	for item in user_list:
		update_list.append(
		{"name": str(item), "points": user_list[item]})
	
	var payload = {
		"password": key,
		"data": update_list
	}
	print(payload)
	
	$HTTPRequest.request_completed.connect(_on_request_completed)
	var headers = ["Content-Type: application/json"]
	$HTTPRequest.request(app_url, headers, HTTPClient.METHOD_POST, _json.stringify(payload))
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json)

func save_standings():
	var file = FileAccess.open("user://user_points.json", FileAccess.WRITE_READ)
	var json_string = _json.stringify(user_list)
	file.store_string(json_string)
	file.close()

func update_obs_scroll_text():
	var result = []
	for user in user_list:
		if user in active_users:
			var append_string = "{user} has {list} points}".format({"user" : user, "list" : user_list[user]})
			result.append(append_string)
	var new_text = ", ".join(result)
	update_scroll_text.emit(result)

func _on_award_timer_timeout():
	update_standings()
	award_timer.start(award_frequency)
