extends Node

var _client = WebSocketPeer.new()
var url
var port
var user_name
var password
var started = false
var connection_established = false
var attempting_connection = false
var _json = JSON.new()
var ws_headers
signal connected

func start():
	started = true
	print("Started Websocket")
	connect_websocket()

func set_username(input):
	user_name = input

func set_url(input):
	url = input

func set_port(input):
	port = input

func set_password(input):
	password = input
	
func set_headers(input):
	ws_headers = input

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !started:
		return
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !connection_established:
			_connected()
			connection_established = true
		while _client.get_available_packet_count():
			_on_received_data()
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED && attempting_connection == true:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		print("Connection failed with " + str(code) + " and reason: " + str(reason))
		attempting_connection = false

func connect_websocket():
	if ws_headers != null:
		_client.set_handshake_headers([ws_headers])	
	print("Connecting to websocket {url} on port {port}".format({"url" : url, "port" : port}))
	var err
	if port != null:
		err = _client.connect_to_url(url + ":" + port)
	else:
		err = _client.connect_to_url(url)
	if err != OK:
		print(err)

func _connected(proto = ""):
	print("Websocket connected!")

func _on_received_data():
	# Well catch our server messages here.
	var packet = _json.parse_string(_client.get_packet().get_string_from_utf8())
	get_parent().on_received_data(packet)
	
func send(array : PackedByteArray):
	print("sending!")
	var err = _client.send(array, WebSocketPeer.WRITE_MODE_TEXT)
	if err != OK:
		print("Sending unsuccessful! {err}".format({"err" : err}))
