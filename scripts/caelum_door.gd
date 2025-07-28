@tool
extends Node3D

@export_file("*.tscn") var targetScenePath: String:
	set(value):
		targetScenePath = value

@export_tool_button("Search for spawnpoints") var search = searchForSpawnpoints

@onready var animPlayer = $AnimationPlayer

var spawnpoint_names: Array[String] = []
var spawnpoints: Array[PackedScene] = []
var _selected_spawnpoint_name: String = ""
var isOpen = false
const spawnpoint_scene_path = "res://scence/spawnPoint.tscn"


func _ready():
	print("caelum_door.gd init")



# editor stuff
func _get_property_list() -> Array:
	var properties = []
	properties.append({
		"name": "selected_spawnpoint",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(spawnpoint_names),
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR
	})
	return properties

func _get(property):
	if property == "selected_spawnpoint":
		return _selected_spawnpoint_name
	return null

func _set(property, value):
	if property == "selected_spawnpoint":
		_selected_spawnpoint_name = value
		return true
	return false

func searchForSpawnpoints():
	spawnpoint_names.clear()
	_selected_spawnpoint_name = ""

	if targetScenePath.is_empty():
		push_warning("no scene selected!")
		return

	if !FileAccess.file_exists(targetScenePath):
		push_error("scene file dont exist: %s" % targetScenePath)
		return

	var packed_scene := load(targetScenePath)
	if !packed_scene:
		push_error("Failed to load scene.")
		return

	var scene_instance = packed_scene.instantiate()

	if !FileAccess.file_exists(spawnpoint_scene_path):
		push_error("spawnPoint.tscn not found.")
		return

	for child in scene_instance.get_children():
		if child.scene_file_path == spawnpoint_scene_path:
			spawnpoint_names.append(child.name)
			spawnpoints.append(child)

	# autoselect first spawnpoint if it exists
	if spawnpoint_names.size() > 0:
		_selected_spawnpoint_name = spawnpoint_names[0]

	# force inspector refresh (to update dropdown list)
	notify_property_list_changed()

	# debug prints
	#print("Found %d spawnpoints:" % spawnpoint_names.size())
	#for name in spawnpoint_names:
		#print("- %s" % name)






# runtime stuff
func toggle_door():
	
	# play door animation ("door_close" is currently not used)
	if isOpen:
		animPlayer.play("caelumDoorClose")
	else:
		animPlayer.play("caelumDoorOpen")
		
	# toggle door state (currently useless)
	isOpen = !isOpen
	
	# wait for animation to finish
	if isOpen and !targetScenePath.is_empty():
		await animPlayer.animation_finished

	# load targetScene
	if isOpen:
		if targetScenePath.is_empty():
			push_warning("Door is missing targetScenePath")
			return
			
		if !FileAccess.file_exists(targetScenePath):
			push_warning("Target scene dont exist")
			return

		var packedScene = load(targetScenePath)
		if !packedScene or !packedScene is PackedScene:
			push_error("Failed to load scene at: %s" % targetScenePath)
			return
		
		var scene_instance = packedScene.instantiate()

		# search the selected spawnpoint in the new scene instance
		var target_spawnpoint: Node3D = null

		for child in scene_instance.get_children():
			if child.scene_file_path == spawnpoint_scene_path and child.name == _selected_spawnpoint_name:
				target_spawnpoint = child
				break

		if !target_spawnpoint:
			push_warning("Could not find spawnpoint '%s' in target scene." % _selected_spawnpoint_name)
			return

		# load
		var world = get_tree().get_root().get_node("world")
		world.loadLevel(packedScene, target_spawnpoint)
