extends Control

@onready var mainMenu: VBoxContainer = $"CenterContainer/mainMenu"
@onready var settingsMenu: VBoxContainer = $"CenterContainer/settingsMenu"
@onready var creditsMenu: VBoxContainer = $"CenterContainer/creditsMenu"
@onready var playButton: Button = $"CenterContainer/mainMenu/playButton"

@onready var volumeValueLabel: Label = $"CenterContainer/settingsMenu/volumeSlider/volumeValue"
@onready var musicValueLabel: Label = $"CenterContainer/settingsMenu/musicSlider/musicValue"
@onready var valumeSlider: HSlider = $"CenterContainer/settingsMenu/volumeSlider"
@onready var musicSlider: HSlider = $"CenterContainer/settingsMenu/musicSlider"

var isFullscreen: bool = false

var volume: float = 0.5
var music: float = 0.5

# menu indexes:
const MENU_MAIN := 0
const MENU_SETTINGS := 1
const MENU_CREDITS := 2

var menus: Array[VBoxContainer] = []

func _ready():
	print("MainMenuScene.gd init")
	
	assert(mainMenu, "mainMenu is null")
	assert(settingsMenu, "settingsMenu is null")
	assert(creditsMenu, "CreditsMenu is null")
	assert(volumeValueLabel, "volumeValueLabel is null")
	assert(musicValueLabel, "musicValueLabel is null")
	
	volumeValueLabel.text = str(volume*100).pad_decimals(0)
	valumeSlider.value = volume
	musicValueLabel.text = str(music*100).pad_decimals(0)
	musicSlider.value = music
	
	isFullscreen = DisplayServer.window_get_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("Fullscreen: ", isFullscreen)
	
	menus = [mainMenu, settingsMenu, creditsMenu]
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _toggleMenu(menu: int):
	if menu < 0 or menu >= menus.size():
		push_error("Invalid menu index")
		return
	
	for i in menus.size():
		menus[i].visible = (i == menu)
		
func _toggleRoot():
	self.visible = !self.visible
	
func _enableRoot():
	self.visible = true
	
func _disableRoot():
	self.visible = false

func _on_play_button_pressed():
	var world_node = get_tree().get_root().get_node("world")
	
	# if world hasn't been loaded yet
	if world_node.worldLoaded == false:
		world_node.loadPlayer()
		world_node.loadLevel(world_node.defaultScene, null)
		if playButton: playButton.text = "Continue"

	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		world_node.player.cameraRotation = true
		world_node.player.enableMovement = true
		world_node.mainMenuActive = true

	# hide root node
	self.visible = false
	
func _on_volumeSliderChanged(val):
	#print("volume val = ", val)
	volumeValueLabel.text = str(val*100).pad_decimals(0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), val)
	
func _on_musicSliderChanged(val):
	#print("Music val = ", val)
	musicValueLabel.text = str(val*100).pad_decimals(0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"), val)

func _on_settings_button_pressed():
	_toggleMenu(MENU_SETTINGS)

func _on_credits_button_pressed():
	_toggleMenu(MENU_CREDITS)

func _on_back_button_pressed():
	_toggleMenu(MENU_MAIN)

func _on_quit_button_pressed():
	get_tree().quit()

func _on_customResolutionPressed():
	#TODO: error handling
	var x: int = int($"CenterContainer/settingsMenu/HBoxContainer/customResX".text)
	var y: int = int($"CenterContainer/settingsMenu/HBoxContainer/customResY".text)
	
	if x != 0 and y != 0:
		_changeResolution(Vector2i(x,y))
		
func toggleFullscreen():
	if isFullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	isFullscreen = !isFullscreen

func _changeResolution(res: Vector2i):
	if res and res[0] > 0 and res[1] > 0:
		DisplayServer.window_set_size(res)
		print("Set resolution to: ", res)
	else:
		push_error("Invalid resolution")
