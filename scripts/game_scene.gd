extends Node2D

var peer = ENetMultiplayerPeer.new()

var _player_scene = preload("res://scenes/player_scene.tscn")

var GaneWorld: World

const _PORT = 27015
const _IP = "localhost"

const VERSION = "0.0.1"


func _ready():

	# Host if noone hosting. else join
	if not _try_host_game():
		_join_game()
	printerr()



func _try_host_game():
	var cs = peer.create_server(_PORT)

	if cs == 20:
		peer.close()
		return false
	
	print("Hosting game on " + _IP + ":" + str(_PORT))
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_disconnect_player)
	_add_player()
	return true

func _add_player(id = 1):

	print("Connecting player:" + str(id))
	var player = _player_scene.instantiate()
	player.name = str(id)

	call_deferred("add_child", player)
	call_deferred("spawn_player", player)

func _disconnect_player(id = 1):
	print("Disconnecting player:", id)
	var ch = get_node(str(id))
	ch.queue_free()


func _join_game():
	print("Joining game on " + _IP + ":" + str(_PORT))
	peer.create_client(_IP, _PORT)
	multiplayer.multiplayer_peer = peer

