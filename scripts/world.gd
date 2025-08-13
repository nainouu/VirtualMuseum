extends Node3D

@onready var stage = $stage
@onready var player = $player
@onready var MainMenuScene = $MainMenuScene

@export var defaultScene = PackedScene

var mainMenuActive: bool = true # tracks if mainmenu is active
var worldLoaded: bool = false # tracks if world has been loaded atleast once

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("world.gd init")
	#scaleToMonitor()
	
	# load default scene
	#if defaultScene:
		#loadLevel(defaultScene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):

		if mainMenuActive:
			MainMenuScene._enableRoot()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			player.cameraRotation = false
			player.enableMovement = false
		else:
			MainMenuScene._disableRoot()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			player.cameraRotation = true
			player.enableMovement = true
			
		mainMenuActive = !mainMenuActive
	
func scaleToMonitor():
	var resolution = DisplayServer.screen_get_size()
	DisplayServer.window_set_size(Vector2i(resolution))
	DisplayServer.window_set_position(Vector2i(0,0))

func loadPlayer():
	var playerScene = load("res://scence/player.tscn").instantiate()
	add_child(playerScene)
	player = playerScene

func loadLevel(packedScene: PackedScene, spawnpoint: Node3D):
	# Clear previous scene
	stage.get_children().map(func(child): child.queue_free())

	# init new scene
	var levelInstance = packedScene.instantiate()
	stage.add_child(levelInstance)

	#assert(player, "player null for some reason")
	
	# teleport player to spawnpoint
	if spawnpoint:
		player.position = spawnpoint.position
		player.rotation = spawnpoint.rotation
		
	else:
		# spawnpoint not found, defaulting to (0,0)
		print("Spawnpoint is null, or 'loadLevel' was called with null spawnpoint. Spawning player to 0.0")
		player.global_position = Vector3.ZERO
	
	worldLoaded = true
	if player and player.gunmodel: 
		player.equippedItem = null
		player.gunmodel.visible = false
