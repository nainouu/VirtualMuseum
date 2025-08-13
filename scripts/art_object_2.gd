# artObject 2.0

@tool
extends Node3D
class_name ArtObject2

#@export_file("*.glb") var targetModel: String:
	#set(value):
		#targetModel = value
		#_update_model()

@export_file("*.jpg", "*.png") var Artwork: String:
	set(value):
		Artwork = value
		_update_texture()
		updateHitbox()

@export var shaded: bool = false:
	set(value):
		shaded = value
		_updateSettings()

@export var EnableFrame: bool = false:
	set(value):
		EnableFrame = value
		if EnableFrame:
			generate_frame()
		else:
			clearFrame()

@export var FrameDepth: float = 0.2:
	set(value):
		if value >= 0:
			FrameDepth = value
			if EnableFrame:
				generate_frame()
			
@export var FrameWidth: float = 0.2:
	set(value):
		if value >= 0:
			FrameWidth = value
			if EnableFrame:
				generate_frame()
				
@export var FrameTextureEnable: bool = false:
	set(value):
		FrameTextureEnable = value
		generate_frame()

@export_file("*.jpg", "*.png") var FrameTexture: String:
	set(value):
		if value:
			FrameTexture = value
			if FrameTextureEnable:
				generate_frame()

@export var FrameColor: Color = Color.WHITE:
	set(value):
		FrameColor = value
		generate_frame()

@onready var Painting: Sprite3D = $Painting
@onready var Model: Node3D = $Model
@onready var Frame: Node3D = $Frame
@onready var hitbox: Area3D = $hitbox
@onready var hitboxShape: CollisionShape3D = $hitbox/shape

func _ready() -> void:
	_update_texture()
	updateHitbox()
	#_update_model()
	if EnableFrame:
		generate_frame()
	
	Painting.shaded = shaded

func _updateSettings():
	if Painting: Painting.shaded = shaded

func _update_texture() -> void:
	if !Painting or !Artwork:
		return

	var text = load(Artwork)
	if text:
		Painting.texture = text
		Painting.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		Painting.shaded = shaded
		await get_tree().process_frame # wait for texture
		
		if Frame and EnableFrame:
			generate_frame()

func updateHitbox():
	if Painting and Painting.texture:
		var size = Painting.texture.get_size() * Painting.pixel_size
		size.x *= Painting.scale.x
		size.y *= Painting.scale.y
		
		var newShape = BoxShape3D.new()
		newShape.size.x = size.x
		newShape.size.y = size.y
		newShape.size.z = 0.1
	
		hitboxShape.shape = newShape

func clearFrame():
	if !Frame:
		push_error("Frame null?")
		return
		
	for child in Frame.get_children():
		child.queue_free()
		
	return

func round_to_2_decimals(value: float) -> float:
	return round(value * 100.0) / 100.0

func generate_frame():
	if !Painting or !Painting.texture:
		push_error("Painting texture null")
		return
		
	# clear
	clearFrame()
	
	var size = Painting.texture.get_size() * Painting.pixel_size
	size.x *= Painting.scale.x
	size.y *= Painting.scale.y
	
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0

# Define frame bars
	var frameDefs = [
		{ # Top
			"size": Vector3(size.x + FrameWidth * 2, FrameWidth, FrameDepth),
			"pos": Vector3(0, half_h + FrameWidth / 2.0, 0)
		},
		{ # Bottom
			"size": Vector3(size.x + FrameWidth * 2, FrameWidth, FrameDepth),
			"pos": Vector3(0, -half_h - FrameWidth / 2.0, 0)
		},
		{ # Left
			"size": Vector3(FrameWidth, size.y, FrameDepth),
			"pos": Vector3(-half_w - FrameWidth / 2.0, 0, 0)
		},
		{ # Right
			"size": Vector3(FrameWidth, size.y, FrameDepth),
			"pos": Vector3(half_w + FrameWidth / 2.0, 0, 0)
		}
	]

	# generate frame
	for def in frameDefs:
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = def["size"]
		
		var material = StandardMaterial3D.new()
		
		if FrameTextureEnable:
			if FrameTexture:
				var tex = load(FrameTexture)
				assert(tex, "Failed to load texture for some reason")
				
				# if frame is left or right, rotate texture 90degrees
				# NOTE: this dont work
				if round_to_2_decimals(box.size.x) == FrameWidth:
					var image = tex.get_image()
					image.rotate_90(CLOCKWISE)
					tex = ImageTexture.create_from_image(image)
					
				material.albedo_texture = tex
			else:
				push_error("No frametexture selected")

		# set color
		if !FrameColor: FrameColor = Color.WHITE
		material.albedo_color = FrameColor

		box.material = material
		
		mesh_instance.mesh = box
		mesh_instance.translate(def["pos"])
		Frame.add_child(mesh_instance)

# wip and NOT tested
#func _update_model() -> void:
	#if !Model or !targetModel:
		#return
		#
	#var modelScene = load(targetModel)
	#if modelScene is PackedScene:
		#for child in Model.get_children():
			#if child != Model.get_child(0):
				#child.queue_free()
		#var model_instance = modelScene.instantiate()
		#Model.add_child(model_instance)
	#else:
		#push_error("Failed to load .glb scene from: " + targetModel)
